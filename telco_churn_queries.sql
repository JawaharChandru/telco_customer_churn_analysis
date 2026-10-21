-- =====================================================================
-- TELCO CUSTOMER CHURN ANALYSIS: SQL SCRIPT
-- Tool   : MySQL Workbench
-- Schema : teleco_churn
-- Data   : telco_customer_churn.csv (7,043 customers, 21 columns)
-- Steps  : 1) Setup and import   2) Data cleaning   3) Analysis
-- =====================================================================


-- =====================================================================
-- STEP 1: SETUP AND IMPORT
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS teleco_churn;
USE teleco_churn;

CREATE TABLE IF NOT EXISTS customers (
  customerID       VARCHAR(20),
  gender           VARCHAR(10),
  SeniorCitizen    INT,
  Partner          VARCHAR(5),
  Dependents       VARCHAR(5),
  tenure           INT,
  PhoneService     VARCHAR(5),
  MultipleLines    VARCHAR(30),
  InternetService  VARCHAR(20),
  OnlineSecurity   VARCHAR(30),
  OnlineBackup     VARCHAR(30),
  DeviceProtection VARCHAR(30),
  TechSupport      VARCHAR(30),
  StreamingTV      VARCHAR(30),
  StreamingMovies  VARCHAR(30),
  Contract         VARCHAR(20),
  PaperlessBilling VARCHAR(5),
  PaymentMethod    VARCHAR(40),
  MonthlyCharges   DECIMAL(8,2),
  TotalCharges     VARCHAR(20),   -- text at import because some rows are blank
  Churn            VARCHAR(5)
);

-- Import telco_customer_churn.csv using the Table Data Import Wizard
-- (right-click the customers table > Table Data Import Wizard), then verify:

-- Expect 7043 rows
SELECT COUNT(*) FROM customers;

-- Expect 5178 No and 1865 Yes
SELECT Churn, COUNT(*) FROM customers GROUP BY Churn;


-- =====================================================================
-- STEP 2: DATA CLEANING
-- =====================================================================

-- 2.1 Check for duplicate customers (expect no rows)
SELECT customerID, COUNT(*)
FROM customers
GROUP BY customerID
HAVING COUNT(*) > 1;

-- 2.2 Count blank TotalCharges (expect 11: new customers with tenure 0)
SELECT COUNT(*) FROM customers WHERE TRIM(TotalCharges) = '';

-- 2.3 Convert blanks to NULL, then change the column to a number type
SET SQL_SAFE_UPDATES = 0;

UPDATE customers
SET TotalCharges = NULL
WHERE TRIM(TotalCharges) = '';

ALTER TABLE customers MODIFY TotalCharges DECIMAL(10,2);

-- 2.4 Check for other missing values (expect all zeros)
SELECT
  SUM(customerID IS NULL)     AS id_nulls,
  SUM(tenure IS NULL)         AS tenure_nulls,
  SUM(MonthlyCharges IS NULL) AS monthly_nulls,
  SUM(Contract IS NULL)       AS contract_nulls,
  SUM(Churn IS NULL)          AS churn_nulls
FROM customers;

-- 2.5 Check the allowed values (expect 3, 3 and 4 values)
SELECT DISTINCT Contract        FROM customers;
SELECT DISTINCT InternetService FROM customers;
SELECT DISTINCT PaymentMethod   FROM customers;

-- 2.6 Create the clean view with two helper columns:
--     churn_flag   = 1 if the customer left, 0 if they stayed
--     tenure_group = bucket of how long the customer has stayed
CREATE OR REPLACE VIEW customers_clean AS
SELECT *,
  CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END AS churn_flag,
  CASE
    WHEN tenure BETWEEN 0 AND 12  THEN '0-12 months'
    WHEN tenure BETWEEN 13 AND 24 THEN '13-24 months'
    WHEN tenure BETWEEN 25 AND 48 THEN '25-48 months'
    ELSE '49+ months'
  END AS tenure_group
FROM customers;

-- Test the view
SELECT customerID, tenure, tenure_group, Churn, churn_flag
FROM customers_clean
LIMIT 10;


-- =====================================================================
-- STEP 3: ANALYSIS
-- =====================================================================

-- Q1: What is the overall churn rate?
-- Expect: 7043 customers, 1865 churned, 26.5%
SELECT COUNT(*)                          AS total_customers,
       SUM(churn_flag)                   AS churned,
       ROUND(100 * AVG(churn_flag), 1)   AS churn_pct
FROM customers_clean;

-- Q2: Which contract type loses the most customers?
-- Expect: Month-to-month about 44%, One year about 8%, Two year about 1%
SELECT Contract,
       COUNT(*)                          AS customers,
       SUM(churn_flag)                   AS churned,
       ROUND(100 * AVG(churn_flag), 1)   AS churn_pct
FROM customers_clean
GROUP BY Contract
ORDER BY churn_pct DESC;

-- Q3: Do new customers leave more than long-term customers?
-- Expect: 0-12 months about 51%, falling to about 5% for 49+ months
SELECT tenure_group,
       COUNT(*)                          AS customers,
       ROUND(100 * AVG(churn_flag), 1)   AS churn_pct
FROM customers_clean
GROUP BY tenure_group
ORDER BY churn_pct DESC;

-- Q4: Which internet service has the highest churn?
-- Expect: Fiber optic about 36%, DSL about 21%, No internet about 14%
SELECT InternetService,
       COUNT(*)                          AS customers,
       ROUND(100 * AVG(churn_flag), 1)   AS churn_pct
FROM customers_clean
GROUP BY InternetService
ORDER BY churn_pct DESC;

-- Q5: Does tech support help keep customers? (internet customers only)
-- Expect: No about 32.5%, Yes about 25%
SELECT TechSupport,
       COUNT(*)                          AS customers,
       ROUND(100 * AVG(churn_flag), 1)   AS churn_pct
FROM customers_clean
WHERE InternetService <> 'No'
GROUP BY TechSupport;

-- Q6: Which payment method has the highest churn?
-- Expect: Electronic check about 41% (highest)
SELECT PaymentMethod,
       COUNT(*)                          AS customers,
       ROUND(100 * AVG(churn_flag), 1)   AS churn_pct
FROM customers_clean
GROUP BY PaymentMethod
ORDER BY churn_pct DESC;

-- Q7: How much revenue is lost to churn?
-- Expect: about 137,597 per month and about 1,651,162 per year
SELECT ROUND(SUM(MonthlyCharges), 2)      AS monthly_revenue_lost,
       ROUND(SUM(MonthlyCharges) * 12, 2) AS yearly_revenue_lost
FROM customers_clean
WHERE churn_flag = 1;

-- Q8: Which exact segment is at the highest risk? (CTE)
-- Expect: Month-to-month, Fiber optic, 0-12 months at about 70% churn
WITH segment AS (
  SELECT Contract, InternetService, tenure_group,
         COUNT(*)                        AS customers,
         SUM(churn_flag)                 AS churned,
         ROUND(100 * AVG(churn_flag), 1) AS churn_pct
  FROM customers_clean
  GROUP BY Contract, InternetService, tenure_group
)
SELECT *
FROM segment
WHERE customers >= 50          -- ignore tiny groups
ORDER BY churn_pct DESC
LIMIT 5;

-- Q9: Rank contract and internet combinations by churn rate (window function)
-- Expect: Month-to-month with Fiber optic ranks first at about 59%
SELECT Contract, InternetService,
       ROUND(100 * AVG(churn_flag), 1)          AS churn_pct,
       RANK() OVER (ORDER BY AVG(churn_flag) DESC) AS churn_rank
FROM customers_clean
GROUP BY Contract, InternetService;

-- Q10: Split customers into four spending groups (NTILE)
-- Quartile 1 = the top 25% highest-paying customers
SELECT customerID, MonthlyCharges, Churn,
       NTILE(4) OVER (ORDER BY MonthlyCharges DESC) AS spend_quartile
FROM customers_clean;

-- BONUS: Churn rate by spending quartile
WITH q AS (
  SELECT churn_flag,
         NTILE(4) OVER (ORDER BY MonthlyCharges DESC) AS spend_quartile
  FROM customers_clean
)
SELECT spend_quartile,
       ROUND(100 * AVG(churn_flag), 1) AS churn_pct
FROM q
GROUP BY spend_quartile
ORDER BY spend_quartile;

-- AT-RISK CUSTOMERS: month-to-month, tenure 12 months or less, not yet churned
-- Expect: 847 customers (the list behind the At-Risk page in Power BI)
SELECT customerID, Contract, InternetService, PaymentMethod,
       tenure, MonthlyCharges
FROM customers_clean
WHERE Churn = 'No'
  AND Contract = 'Month-to-month'
  AND tenure <= 12
ORDER BY MonthlyCharges DESC;
