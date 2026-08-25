import mysql.connector
import csv
import os

conn = mysql.connector.connect(
    host="localhost",
<<<<<<< HEAD
    user="root",
    password="Database Password",
=======
    user="your user",
    password="database Pasword",
>>>>>>> 7b29e367d56195dc19670a27c9ad42e81d064478
    database="kenya_mobile_money"
)

cursor = conn.cursor()

tables = ['DimDate', 'DimLocation', 'DimProvider', 'DimCustomer', 
          'DimTransactionType', 'DimAgent', 'FactTransactions']

os.makedirs('data/raw', exist_ok=True)

for table in tables:
    print(f"Exporting {table}...")
    
    cursor.execute(f"SELECT * FROM {table} LIMIT 0")
    column_names = [desc[0] for desc in cursor.description]
    
    cursor.execute(f"SELECT * FROM {table}")
    rows = cursor.fetchall()
    
    filepath = f'data/raw/{table}.csv'
    with open(filepath, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(column_names)
        writer.writerows(rows)
    
    print(f"✓ {table} exported")

cursor.close()
conn.close()
print("\n✓ All tables exported successfully!")
