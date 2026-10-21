create schema teleco_churn;
use teleco_churn;
CREATE TABLE customers (
  customerID VARCHAR(20),
  gender VARCHAR(10),
  SeniorCitizen INT,
  Partner VARCHAR(5),
  Dependents VARCHAR(5),
  tenure INT,
  PhoneService VARCHAR(5),
  MultipleLines VARCHAR(30),
  InternetService VARCHAR(20),
  OnlineSecurity VARCHAR(30),
  OnlineBackup VARCHAR(30),
  DeviceProtection VARCHAR(30),
  TechSupport VARCHAR(30),
  StreamingTV VARCHAR(30),
  StreamingMovies VARCHAR(30),
  Contract VARCHAR(20),
  PaperlessBilling VARCHAR(5),
  PaymentMethod VARCHAR(40),
  MonthlyCharges DECIMAL(8,2),
  TotalCharges VARCHAR(20),
  Churn VARCHAR(5)
);
SELECT COUNT(*) FROM customers;
SELECT Churn, COUNT(*) FROM customers GROUP BY Churn;
USE teleco_churn;
SELECT customerID, COUNT(*)
FROM customers
GROUP BY customerID
HAVING COUNT(*) > 1;
SELECT COUNT(*) FROM customers WHERE TRIM(TotalCharges) = '';
SET SQL_SAFE_UPDATES = 0;
UPDATE customers
SET TotalCharges = NULL
WHERE TRIM(TotalCharges) = '';
ALTER TABLE customers MODIFY TotalCharges DECIMAL(10,2);
SELECT
  SUM(customerID IS NULL) AS id_nulls,
  SUM(tenure IS NULL) AS tenure_nulls,
  SUM(MonthlyCharges IS NULL) AS monthly_nulls,
  SUM(Contract IS NULL) AS contract_nulls,
  SUM(Churn IS NULL) AS churn_nulls
FROM customers;
SELECT DISTINCT Contract FROM customers;
SELECT DISTINCT InternetService FROM customers;
SELECT DISTINCT PaymentMethod FROM customers;
CREATE VIEW customers_clean AS
SELECT *,
  CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END AS churn_flag,
  CASE
    WHEN tenure BETWEEN 0 AND 12  THEN '0-12 months'
    WHEN tenure BETWEEN 13 AND 24 THEN '13-24 months'
    WHEN tenure BETWEEN 25 AND 48 THEN '25-48 months'
    ELSE '49+ months'
  END AS tenure_group
FROM customers;
SELECT customerID, tenure, tenure_group, Churn, churn_flag
FROM customers_clean
LIMIT 10;
SELECT COUNT(*) AS total_customers,
       SUM(churn_flag) AS churned,
       ROUND(100 * AVG(churn_flag), 1) AS churn_pct
FROM customers_clean;
SELECT Contract,
       COUNT(*) AS customers,
       SUM(churn_flag) AS churned,
       ROUND(100 * AVG(churn_flag), 1) AS churn_pct
FROM customers_clean
GROUP BY Contract
ORDER BY churn_pct DESC;
SELECT tenure_group,
       COUNT(*) AS customers,
       ROUND(100 * AVG(churn_flag), 1) AS churn_pct
FROM customers_clean
GROUP BY tenure_group
ORDER BY churn_pct DESC;
SELECT InternetService,
       COUNT(*) AS customers,
       ROUND(100 * AVG(churn_flag), 1) AS churn_pct
FROM customers_clean
GROUP BY InternetService
ORDER BY churn_pct DESC;
SELECT TechSupport,
       COUNT(*) AS customers,
       ROUND(100 * AVG(churn_flag), 1) AS churn_pct
FROM customers_clean
WHERE InternetService <> 'No'
GROUP BY TechSupport;
SELECT PaymentMethod,
       COUNT(*) AS customers,
       ROUND(100 * AVG(churn_flag), 1) AS churn_pct
FROM customers_clean
GROUP BY PaymentMethod
ORDER BY churn_pct DESC;
SELECT ROUND(SUM(MonthlyCharges), 2) AS monthly_revenue_lost,
       ROUND(SUM(MonthlyCharges) * 12, 2) AS yearly_revenue_lost
FROM customers_clean
WHERE churn_flag = 1;
WITH segment AS (
  SELECT Contract, InternetService, tenure_group,
         COUNT(*) AS customers,
         SUM(churn_flag) AS churned,
         ROUND(100 * AVG(churn_flag), 1) AS churn_pct
  FROM customers_clean
  GROUP BY Contract, InternetService, tenure_group
)
SELECT *
FROM segment
WHERE customers >= 50
ORDER BY churn_pct DESC
LIMIT 5;
SELECT Contract, InternetService,
       ROUND(100 * AVG(churn_flag), 1) AS churn_pct,
       RANK() OVER (ORDER BY AVG(churn_flag) DESC) AS churn_rank
FROM customers_clean
GROUP BY Contract, InternetService;
SELECT customerID, MonthlyCharges, Churn,
       NTILE(4) OVER (ORDER BY MonthlyCharges DESC) AS spend_quartile
FROM customers_clean;
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

