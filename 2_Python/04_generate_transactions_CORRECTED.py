"""
=========================================================================
KENYA MOBILE MONEY & AGENT NETWORK ANALYTICS
Phase 4: Synthetic Data Generation (CORRECTED)

Target (v1):
    Customers       : 1,000
    Agents          : 100
    Transactions    : 10,000

Database:
    MySQL 8.x

Schema:
    kenya_mobile_money

Purpose:
    Generate realistic synthetic Kenyan mobile-money / agent-network data
    for SQL, Power BI, DAX and analytics portfolio work.

NOTE:
    This is synthetic data. It is NOT real customer, agent, provider,
    financial or transaction data.

Changes from original:
    - Credentials moved to environment variables (.env file)
    - Removed unused Faker library
    - Optimized agent eligibility filtering
    - Eliminated global variable (pass providers as parameter)
    - Fixed transaction type weight order mismatch
    - Added error handling for missing transaction amounts
    - Region weights derived from actual DimLocation data
    - Updated header comment to match v1 configuration
=========================================================================
"""

import os
import random
import math
from datetime import date, timedelta

import numpy as np
import mysql.connector
from dotenv import load_dotenv


# =========================================================================
# 1. CONFIGURATION & ENVIRONMENT
# =========================================================================

load_dotenv()  # Load .env file if it exists

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "user": os.getenv("DB_USER", "root"),
    "password": os.getenv("DB_PASSWORD"),
    "database": "kenya_mobile_money"
}

# Validate required environment variable
if not DB_CONFIG["password"]:
    raise RuntimeError(
        "DB_PASSWORD environment variable not set. "
        "Create a .env file in the project root with:\n"
        "    DB_HOST=localhost\n"
        "    DB_USER=root\n"
        "    DB_PASSWORD=your_password"
    )

RANDOM_SEED = 42

NUM_CUSTOMERS = 100_000
NUM_AGENTS = 10_000
NUM_TRANSACTIONS = 1_000_000

START_DATE = date(2025, 1, 1)
END_DATE = date(2025, 12, 31)

BATCH_SIZE = 50_000

random.seed(RANDOM_SEED)
np.random.seed(RANDOM_SEED)


# =========================================================================
# 2. DATABASE CONNECTION
# =========================================================================

def get_connection():
    return mysql.connector.connect(**DB_CONFIG)


# =========================================================================
# 3. HELPER FUNCTIONS
# =========================================================================

def random_date(start_date, end_date):
    """Generate a random date between two dates."""
    days = (end_date - start_date).days
    return start_date + timedelta(days=random.randint(0, days))


def weighted_choice(items, weights):
    """Return one item using supplied probability weights."""
    return random.choices(items, weights=weights, k=1)[0]


def clamp(value, minimum, maximum):
    return max(minimum, min(value, maximum))


# =========================================================================
# 4. POPULATE DIMDATE
# =========================================================================

def populate_dim_date(connection):
    """
    Populate DimDate for the transaction period.

    DimDate is required before FactTransactions can be generated.
    """

    cursor = connection.cursor()

    print("\n[1/6] Populating DimDate...")

    insert_sql = """
        INSERT IGNORE INTO DimDate
        (
            DateKey,
            Year,
            Quarter,
            Month,
            MonthName,
            Week,
            Day,
            DayName,
            IsWeekend
        )
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
    """

    rows = []
    current_date = START_DATE

    while current_date <= END_DATE:

        year = current_date.year
        month = current_date.month
        quarter = ((month - 1) // 3) + 1
        week = current_date.isocalendar().week
        day = current_date.day

        month_name = current_date.strftime("%B")
        day_name = current_date.strftime("%A")

        is_weekend = 1 if current_date.weekday() >= 5 else 0

        rows.append(
            (
                current_date,
                year,
                quarter,
                month,
                month_name,
                week,
                day,
                day_name,
                is_weekend
            )
        )

        current_date += timedelta(days=1)

    cursor.executemany(insert_sql, rows)
    connection.commit()

    print(f"    ✓ {len(rows):,} dates inserted/verified.")

    cursor.close()


# =========================================================================
# 5. TRANSACTION TYPES
# =========================================================================

def populate_transaction_types(connection):

    print("\n[2/6] Populating DimTransactionType...")

    cursor = connection.cursor()

    transaction_types = [
        ("Cash Deposit", "Cash"),
        ("Cash Withdrawal", "Cash"),
        ("Send Money", "Transfer"),
        ("Bill Payment", "Payment"),
        ("Airtime Purchase", "Payment"),
        ("Merchant Payment", "Payment"),
        ("Bank Transfer", "Banking"),
        ("Account Deposit", "Banking"),
        ("Account Withdrawal", "Banking")
    ]

    sql = """
        INSERT IGNORE INTO DimTransactionType
        (
            TransactionType,
            Category
        )
        VALUES (%s,%s)
    """

    cursor.executemany(sql, transaction_types)
    connection.commit()

    print(f"    ✓ {len(transaction_types)} transaction types inserted/verified.")

    cursor.close()


# =========================================================================
# 6. GENERATE CUSTOMERS
# =========================================================================

def generate_customers(connection):

    print("\n[3/6] Generating customers...")
    print(f"    Target customers: {NUM_CUSTOMERS:,}")

    cursor = connection.cursor()

    # Clear existing synthetic customer data
    cursor.execute("DELETE FROM DimCustomer")
    connection.commit()

    segments = ["Mass Market", "Emerging", "Affluent", "Business"]
    segment_weights = [0.55, 0.25, 0.15, 0.05]

    age_groups = ["18-24", "25-34", "35-44", "45-54", "55+"]
    age_weights = [0.18, 0.32, 0.25, 0.15, 0.10]

    genders = ["Male", "Female"]
    gender_weights = [0.51, 0.49]

    insert_sql = """
        INSERT INTO DimCustomer
        (CustomerSegment, AgeGroup, Gender)
        VALUES (%s,%s,%s)
    """

    rows = []

    for _ in range(NUM_CUSTOMERS):

        segment = weighted_choice(segments, segment_weights)
        age_group = weighted_choice(age_groups, age_weights)
        gender = weighted_choice(genders, gender_weights)

        rows.append((segment, age_group, gender))

        if len(rows) >= BATCH_SIZE:
            cursor.executemany(insert_sql, rows)
            connection.commit()
            rows.clear()

    if rows:
        cursor.executemany(insert_sql, rows)
        connection.commit()

    print(f"    ✓ {NUM_CUSTOMERS:,} customers generated.")
    cursor.close()


# =========================================================================
# 7. LOAD LOCATIONS
# =========================================================================

def load_locations(connection):

    cursor = connection.cursor()

    cursor.execute("""
        SELECT LocationID, County, SubCounty, UrbanRural, Region
        FROM DimLocation
    """)

    rows = cursor.fetchall()
    cursor.close()

    if not rows:
        raise RuntimeError(
            "DimLocation is empty. Run the Phase 3 seed script first."
        )

    return rows


# =========================================================================
# 8. GENERATE AGENTS
# =========================================================================

def generate_agents(connection):

    print("\n[4/6] Generating agents...")
    print(f"    Target agents: {NUM_AGENTS:,}")

    locations = load_locations(connection)

    cursor = connection.cursor()
    cursor.execute("DELETE FROM DimAgent")
    connection.commit()

    agent_types = ["Standard Agent", "Super Agent", "Merchant Agent", "Banking Agent"]
    agent_type_weights = [0.65, 0.10, 0.15, 0.10]

    statuses = ["Active", "Inactive", "Suspended"]
    status_weights = [0.88, 0.09, 0.03]

    # FIX #7: Derive region weights from actual DimLocation data
    region_location_map = {}

    for location in locations:
        location_id = location[0]
        region = location[4]

        if region not in region_location_map:
            region_location_map[region] = []

        region_location_map[region].append(location)

    # Calculate region weights from actual location counts
    region_counts = {r: len(locs) for r, locs in region_location_map.items()}
    total = sum(region_counts.values())
    region_weights = {r: count / total for r, count in region_counts.items()}

    regions = list(region_weights.keys())
    region_probs = [region_weights[r] for r in regions]

    insert_sql = """
        INSERT INTO DimAgent
        (AgentName, AgentType, AgentStartDate, AgentStatus, LocationID)
        VALUES (%s,%s,%s,%s,%s)
    """

    rows = []

    for i in range(NUM_AGENTS):

        agent_name = f"Agent {i + 1:05d}"
        agent_type = weighted_choice(agent_types, agent_type_weights)
        agent_start = random_date(date(2023, 1, 1), date(2025, 9, 30))
        status = weighted_choice(statuses, status_weights)

        selected_region = weighted_choice(regions, region_probs)
        selected_location = random.choice(region_location_map[selected_region])
        location_id = selected_location[0]

        rows.append((agent_name, agent_type, agent_start, status, location_id))

        if len(rows) >= BATCH_SIZE:
            cursor.executemany(insert_sql, rows)
            connection.commit()
            rows.clear()

    if rows:
        cursor.executemany(insert_sql, rows)
        connection.commit()

    print(f"    ✓ {NUM_AGENTS:,} agents generated.")
    cursor.close()


# =========================================================================
# 9. LOAD DIMENSION DATA FOR TRANSACTION GENERATION
# =========================================================================

def load_dimension_data(connection):

    cursor = connection.cursor()

    cursor.execute("SELECT CustomerID FROM DimCustomer")
    customer_ids = [row[0] for row in cursor.fetchall()]

    cursor.execute("""
        SELECT AgentID, AgentStartDate, AgentStatus, LocationID
        FROM DimAgent
    """)
    agents = cursor.fetchall()

    cursor.execute("SELECT ProviderID, ProviderName FROM DimProvider")
    providers = cursor.fetchall()

    cursor.execute("""
        SELECT TransactionTypeID, TransactionType
        FROM DimTransactionType
    """)
    transaction_types = cursor.fetchall()

    cursor.close()

    if not customer_ids:
        raise RuntimeError("DimCustomer is empty.")
    if not agents:
        raise RuntimeError("DimAgent is empty.")
    if not providers:
        raise RuntimeError("DimProvider is empty.")
    if not transaction_types:
        raise RuntimeError("DimTransactionType is empty.")

    return (customer_ids, agents, providers, transaction_types)


# =========================================================================
# 10. TRANSACTION AMOUNT MODEL (FIX #6: Added error handling)
# =========================================================================

def generate_transaction_amount(transaction_type):
    """
    Generate realistic synthetic transaction amounts.

    Amounts are intentionally skewed:
    many transactions are relatively small,
    while a smaller number are significantly larger.
    """

    amount_ranges = {
        "Cash Deposit": (100, 80_000),
        "Cash Withdrawal": (100, 50_000),
        "Send Money": (50, 30_000),
        "Bill Payment": (50, 100_000),
        "Airtime Purchase": (10, 10_000),
        "Merchant Payment": (50, 50_000),
        "Bank Transfer": (500, 250_000),
        "Account Deposit": (500, 200_000),
        "Account Withdrawal": (500, 100_000)
    }

    # FIX #6: Use .get() with default fallback
    minimum, maximum = amount_ranges.get(
        transaction_type,
        (50, 10_000)  # Conservative default
    )

    # Log-normal distribution produces realistic financial skew.
    value = np.random.lognormal(
        mean=math.log(maximum * 0.08),
        sigma=1.05
    )

    value = clamp(value, minimum, maximum)

    return round(value, 2)


# =========================================================================
# 11. COMMISSION MODEL
# =========================================================================

def calculate_commission(transaction_type, amount, provider_name):
    """Calculate realistic commission based on transaction type and provider."""

    rates = {
        "Cash Deposit": 0.0050,
        "Cash Withdrawal": 0.0075,
        "Send Money": 0.0040,
        "Bill Payment": 0.0030,
        "Airtime Purchase": 0.0020,
        "Merchant Payment": 0.0025,
        "Bank Transfer": 0.0035,
        "Account Deposit": 0.0040,
        "Account Withdrawal": 0.0050
    }

    rate = rates.get(transaction_type, 0.003)
    commission = amount * rate

    # Small provider adjustment
    if provider_name == "Airtel Money":
        commission *= 0.95
    elif provider_name == "Bank Agency Banking":
        commission *= 1.10

    return round(commission, 2)


# =========================================================================
# 12. PROCESSING COST MODEL
# =========================================================================

def calculate_processing_cost(transaction_type, amount):
    """Calculate processing cost based on transaction type and amount."""

    base_cost = {
        "Cash Deposit": 3.00,
        "Cash Withdrawal": 4.00,
        "Send Money": 2.50,
        "Bill Payment": 2.00,
        "Airtime Purchase": 1.50,
        "Merchant Payment": 2.00,
        "Bank Transfer": 6.00,
        "Account Deposit": 5.00,
        "Account Withdrawal": 5.50
    }

    cost = base_cost.get(transaction_type, 2.50)

    # Slightly increase processing cost for larger transactions.
    variable_cost = amount * 0.0002

    return round(cost + variable_cost, 2)


# =========================================================================
# 13. TRANSACTION DURATION
# =========================================================================

def generate_duration(transaction_type):
    """Generate realistic transaction duration in seconds."""

    duration_ranges = {
        "Cash Deposit": (20, 180),
        "Cash Withdrawal": (20, 180),
        "Send Money": (10, 120),
        "Bill Payment": (15, 150),
        "Airtime Purchase": (5, 60),
        "Merchant Payment": (5, 90),
        "Bank Transfer": (30, 240),
        "Account Deposit": (30, 240),
        "Account Withdrawal": (30, 240)
    }

    minimum, maximum = duration_ranges.get(transaction_type, (10, 120))

    return random.randint(minimum, maximum)


# =========================================================================
# 14. PROVIDER SELECTION
# =========================================================================

def select_provider(transaction_type, providers):
    """Select a provider based on transaction type and realistic probabilities."""

    provider_map = {
        "M-Pesa": None,
        "Airtel Money": None,
        "Bank Agency Banking": None
    }

    for provider_id, provider_name in providers:
        provider_map[provider_name] = provider_id

    # Transaction-specific provider probabilities.
    if transaction_type in [
        "Cash Deposit", "Cash Withdrawal", "Send Money",
        "Airtime Purchase", "Merchant Payment"
    ]:
        names = ["M-Pesa", "Airtel Money", "Bank Agency Banking"]
        weights = [0.84, 0.11, 0.05]

    elif transaction_type in [
        "Bank Transfer", "Account Deposit", "Account Withdrawal"
    ]:
        names = ["M-Pesa", "Airtel Money", "Bank Agency Banking"]
        weights = [0.55, 0.10, 0.35]

    else:
        names = ["M-Pesa", "Airtel Money", "Bank Agency Banking"]
        weights = [0.80, 0.12, 0.08]

    provider_name = weighted_choice(names, weights)

    return (provider_map[provider_name], provider_name)


# =========================================================================
# 15. TRANSACTION STATUS
# =========================================================================

def generate_status():
    """
    Synthetic operational outcome.

    Success     : 96%
    Failed      : 3%
    Reversed    : 1%
    """

    statuses = ["Success", "Failed", "Reversed"]
    weights = [0.96, 0.03, 0.01]

    return weighted_choice(statuses, weights)


# =========================================================================
# 16. GENERATE FACT TRANSACTIONS (FIX #3, #4, #5: Optimized)
# =========================================================================

INSERT_FACT_SQL = """
    INSERT INTO FactTransactions
    (DateKey, AgentID, CustomerID, ProviderID, TransactionTypeID,
     TransactionAmount, Commission, ProcessingCost,
     TransactionStatus, TransactionDuration)
    VALUES (%s,%s,%s,%s,%s, %s,%s,%s,%s,%s)
"""


def generate_transactions(connection, providers):
    """
    Generate synthetic transactions.

    FIX #4: providers passed as parameter instead of global
    """

    print("\n[5/6] Generating transactions...")
    print(f"    Target transactions: {NUM_TRANSACTIONS:,}")
    print(f"    Batch size: {BATCH_SIZE:,}")

    (customer_ids, agents, _, transaction_types) = load_dimension_data(connection)

    cursor = connection.cursor()

    print("    Clearing existing FactTransactions...")
    cursor.execute("DELETE FROM FactTransactions")
    connection.commit()

    # FIX #3: Build eligible agents list ONCE before the loop
    active_agents = [agent for agent in agents if agent[2] == "Active"]

    # FIX #5: Build transaction type weights mapping explicitly
    transaction_type_weights = {
        "Cash Deposit": 0.15,
        "Cash Withdrawal": 0.18,
        "Send Money": 0.20,
        "Bill Payment": 0.10,
        "Airtime Purchase": 0.08,
        "Merchant Payment": 0.15,
        "Bank Transfer": 0.05,
        "Account Deposit": 0.05,
        "Account Withdrawal": 0.04
    }

    # Build weights list in database order
    weights = [
        transaction_type_weights.get(type_name, 0.01)
        for type_id, type_name in transaction_types
    ]

    rows = []

    for transaction_number in range(1, NUM_TRANSACTIONS + 1):

        # Select transaction type with explicit weights
        transaction_type_id, transaction_type = weighted_choice(
            transaction_types,
            weights
        )

        # Customer
        customer_id = random.choice(customer_ids)

        # Agent (prefer active, but include inactive/suspended occasionally)
        if random.random() < 0.94:
            agent = random.choice(active_agents)
        else:
            agent = random.choice(agents)

        agent_id = agent[0]
        agent_start_date = agent[1]

        # Transaction date (ensure after agent start date)
        transaction_date = random_date(
            max(START_DATE, agent_start_date),
            END_DATE
        )

        # Provider
        provider_id, provider_name = select_provider(
            transaction_type,
            providers
        )

        # Amount
        amount = generate_transaction_amount(transaction_type)

        # Commission
        commission = calculate_commission(
            transaction_type,
            amount,
            provider_name
        )

        # Processing cost
        processing_cost = calculate_processing_cost(
            transaction_type,
            amount
        )

        # Status
        status = generate_status()

        # Duration
        duration = generate_duration(transaction_type)

        rows.append(
            (
                transaction_date, agent_id, customer_id, provider_id,
                transaction_type_id, amount, commission, processing_cost,
                status, duration
            )
        )

        # Batch insert
        if len(rows) >= BATCH_SIZE:
            cursor.executemany(INSERT_FACT_SQL, rows)
            connection.commit()
            rows.clear()

            if transaction_number % 100_000 == 0:
                print(
                    f"    ✓ {transaction_number:,} "
                    f"/ {NUM_TRANSACTIONS:,} transactions"
                )

    # Insert remaining rows
    if rows:
        cursor.executemany(INSERT_FACT_SQL, rows)
        connection.commit()

    print(f"    ✓ {NUM_TRANSACTIONS:,} transactions generated.")
    cursor.close()


# =========================================================================
# 17. DATA QUALITY VALIDATION
# =========================================================================

def validate_database(connection):

    print("\n[6/6] Running data-quality validation...")

    cursor = connection.cursor()

    # Table counts
    tables = [
        "DimDate", "DimLocation", "DimProvider", "DimCustomer",
        "DimTransactionType", "DimAgent", "FactTransactions"
    ]

    print("\nTABLE COUNTS")
    print("-" * 50)

    for table in tables:
        cursor.execute(f"SELECT COUNT(*) FROM {table}")
        count = cursor.fetchone()[0]
        print(f"{table:<25} {count:>12,}")

    # Foreign key integrity
    print("\nFOREIGN KEY VALIDATION")
    print("-" * 50)

    validation_queries = {
        "Orphan Dates": """
            SELECT COUNT(*) FROM FactTransactions f
            LEFT JOIN DimDate d ON f.DateKey = d.DateKey
            WHERE d.DateKey IS NULL
        """,
        "Orphan Agents": """
            SELECT COUNT(*) FROM FactTransactions f
            LEFT JOIN DimAgent a ON f.AgentID = a.AgentID
            WHERE a.AgentID IS NULL
        """,
        "Orphan Customers": """
            SELECT COUNT(*) FROM FactTransactions f
            LEFT JOIN DimCustomer c ON f.CustomerID = c.CustomerID
            WHERE c.CustomerID IS NULL
        """,
        "Orphan Providers": """
            SELECT COUNT(*) FROM FactTransactions f
            LEFT JOIN DimProvider p ON f.ProviderID = p.ProviderID
            WHERE p.ProviderID IS NULL
        """,
        "Orphan Transaction Types": """
            SELECT COUNT(*) FROM FactTransactions f
            LEFT JOIN DimTransactionType t
                ON f.TransactionTypeID = t.TransactionTypeID
            WHERE t.TransactionTypeID IS NULL
        """
    }

    for name, query in validation_queries.items():
        cursor.execute(query)
        result = cursor.fetchone()[0]
        status = "PASS" if result == 0 else "FAIL"
        print(f"{name:<30} {status:<6} ({result:,})")

    # Negative financial values
    cursor.execute("""
        SELECT COUNT(*) FROM FactTransactions
        WHERE TransactionAmount < 0 OR Commission < 0 OR ProcessingCost < 0
    """)
    negative_values = cursor.fetchone()[0]
    print(
        f"{'Negative financial values':<30} "
        f"{'PASS' if negative_values == 0 else 'FAIL'} ({negative_values:,})"
    )

    # Transaction status distribution
    print("\nTRANSACTION STATUS")
    print("-" * 50)

    cursor.execute("""
        SELECT
            TransactionStatus, COUNT(*) AS Transactions,
            ROUND(COUNT(*) * 100 / (SELECT COUNT(*) FROM FactTransactions), 2)
                AS Percentage
        FROM FactTransactions
        GROUP BY TransactionStatus
        ORDER BY Transactions DESC
    """)

    for row in cursor.fetchall():
        print(f"{row[0]:<15} {row[1]:>12,} {row[2]:>8.2f}%")

    # Provider distribution
    print("\nPROVIDER DISTRIBUTION")
    print("-" * 50)

    cursor.execute("""
        SELECT
            p.ProviderName, COUNT(*) AS Transactions,
            ROUND(COUNT(*) * 100 / (SELECT COUNT(*) FROM FactTransactions), 2)
                AS Percentage
        FROM FactTransactions f
        JOIN DimProvider p ON f.ProviderID = p.ProviderID
        GROUP BY p.ProviderName
        ORDER BY Transactions DESC
    """)

    for row in cursor.fetchall():
        print(f"{row[0]:<25} {row[1]:>12,} {row[2]:>8.2f}%")

    # Financial summary
    print("\nFINANCIAL SUMMARY")
    print("-" * 50)

    cursor.execute("""
        SELECT
            COUNT(*) AS Transactions,
            ROUND(SUM(TransactionAmount), 2) AS TotalValue,
            ROUND(AVG(TransactionAmount), 2) AS AverageValue,
            ROUND(SUM(Commission), 2) AS TotalCommission,
            ROUND(SUM(ProcessingCost), 2) AS TotalProcessingCost,
            ROUND(SUM(Commission - ProcessingCost), 2) AS NetRevenue
        FROM FactTransactions
    """)

    summary = cursor.fetchone()

    print(f"Transactions       : {summary[0]:,}")
    print(f"Total Value        : KES {summary[1]:,.2f}")
    print(f"Average Transaction: KES {summary[2]:,.2f}")
    print(f"Commission         : KES {summary[3]:,.2f}")
    print(f"Processing Cost    : KES {summary[4]:,.2f}")
    print(f"Net Revenue        : KES {summary[5]:,.2f}")

    cursor.close()


# =========================================================================
# 18. MAIN PROGRAM
# =========================================================================

def main():

    print("=" * 75)
    print("KENYA MOBILE MONEY & AGENT NETWORK ANALYTICS")
    print("PHASE 4 — SYNTHETIC DATA GENERATION (v1)")
    print("=" * 75)

    print("\nConfiguration")
    print("-" * 50)

    print(f"Customers       : {NUM_CUSTOMERS:,}")
    print(f"Agents          : {NUM_AGENTS:,}")
    print(f"Transactions    : {NUM_TRANSACTIONS:,}")
    print(f"Date Range      : {START_DATE} → {END_DATE}")
    print(f"Random Seed     : {RANDOM_SEED}")

    connection = None

    try:

        connection = get_connection()
        print("\n✓ MySQL connection successful.")

        # Clear old fact data FIRST before clearing dimensions
        cursor = connection.cursor()
        print("\nClearing old data...")
        cursor.execute("SET FOREIGN_KEY_CHECKS=0")
        cursor.execute("DELETE FROM FactTransactions")
        cursor.execute("DELETE FROM DimAgent")
        cursor.execute("DELETE FROM DimCustomer")
        cursor.execute("SET FOREIGN_KEY_CHECKS=1")
        connection.commit()
        cursor.close()

        # Populate DimDate
        populate_dim_date(connection)

        # Populate transaction types
        populate_transaction_types(connection)

        # Generate customers
        generate_customers(connection)

        # Generate agents
        generate_agents(connection)

        # Load providers (FIX #4: load once, pass to function)
        cursor = connection.cursor()
        cursor.execute("SELECT ProviderID, ProviderName FROM DimProvider")
        providers = cursor.fetchall()
        cursor.close()

        if not providers:
            raise RuntimeError(
                "DimProvider is empty. Run Phase 3 seed script first."
            )

        # Generate transactions
        generate_transactions(connection, providers)

        # Validate
        validate_database(connection)

        print("\n" + "=" * 75)
        print("PHASE 4 COMPLETED SUCCESSFULLY ✓")
        print("=" * 75)

    except Exception as error:

        print("\n❌ ERROR")
        print("-" * 50)
        print(str(error))

        if connection and connection.is_connected():
            connection.rollback()

    finally:

        if connection and connection.is_connected():
            connection.close()
            print("\n✓ MySQL connection closed.")


# =========================================================================
# PROGRAM ENTRY POINT
# =========================================================================

if __name__ == "__main__":
    main()