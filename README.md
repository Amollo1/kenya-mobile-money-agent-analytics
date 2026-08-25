# Kenya Mobile Money & Agent Network Analytics

**A full-stack data analytics portfolio project** — from synthetic data generation through a dimensional database model to an interactive Power BI dashboard — analyzing the profitability and geographic performance of a simulated Kenyan mobile-money agent network.

![Executive Overview](images/02_executive_overview.jpeg)

---

## Business Problem

Kenya's mobile-money agent network has grown rapidly — CBK reported 381,116 active agents in 2024, rising to 473,536 by December 2025, processing roughly KSh 722.5 billion in monthly transaction value. But growth in agent numbers has not translated into growth in agent economics: average annual M-Pesa agent commissions fell to approximately KSh 112,244 for the year ended March 2026.

**Central question:** How profitable is the agent network, where is it performing well, and where is it losing money or facing operational risk?

*All CBK/industry figures above are public statistics used only to ground realistic assumptions. All transaction-level data in this project is synthetic and does not represent Safaricom, Airtel, or any bank's actual data.*

📄 **[Read the full Business Insights write-up →](documentation/PHASE9_business_insights_writeup.md)**

---

## What This Project Demonstrates

- **Database design:** A dimensional (star schema) model in MySQL — one fact table, five dimension tables
- **Data engineering:** A Python pipeline generating 1,000,000 statistically realistic synthetic transactions (log-normal amount distributions, weighted provider/transaction-type probabilities grounded in real Kenyan market share data)
- **SQL analysis:** 10 exploratory queries answering specific business questions, with documented findings
- **BI development:** A 2-page Power BI dashboard with 15 DAX measures, synced cross-page filters, custom tooltips, a dynamic insight card, and in-app page navigation
- **Business communication:** A written insights document translating technical findings into strategic recommendations

---

## Dashboard Preview

### Executive Overview
High-level KPIs, revenue trend, provider comparison, and transaction type profitability.

![Executive Overview](images/02-executive-overview.png)

### Geographic Intelligence
County-level performance, agent saturation analysis, and a revenue map.

![Geographic Intelligence](images/06-geographic-intelligence.png)

**Key visual — Revenue per Agent by County:**

![Scatter Plot](images/07-scatter-plot.png)

This scatter plot was the project's most important analytical finding: revenue per agent stays broadly flat (~KES 3,500–3,900) regardless of how many agents operate in a county. The initial hypothesis — that dense urban markets like Nairobi would show diminishing per-agent returns — was **not** strongly supported by the data, and the write-up reports that honestly rather than forcing the original narrative.

---

## Tech Stack

| Layer | Tools |
|---|---|
| Data Generation | Python (`mysql-connector-python`, `numpy`, `python-dotenv`) |
| Database | MySQL 8.x |
| Analysis | SQL |
| Visualization | Power BI Desktop, DAX |
| Version Control | Git / GitHub |

---

## Data Model

![Star Schema](images/01-star-schema.png)

A classic star schema: **FactTransactions** (1,000,000 rows) at the center, surrounded by **DimDate**, **DimAgent**, **DimCustomer**, **DimProvider**, and **DimTransactionType**. **DimLocation** connects through DimAgent (agents are assigned to a location; transactions inherit location context through their agent).

| Table | Rows | Purpose |
|---|---|---|
| FactTransactions | 1,000,000 | Transaction-level facts: amount, commission, cost, status |
| DimCustomer | 100,000 | Customer segment, age group, gender |
| DimAgent | 10,000 | Agent type, status, start date, location |
| DimLocation | 103 | Kenya's 47 counties + sub-counties, region, urban/rural flag |
| DimDate | 365 | Full calendar year 2025 |
| DimProvider | 3 | M-Pesa, Airtel Money, Bank Agency Banking |
| DimTransactionType | 9 | Cash Deposit, Withdrawal, Send Money, Bill Payment, etc. |

---

## Key Findings (Summary)

| Finding | Detail |
|---|---|
| Overall profitability | 88% net revenue margin on KES 41.6M gross revenue |
| Provider mix | M-Pesa ~79.5% of volume, but no single-provider revenue dependency |
| Volume ≠ profit | Bank Transfer is low-volume but disproportionately profitable per transaction |
| Agent concentration | Top 10 agents (of 10,000) show a tight revenue spread — no extreme outliers |
| Geographic saturation | **Not observed** — revenue per agent is stable across county sizes |
| Reliability | 95.98% transaction success rate |

Full detail, interpretation, and strategic recommendations in the [Business Insights write-up](documentation/PHASE9_business_insights_writeup.md).

---

## Repository Structure

```
kenya-mobile-money-agent-analytics/
│
├── README.md
├── LICENSE
├── .gitignore
│
├── images/                    # Dashboard screenshots used in this README + insights doc
├── sql/                       # Star schema DDL + reference data seed script
├── python/                    # Synthetic data generation script
├── data/raw/                  # Exported dimension table CSVs (fact table excluded — see below)
├── powerbi/                   # .pbix dashboard file
├── documentation/             # Business problem, SQL findings, insights write-up
└── dax/                       # All 15 DAX measures with descriptions
```

**Note:** `FactTransactions.csv` (~69MB, 1M rows) is excluded from this repo to keep it lightweight. Run `python/04_generate_transactions_CORRECTED.py` locally against the provided schema to reproduce the full dataset.

---

## How to Reproduce This Project

1. **Set up the database**
   ```bash
   mysql -u root -p < sql/schema.sql
   mysql -u root -p < sql/seed_reference_data.sql
   ```

2. **Configure environment variables**
   Create a `.env` file in the project root:
   ```
   DB_HOST=localhost
   DB_USER=root
   DB_PASSWORD=your_password
   ```

3. **Install Python dependencies**
   ```bash
   pip install mysql-connector-python python-dotenv numpy
   ```

4. **Generate the synthetic dataset**
   ```bash
   python python/04_generate_transactions_CORRECTED.py
   ```
   Generates 100,000 customers, 10,000 agents, and 1,000,000 transactions (~5-10 minutes).

5. **Open the dashboard**
   Open `powerbi/Kenya_Mobile_Money_Analytics.pbix` in Power BI Desktop and refresh the data connection to point to your local MySQL instance.

---

## DAX Measures

15 measures covering financial performance, rates/margins, status breakdowns, and geographic callouts. Full formulas and descriptions in [`dax/dax_measures.md`](dax/dax_measures.md).

Highlight — the KPI most directly tied to the business question:
```dax
Revenue per Active Agent = 
DIVIDE(
    [Net Revenue],
    CALCULATE(DISTINCTCOUNT(FactTransactions[AgentID]), FactTransactions[TransactionStatus]="Success")
)
```

---

## Project Documentation

- [Phase 1: Business Problem & KPIs](documentation/PHASE1_business_problem_and_kpis.md)
- [Phase 5: SQL Analysis Summary](documentation/PHASE5_sql_analysis_summary.md)
- [Phase 9: Business Insights Write-Up](documentation/PHASE9_business_insights_writeup.md)
- [DAX Measures Reference](dax/dax_measures.md)

---

## About the Author

**Benard Omoga**
IT Specialist | Data Analyst | Web Developer | AI Content Creator

Experienced in Python, SQL, R, SPSS, Excel, Power BI, Tableau, databases, data engineering, web development, automation, and AI. This project was built end-to-end — data architecture, synthetic data engineering, SQL analysis, DAX, and dashboard design — as a demonstration of full-stack analytics capability for data/BI roles.

[LinkedIn](#) · [Portfolio](#) · [Email](#)

---

## License

This project is released under the [MIT License](LICENSE). All transaction-level data is synthetic and freely usable; it does not represent real Safaricom, Airtel, or bank data.

---

*Portfolio Project | 2026*
