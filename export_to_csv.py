import mysql.connector
import csv
import os

conn = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Your Password",
    database="kenya_mobile_money"
)

cursor = conn.cursor()
tables = ['DimDate', 'DimLocation', 'DimProvider', 'DimCustomer', 'DimTransactionType', 'DimAgent', 'FactTransactions']
os.makedirs('data/raw', exist_ok=True)

for table in tables:
    print(f"Exporting {table}...")
    
    # Get column names FIRST
    cursor.execute(f"SELECT * FROM {table} LIMIT 1")
    column_names = [desc[0] for desc in cursor.description]
    cursor.fetchall()  # Consume the result
    
    # Now get all data
    cursor.execute(f"SELECT * FROM {table}")
    rows = cursor.fetchall()
    
    # Write to CSV
    filepath = f'data/raw/{table}.csv'
    with open(filepath, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(column_names)
        writer.writerows(rows)
    print(f"✓ {table} exported")

cursor.close()
conn.close()
print("\n✓ All tables exported successfully!")