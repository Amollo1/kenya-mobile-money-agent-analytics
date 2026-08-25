-- =========================================================================
-- Kenya Mobile Money & Agent Network Analytics
-- Phase 2 Deliverable: Database + Star Schema DDL
-- Target: MySQL 8.x / MySQL Workbench
-- =========================================================================
-- Notes:
--   * Charset utf8mb4 is used throughout for correct handling of Kenyan
--     place names and any future free-text fields.
--   * All tables use InnoDB to support foreign keys and transactions.
--   * Surrogate integer PKs are used for dimensions (fast joins, standard
--     Kimball star-schema practice); DimDate uses the date itself as PK,
--     which is the conventional exception for date dimensions.
--   * Only ONE path into location exists: FactTransactions -> DimAgent ->
--     DimLocation. There is no LocationID on FactTransactions and no
--     CustomerLocation on DimCustomer, by design (see Phase 2 notes).
--   * FraudScore / RiskFlag are intentionally NOT columns here — they are
--     computed later in DAX, not stored in the database.
-- =========================================================================

DROP DATABASE IF EXISTS kenya_mobile_money;
CREATE DATABASE kenya_mobile_money
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE kenya_mobile_money;

-- =========================================================================
-- 1. DimDate
-- Standalone dimension, no dependencies. PK is the calendar date itself.
-- =========================================================================
CREATE TABLE DimDate (
    DateKey         DATE            NOT NULL,
    Year            SMALLINT        NOT NULL,
    Quarter         TINYINT         NOT NULL,
    Month           TINYINT         NOT NULL,
    MonthName       VARCHAR(15)     NOT NULL,
    Week            TINYINT         NOT NULL,
    Day             TINYINT         NOT NULL,
    DayName         VARCHAR(10)     NOT NULL,
    IsWeekend       TINYINT(1)      NOT NULL DEFAULT 0,
    PRIMARY KEY (DateKey),
    CONSTRAINT chk_date_quarter CHECK (Quarter BETWEEN 1 AND 4),
    CONSTRAINT chk_date_month   CHECK (Month BETWEEN 1 AND 12)
) ENGINE=InnoDB;


-- =========================================================================
-- 2. DimLocation
-- Standalone dimension, no dependencies. Referenced only by DimAgent.
-- =========================================================================
CREATE TABLE DimLocation (
    LocationID      INT             NOT NULL AUTO_INCREMENT,
    County          VARCHAR(50)     NOT NULL,
    SubCounty       VARCHAR(50)     NOT NULL,
    UrbanRural      ENUM('Urban','Rural') NOT NULL,
    Region          VARCHAR(50)     NOT NULL,
    PRIMARY KEY (LocationID),
    UNIQUE KEY uq_location (County, SubCounty)
) ENGINE=InnoDB;


-- =========================================================================
-- 3. DimProvider
-- Standalone dimension, no dependencies.
-- =========================================================================
CREATE TABLE DimProvider (
    ProviderID          INT             NOT NULL AUTO_INCREMENT,
    ProviderName        VARCHAR(50)     NOT NULL,
    ProviderCategory    VARCHAR(50)     NOT NULL,
    PRIMARY KEY (ProviderID),
    UNIQUE KEY uq_provider_name (ProviderName)
) ENGINE=InnoDB;


-- =========================================================================
-- 4. DimCustomer
-- Standalone dimension, no dependencies.
-- Note: CustomerLocation intentionally omitted for v1 (see Phase 2 notes).
-- =========================================================================
CREATE TABLE DimCustomer (
    CustomerID           INT             NOT NULL AUTO_INCREMENT,
    CustomerSegment       VARCHAR(30)     NOT NULL,
    AgeGroup              VARCHAR(15)     NOT NULL,
    Gender                ENUM('Male','Female') NOT NULL,
    PRIMARY KEY (CustomerID)
) ENGINE=InnoDB;


-- =========================================================================
-- 5. DimTransactionType
-- Standalone dimension, no dependencies.
-- =========================================================================
CREATE TABLE DimTransactionType (
    TransactionTypeID    INT             NOT NULL AUTO_INCREMENT,
    TransactionType        VARCHAR(30)     NOT NULL,
    Category                 VARCHAR(30)     NOT NULL,
    PRIMARY KEY (TransactionTypeID),
    UNIQUE KEY uq_transaction_type (TransactionType)
) ENGINE=InnoDB;


-- =========================================================================
-- 6. DimAgent
-- Depends on DimLocation (single location path into the star schema).
-- =========================================================================
CREATE TABLE DimAgent (
    AgentID          INT             NOT NULL AUTO_INCREMENT,
    AgentName        VARCHAR(100)    NOT NULL,
    AgentType        VARCHAR(30)     NOT NULL,
    AgentStartDate   DATE            NOT NULL,
    AgentStatus      ENUM('Active','Inactive','Suspended') NOT NULL DEFAULT 'Active',
    LocationID       INT             NOT NULL,
    PRIMARY KEY (AgentID),
    CONSTRAINT fk_agent_location
        FOREIGN KEY (LocationID) REFERENCES DimLocation (LocationID)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE INDEX idx_agent_location ON DimAgent (LocationID);


-- =========================================================================
-- 7. FactTransactions
-- Depends on all six dimensions above. Grain: one row = one transaction.
-- No LocationID here — location is reached only via AgentID -> DimAgent.
-- No FraudScore / RiskFlag columns — computed in DAX, not stored.
-- =========================================================================
CREATE TABLE FactTransactions (
    TransactionID          BIGINT          NOT NULL AUTO_INCREMENT,
    DateKey                 DATE            NOT NULL,
    AgentID                  INT             NOT NULL,
    CustomerID                INT             NOT NULL,
    ProviderID                 INT             NOT NULL,
    TransactionTypeID           INT             NOT NULL,
    TransactionAmount            DECIMAL(12,2)   NOT NULL,
    Commission                     DECIMAL(10,2)   NOT NULL,
    ProcessingCost                   DECIMAL(10,2)   NOT NULL,
    TransactionStatus                  ENUM('Success','Failed','Reversed') NOT NULL,
    TransactionDuration                  SMALLINT        NOT NULL COMMENT 'seconds',
    PRIMARY KEY (TransactionID),

    CONSTRAINT fk_fact_date
        FOREIGN KEY (DateKey) REFERENCES DimDate (DateKey)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT fk_fact_agent
        FOREIGN KEY (AgentID) REFERENCES DimAgent (AgentID)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT fk_fact_customer
        FOREIGN KEY (CustomerID) REFERENCES DimCustomer (CustomerID)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT fk_fact_provider
        FOREIGN KEY (ProviderID) REFERENCES DimProvider (ProviderID)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT fk_fact_transactiontype
        FOREIGN KEY (TransactionTypeID) REFERENCES DimTransactionType (TransactionTypeID)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT chk_amounts_nonnegative
        CHECK (TransactionAmount >= 0 AND Commission >= 0 AND ProcessingCost >= 0)

) ENGINE=InnoDB;

-- Indexes on FK columns for join performance and to support the specific
-- slice-and-dice patterns this project's KPIs will run.
CREATE INDEX idx_fact_date       ON FactTransactions (DateKey);
CREATE INDEX idx_fact_agent      ON FactTransactions (AgentID);
CREATE INDEX idx_fact_customer   ON FactTransactions (CustomerID);
CREATE INDEX idx_fact_provider   ON FactTransactions (ProviderID);
CREATE INDEX idx_fact_txntype    ON FactTransactions (TransactionTypeID);
CREATE INDEX idx_fact_agent_date ON FactTransactions (AgentID, DateKey);


-- =========================================================================
-- Sanity check: confirm all 7 tables and FK relationships exist
-- =========================================================================
SELECT TABLE_NAME, TABLE_ROWS
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'kenya_mobile_money'
ORDER BY TABLE_NAME;

SELECT
    TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'kenya_mobile_money'
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME;