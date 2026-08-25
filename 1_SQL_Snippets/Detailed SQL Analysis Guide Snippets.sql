/*
Detailed SQL Analysis Guide
Kenya Mobile Money & Agent Network Analytics
Analyzing 1,000,000 Transactions

This guide helps you extract meaningful insights from the full dataset (1 Million transactions,
100K customers, 10K agents) and understand which insights become Power BI visuals.
*/

/*QUERY 1: Overall Financial Health

SQL Query*/

SELECT
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT AgentID) AS unique_agents,
    COUNT(DISTINCT CustomerID) AS unique_customers,
    ROUND(SUM(TransactionAmount), 2) AS total_transaction_value,
    ROUND(AVG(TransactionAmount), 2) AS avg_transaction_amount,
    ROUND(SUM(Commission), 2) AS total_commission,
    ROUND(SUM(ProcessingCost), 2) AS total_processing_cost,
    ROUND(SUM(Commission) - SUM(ProcessingCost), 2) AS net_revenue,
    ROUND((SUM(Commission) - SUM(ProcessingCost)) / SUM(Commission) * 100, 2) AS net_margin_pct
FROM FactTransactions
WHERE TransactionStatus = 'Success';

/*
QUERY 2: Top 20 Agents by Net Revenue

SQL Query
*/

SELECT
    a.AgentID,
    a.AgentName,
    l.County,
    a.AgentType,
    COUNT(f.TransactionID) AS transaction_count,
    ROUND(SUM(f.TransactionAmount), 2) AS total_value,
    ROUND(SUM(f.Commission), 2) AS total_commission,
    ROUND(SUM(f.Commission) - SUM(f.ProcessingCost), 2) AS net_revenue,
    ROUND(AVG(f.TransactionAmount), 2) AS avg_transaction_value,
    ROUND((SUM(f.Commission) - SUM(f.ProcessingCost)) / COUNT(DISTINCT f.CustomerID), 2) AS revenue_per_customer
FROM FactTransactions f
JOIN DimAgent a ON f.AgentID = a.AgentID
JOIN DimLocation l ON a.LocationID = l.LocationID
WHERE f.TransactionStatus = 'Success'
GROUP BY a.AgentID, a.AgentName, l.County, a.AgentType
ORDER BY net_revenue DESC
LIMIT 20;

/*
QUERY 3: Revenue by County (Geographic Performance)

SQL Query
*/

SELECT
    l.County,
    l.Region,
    l.UrbanRural,
    COUNT(DISTINCT a.AgentID) AS agent_count,
    COUNT(f.TransactionID) AS transaction_count,
    ROUND(SUM(f.TransactionAmount), 2) AS total_value,
    ROUND(SUM(f.Commission) - SUM(f.ProcessingCost), 2) AS net_revenue,
    ROUND(AVG(f.Commission) - AVG(f.ProcessingCost), 2) AS avg_net_per_transaction,
    ROUND((SUM(f.Commission) - SUM(f.ProcessingCost)) / SUM(f.Commission) * 100, 2) AS margin_pct,
    ROUND(COUNT(f.TransactionID) / COUNT(DISTINCT a.AgentID), 2) AS transactions_per_agent
FROM FactTransactions f
JOIN DimAgent a ON f.AgentID = a.AgentID
JOIN DimLocation l ON a.LocationID = l.LocationID
WHERE f.TransactionStatus = 'Success'
GROUP BY l.County, l.Region, l.UrbanRural
ORDER BY net_revenue DESC;

/*
QUERY 4: Revenue per Active Agent (KEY METRIC!)

SQL Query
*/

SELECT
    l.County,
    l.Region,
    COUNT(DISTINCT a.AgentID) AS agent_count,
    COUNT(f.TransactionID) AS total_transactions,
    ROUND(SUM(f.Commission) - SUM(f.ProcessingCost), 2) AS county_net_revenue,
    ROUND((SUM(f.Commission) - SUM(f.ProcessingCost)) / COUNT(DISTINCT a.AgentID), 2) AS revenue_per_agent,
    ROUND(COUNT(f.TransactionID) / COUNT(DISTINCT a.AgentID), 2) AS transactions_per_agent,
    ROUND(AVG(f.TransactionAmount), 2) AS avg_transaction_value,
    ROUND(SUM(f.TransactionStatus = 'Success') * 100 / COUNT(*), 2) AS success_rate_pct
FROM FactTransactions f
JOIN DimAgent a ON f.AgentID = a.AgentID
JOIN DimLocation l ON a.LocationID = l.LocationID
GROUP BY l.County, l.Region
ORDER BY revenue_per_agent DESC;

/*
QUERY 5: Provider Performance Comparison

SQL Query
*/

SELECT
    p.ProviderName,
    p.ProviderCategory,
    COUNT(f.TransactionID) AS transaction_count,
    ROUND(COUNT(f.TransactionID) * 100 / (SELECT COUNT(*) FROM FactTransactions), 2) AS pct_of_total,
    ROUND(SUM(f.TransactionAmount), 2) AS total_value,
    ROUND(AVG(f.TransactionAmount), 2) AS avg_transaction_value,
    ROUND(SUM(f.Commission), 2) AS total_commission,
    ROUND(SUM(f.ProcessingCost), 2) AS total_processing_cost,
    ROUND(SUM(f.Commission) - SUM(f.ProcessingCost), 2) AS net_revenue,
    ROUND((SUM(f.Commission) - SUM(f.ProcessingCost)) / SUM(f.Commission) * 100, 2) AS margin_pct,
    ROUND(SUM(f.TransactionStatus = 'Success') * 100 / COUNT(*), 2) AS success_rate_pct
FROM FactTransactions f
JOIN DimProvider p ON f.ProviderID = p.ProviderID
GROUP BY p.ProviderID, p.ProviderName, p.ProviderCategory
ORDER BY net_revenue DESC;

/*
QUERY 6: Transaction Type Profitability

SQL QueryP
*/

SELECT
    t.TransactionType,
    t.Category,
    COUNT(f.TransactionID) AS transaction_count,
    ROUND(COUNT(f.TransactionID) * 100 / (SELECT COUNT(*) FROM FactTransactions), 2) AS pct_of_total,
    ROUND(AVG(f.TransactionAmount), 2) AS avg_amount,
    ROUND(AVG(f.Commission), 2) AS avg_commission,
    ROUND(AVG(f.ProcessingCost), 2) AS avg_processing_cost,
    ROUND(AVG(f.Commission) - AVG(f.ProcessingCost), 2) AS avg_net_revenue,
    ROUND(SUM(f.Commission) - SUM(f.ProcessingCost), 2) AS total_net_revenue,
    ROUND((SUM(f.Commission) - SUM(f.ProcessingCost)) / SUM(f.Commission) * 100, 2) AS margin_pct,
    ROUND(SUM(f.TransactionStatus = 'Success') * 100 / COUNT(*), 2) AS success_rate_pct
FROM FactTransactions f
JOIN DimTransactionType t ON f.TransactionTypeID = t.TransactionTypeID
GROUP BY t.TransactionTypeID, t.TransactionType, t.Category
ORDER BY total_net_revenue DESC;

/*
QUERY 7: Customer Segment Behavior

SQL Query
*/

SELECT
    c.CustomerSegment,
    c.AgeGroup,
    COUNT(f.TransactionID) AS transaction_count,
    COUNT(DISTINCT f.CustomerID) AS unique_customers,
    ROUND(COUNT(f.TransactionID) / COUNT(DISTINCT f.CustomerID), 2) AS transactions_per_customer,
    ROUND(SUM(f.TransactionAmount), 2) AS total_value,
    ROUND(AVG(f.TransactionAmount), 2) AS avg_transaction_amount,
    ROUND(SUM(f.Commission) - SUM(f.ProcessingCost), 2) AS net_revenue,
    ROUND((SUM(f.Commission) - SUM(f.ProcessingCost)) / COUNT(DISTINCT f.CustomerID), 2) AS revenue_per_customer,
    ROUND(SUM(f.TransactionStatus = 'Success') * 100 / COUNT(*), 2) AS success_rate_pct
FROM FactTransactions f
JOIN DimCustomer c ON f.CustomerID = c.CustomerID
WHERE f.TransactionStatus = 'Success'
GROUP BY c.CustomerSegment, c.AgeGroup
ORDER BY net_revenue DESC;

/*
QUERY 8: Monthly Trends (Seasonality & Growth)

SQL Query
*/

SELECT
    YEAR(d.DateKey) AS year,
    MONTH(d.DateKey) AS month,
    d.MonthName,
    COUNT(f.TransactionID) AS transaction_count,
    ROUND(SUM(f.TransactionAmount), 2) AS total_value,
    ROUND(SUM(f.Commission) - SUM(f.ProcessingCost), 2) AS net_revenue,
    ROUND(AVG(f.TransactionAmount), 2) AS avg_transaction_value,
    ROUND(SUM(f.TransactionStatus = 'Success') * 100 / COUNT(*), 2) AS success_rate_pct,
    ROUND(COUNT(DISTINCT f.AgentID), 0) AS active_agents,
    ROUND(COUNT(f.TransactionID) / COUNT(DISTINCT f.AgentID), 2) AS transactions_per_agent
FROM FactTransactions f
JOIN DimDate d ON f.DateKey = d.DateKey
WHERE YEAR(d.DateKey) = 2025
GROUP BY YEAR(d.DateKey), MONTH(d.DateKey), d.MonthName
ORDER BY MONTH(d.DateKey);

/*
QUERY 9: Failure & Reversal Analysis

SQL Query
*/

SELECT
    f.TransactionStatus,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100 / (SELECT COUNT(*) FROM FactTransactions), 2) AS pct_of_total,
    ROUND(AVG(f.TransactionAmount), 2) AS avg_amount,
    ROUND(SUM(f.TransactionAmount), 2) AS total_value
FROM FactTransactions f
GROUP BY f.TransactionStatus
ORDER BY count DESC;

-- By Transaction Type
SELECT
    t.TransactionType,
    f.TransactionStatus,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER (PARTITION BY t.TransactionTypeID), 2) AS pct_of_type
FROM FactTransactions f
JOIN DimTransactionType t ON f.TransactionTypeID = t.TransactionTypeID
GROUP BY t.TransactionType, f.TransactionStatus
ORDER BY t.TransactionType, count DESC;

-- By Provider
SELECT
    p.ProviderName,
    f.TransactionStatus,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER (PARTITION BY p.ProviderID), 2) AS pct_of_provider
FROM FactTransactions f
JOIN DimProvider p ON f.ProviderID = p.ProviderID
GROUP BY p.ProviderName, f.TransactionStatus
ORDER BY p.ProviderName, count DESC;

/*
QUERY 10: High-Value Transaction Distribution

SQL Query
*/

-- Query 1: Distribution percentiles
SELECT
    MIN(TransactionAmount) AS min_amount,
    ROUND(AVG(TransactionAmount), 2) AS mean_amount,
    ROUND(MAX(TransactionAmount), 2) AS max_amount,
    COUNT(*) AS total_count
FROM FactTransactions;

-- Query 2: Bucket analysis
SELECT
    CASE 
        WHEN TransactionAmount < 1000 THEN '< 1K'
        WHEN TransactionAmount < 5000 THEN '1K - 5K'
        WHEN TransactionAmount < 10000 THEN '5K - 10K'
        WHEN TransactionAmount < 50000 THEN '10K - 50K'
        WHEN TransactionAmount < 100000 THEN '50K - 100K'
        ELSE '> 100K'
    END AS amount_bucket,
    COUNT(*) AS transaction_count,
    ROUND(COUNT(*) * 100 / (SELECT COUNT(*) FROM FactTransactions), 2) AS pct_of_total,
    ROUND(SUM(TransactionAmount), 2) AS total_value,
    ROUND(SUM(f.Commission) - SUM(f.ProcessingCost), 2) AS net_revenue
FROM FactTransactions f
GROUP BY amount_bucket
ORDER BY MIN(TransactionAmount);

-- Query 3: Top 20 high-value transactions (FIXED)
SELECT
    f.TransactionID,
    d.DateKey,
    a.AgentName,
    l.County,
    c.CustomerSegment,
    p.ProviderName,
    t.TransactionType,
    f.TransactionAmount,
    f.Commission,
    f.ProcessingCost,
    ROUND(f.Commission - f.ProcessingCost, 2) AS net_revenue,
    f.TransactionStatus
FROM FactTransactions f
JOIN DimDate d ON f.DateKey = d.DateKey
JOIN DimAgent a ON f.AgentID = a.AgentID
JOIN DimLocation l ON a.LocationID = l.LocationID
JOIN DimCustomer c ON f.CustomerID = c.CustomerID
JOIN DimProvider p ON f.ProviderID = p.ProviderID
JOIN DimTransactionType t ON f.TransactionTypeID = t.TransactionTypeID
ORDER BY f.TransactionAmount DESC
LIMIT 20;