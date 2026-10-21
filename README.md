# Telco Customer Churn Analysis

An end-to-end analysis of why telecom customers leave, built with SQL, Python and Power BI.

## Business Problem
A telecom company is losing about 26.5% of its customers. This project finds which customers are leaving, why, and what the company can do to keep them.

## Dataset
Synthetic dataset modelled on the public Telco Customer Churn schema: 7,043 customers and 21 columns covering demographics, services, contract, billing and churn status.

## Tools Used
- MySQL for data cleaning and analysis
- Python (pandas, seaborn, matplotlib) in Jupyter Notebook
- Power BI for the dashboard
- GitHub for version control

## Process
1. Imported the data into MySQL and checked quality (duplicates, nulls, allowed values).
2. Fixed 11 blank TotalCharges values (new customers with zero tenure) and created a clean view with churn_flag and tenure_group columns.
3. Analysed churn with SQL using GROUP BY, CASE WHEN, CTEs, RANK() and NTILE().
4. Confirmed the findings with charts in Python.
5. Built a 3-page Power BI dashboard: Overview, Drivers and At-Risk Customers.

## Key Findings
- Overall churn is 26.5% (1,865 of 7,043 customers).
- Month-to-month customers churn at 44.2%, versus 8.3% for one-year and 1.3% for two-year contracts.
- Churn is 51.2% in the first 12 months and falls to 4.7% after 48 months.
- Fiber optic customers churn at 36.3%, versus 21.3% for DSL.
- Customers without tech support churn at 32.5%, versus 25.2% with it.
- Electronic check users churn at 40.8%, the highest of all payment methods.
- Month-to-month customers with Fiber optic are the riskiest group, at 59.0% churn.
- Churn costs about 137,600 per month (roughly 1.65 million per year) in lost revenue.

## Recommendations
1. Offer discounts or upgrades to move month-to-month customers onto one-year plans.
2. Start a 90-day welcome program for new customers.
3. Bundle tech support and online security with fiber plans.
4. Encourage automatic payments with a small bill discount.
5. Use the At-Risk Customers list (847 customers) for proactive retention calls.

## Dashboard Screenshots
### Overview
![Overview](screenshots/overview.png)

### Churn Drivers
![Drivers](screenshots/drivers.png)

### At-Risk Customers
![At-Risk Customers]<img width="2549" height="1445" alt="risk_customers" src="https://github.com/user-attachments/assets/de19e25a-654a-470b-a84a-c9fc83de42c4" />


## Repository Structure
- data: raw and cleaned CSV files
- sql: SQL queries for cleaning and analysis
- notebook: Python analysis notebook
- dashboard: Power BI file (.pbix)
- screenshots: dashboard images

## How to Reproduce
1. Create a MySQL schema and import telco_customer_churn.csv into a table called customers.
2. Run the SQL scripts in the sql folder to clean the data and create the customers_clean view.
3. Export customers_clean to CSV and run the notebook in the notebook folder.
4. Open the .pbix file in Power BI Desktop and refresh the data source.

## Limitations
- The dataset is synthetic, so the exact numbers are illustrative.
- The findings show associations, not proof of cause. A pilot test would be needed to confirm that the recommended actions reduce churn.

## Author
Jawahar Chandru
