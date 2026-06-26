-- ============================================================
-- ONLINE RETAIL ANALYSIS
-- MySQL portfolio project
--
-- Source  : https://www.kaggle.com/datasets/carrie1/ecommerce-data/data
--
-- BEFORE RUNNING THIS SCRIPT:
-- 1. In MySQL Workbench, create a schema called online_retail
-- 2. Move your 'data.csv' file into the MySQL secure uploads folder:
--    C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/
-- 3. Run this script. The LOAD DATA INFILE engine will automatically
--    import, parse, and clean the dataset.
-- ============================================================

USE online_retail;


-- ============================================================
-- 1. RAW TABLE
-- Columns are optimized for import. Invoicedate is set as 
-- DATETIME to natively store parsed dates during the LOAD DATA 
-- stage, bypassing Import Wizard limitations.
-- ============================================================

DROP TABLE IF EXISTS raw_orders;

CREATE TABLE raw_orders (
    invoiceno   VARCHAR(20),   
    stockcode   VARCHAR(20),   
    description VARCHAR(255),  
    quantity    VARCHAR(20),   
    invoicedate DATETIME,      
    unitprice   VARCHAR(20),   
    customerid  VARCHAR(50),
    country     VARCHAR(100) 
);
-- ============================================================
-- DATA IMPORT VIA AUTOMATED SCRIPT
-- Bypasses the Import Wizard limitations.
-- Parses dates into standard SQL format dynamically on ingestion.
-- ============================================================
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data.csv' --change path to where you saved the data
INTO TABLE raw_orders
CHARACTER SET latin1 
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(InvoiceNo, StockCode, Description, Quantity, @dummy_date, UnitPrice, CustomerID, Country)
SET InvoiceDate = STR_TO_DATE(@dummy_date, '%m/%d/%Y %H:%i');

-- ============================================================
-- 2. CLEAN ORDERS TABLE
-- Converts types, applies business filters, and adds derived columns. 
-- Materialised as a physical table so analysis views query pre-filtered data.
--
-- invoice_date is pulled cleanly from raw_orders since dates were
-- already normalized during the file load execution.
--
-- order_date (date only) is added as a clean join key for the
-- Power BI relationship to dim_date.
--
-- All exclusion decisions are documented in the README.
-- ============================================================

DROP TABLE IF EXISTS clean_orders;

CREATE TABLE clean_orders AS
SELECT
    invoiceno,
    stockcode,
    TRIM(description)                                           AS description,
    CAST(quantity AS SIGNED)                                    AS quantity,
    CAST(unitprice AS DECIMAL(10,2))                            AS unit_price,
    invoicedate                                                 AS invoice_date,
    DATE(invoicedate)                                           AS order_date,
    DATE_FORMAT(invoicedate,'%Y-%m')                            AS 'year_month',
    ROUND(CAST(quantity AS DECIMAL(10,2))
          * CAST(unitprice AS DECIMAL(10,2)), 2)                AS revenue,
    CASE
        WHEN customerid IS NULL OR TRIM(customerid) = '' THEN 'Guest'
        ELSE TRIM(customerid)
    END                                                         AS customer_id,
    TRIM(country)                                               AS country
FROM raw_orders
WHERE CAST(unitprice AS DECIMAL(10,2)) > 0   -- Exclude true zero/bad prices
  AND CAST(quantity AS SIGNED) != 0          -- Exclude phantom zero-quantity rows
  AND description IS NOT NULL 
  AND TRIM(description) != '';

-- Indexes on clean_orders: all analysis views query this table.
-- order_date : Power BI relationship to dim_date; date-range filters
-- year_month : GROUP BY in vw_monthly_revenue
-- customer_id: GROUP BY and WHERE filter in all customer-level views
-- country    : GROUP BY in vw_revenue_by_country
CREATE INDEX idx_clean_order_date  ON clean_orders(order_date);
CREATE INDEX idx_clean_year_month  ON clean_orders(`year_month`);
CREATE INDEX idx_clean_customer_id ON clean_orders(customer_id);
CREATE INDEX idx_clean_country     ON clean_orders(country);

-- One index on raw_orders for the returns view and validation
-- subqueries, which still read the unfiltered source table.
CREATE INDEX idx_raw_invoiceno ON raw_orders(invoiceno);


-- ============================================================
-- 3. DATE DIMENSION TABLE
-- A continuous day-level calendar covering the full date range
-- of clean_orders. 
-- ============================================================

DROP TABLE IF EXISTS dim_date;

CREATE TABLE dim_date AS
WITH RECURSIVE calendar(date_val) AS (
    SELECT MIN(order_date) FROM clean_orders
    UNION ALL
    SELECT date_val + INTERVAL 1 DAY
    FROM calendar
    WHERE date_val < (SELECT MAX(order_date) FROM clean_orders)
)
SELECT
    date_val                                                    AS date,
    YEAR(date_val)                                              AS year,
    MONTH(date_val)                                             AS month_num,
    MONTHNAME(date_val)                                         AS month_name,
    DATE_FORMAT(date_val, '%Y-%m')                              AS `year_month`,
    QUARTER(date_val)                                           AS quarter,
    CONCAT('Q', QUARTER(date_val))                              AS quarter_label
FROM calendar;

CREATE INDEX idx_dim_date ON dim_date(date);


-- ============================================================
-- 4. VALIDATION
-- Confirms row counts before and after cleaning. Each bucket
-- is mutually exclusive so the numbers add up to raw total.
-- Run: SELECT * FROM vw_data_quality_summary;
-- ============================================================

DROP VIEW IF EXISTS vw_data_quality_summary;

CREATE VIEW vw_data_quality_summary AS
SELECT
    (SELECT COUNT(*) FROM raw_orders)                           AS raw_rows,
    (SELECT COUNT(*) FROM raw_orders 
     WHERE CAST(unitprice AS DECIMAL(10,2)) <= 0 
        OR CAST(quantity AS SIGNED) = 0
        OR description IS NULL 
        OR TRIM(description) = '')                              AS excluded_bad_data,
    (SELECT COUNT(*) FROM clean_orders)                         AS clean_rows,
    (SELECT COUNT(*) FROM clean_orders WHERE invoiceno LIKE 'C%') AS retained_cancellations,
    ROUND(
        (SELECT COUNT(*) FROM clean_orders) * 100.0
        / (SELECT COUNT(*) FROM raw_orders)
    , 1)                                                        AS pct_retained;


-- ============================================================
-- 5. ANALYSIS VIEWS
-- ============================================================

-- ------------------------------------------------------------
-- 5A. Monthly Revenue Trend
DROP VIEW IF EXISTS vw_monthly_revenue;
CREATE VIEW vw_monthly_revenue AS
WITH monthly AS (
    SELECT
        `year_month`,
        ROUND(SUM(revenue), 2)                              AS total_revenue, -- Naturally nets out
        COUNT(DISTINCT CASE WHEN invoiceno NOT LIKE 'C%' THEN invoiceno END) AS total_orders, -- Purchases only
        ROUND(SUM(revenue) / NULLIF(COUNT(DISTINCT CASE WHEN invoiceno NOT LIKE 'C%' THEN invoiceno END), 0), 2) AS avg_order_value
    FROM clean_orders
    GROUP BY `year_month`
)
SELECT
    `year_month`,
    total_revenue,
    total_orders,
    avg_order_value,
    ROUND(
        (total_revenue - LAG(total_revenue) OVER (ORDER BY `year_month`))
        / NULLIF(LAG(total_revenue) OVER (ORDER BY `year_month`), 0) * 100
    , 1)                                                    AS mom_growth_pct
FROM monthly
ORDER BY `year_month`;

-- 5B. Top 20 Products (Now showing true Net Performance)
DROP VIEW IF EXISTS vw_top_products;
CREATE VIEW vw_top_products AS
SELECT
    stockcode                                               AS stock_code,
    description,
    SUM(quantity)                                           AS total_units_sold, -- Automatically reduced by returns
    COUNT(DISTINCT CASE WHEN invoiceno NOT LIKE 'C%' THEN invoiceno END) AS times_ordered,
    ROUND(SUM(revenue), 2)                                  AS total_revenue
FROM clean_orders
WHERE stockcode NOT IN ('POST', 'DOT', 'M', 'm', 'C2', 'B', 'S', 'AMAZONFEE', 'BANK CHARGES', 'PADS')
  AND stockcode NOT LIKE 'gift_%'
GROUP BY stockcode, description
ORDER BY total_revenue DESC
LIMIT 20;

-- 5C. Top 20 Customers by Spend
DROP VIEW IF EXISTS vw_top_customers;
CREATE VIEW vw_top_customers AS
SELECT
    customer_id,
    COUNT(DISTINCT CASE WHEN invoiceno NOT LIKE 'C%' THEN invoiceno END) AS total_orders,
    SUM(quantity)                                           AS total_items_bought,
    ROUND(SUM(revenue), 2)                                  AS total_spend -- Net spend
FROM clean_orders
WHERE customer_id != 'Guest'
GROUP BY customer_id
ORDER BY total_spend DESC
LIMIT 20;

-- 5D. Revenue by Country
DROP VIEW IF EXISTS vw_revenue_by_country;
CREATE VIEW vw_revenue_by_country AS
SELECT
    country,
    COUNT(DISTINCT CASE WHEN invoiceno NOT LIKE 'C%' THEN invoiceno END) AS total_orders,
    COUNT(DISTINCT customer_id)                             AS unique_customers,
    ROUND(SUM(revenue), 2)                                  AS total_revenue,
    ROUND(SUM(revenue) * 100.0 / (SELECT SUM(revenue) FROM clean_orders), 1) AS revenue_share_pct
FROM clean_orders
GROUP BY country
ORDER BY total_revenue DESC;

-- 5E. One-time vs Repeat Customers
DROP VIEW IF EXISTS vw_customer_segments;
CREATE VIEW vw_customer_segments AS
WITH purchase_counts AS (
    SELECT
        customer_id,
        COUNT(DISTINCT CASE WHEN invoiceno NOT LIKE 'C%' THEN invoiceno END) AS order_count,
        ROUND(SUM(revenue), 2)                              AS total_spend
    FROM clean_orders
    WHERE customer_id != 'Guest'
    GROUP BY customer_id
)
SELECT
    CASE WHEN order_count <= 1 THEN 'One-time buyer' ELSE 'Repeat buyer' END AS segment,
    COUNT(*)                                                AS customer_count,
    ROUND(SUM(total_spend), 2)                              AS total_revenue,
    ROUND(AVG(total_spend), 2)                              AS avg_spend_per_customer,
    ROUND(AVG(order_count), 1)                              AS avg_orders_per_customer
FROM purchase_counts
GROUP BY segment;

-- 5F. RFM Analysis (Recency based on last purchase, Monetary based on net spend)
DROP VIEW IF EXISTS vw_rfm;
CREATE VIEW vw_rfm AS
WITH snapshot AS (
    SELECT MAX(order_date) AS snapshot_date FROM clean_orders
),
customer_metrics AS (
    SELECT
        customer_id,
        MAX(CASE WHEN invoiceno NOT LIKE 'C%' THEN order_date END) AS last_order_date,
        COUNT(DISTINCT CASE WHEN invoiceno NOT LIKE 'C%' THEN invoiceno END) AS frequency,
        ROUND(SUM(revenue), 2)                                     AS monetary
    FROM clean_orders
    WHERE customer_id != 'Guest'
    GROUP BY customer_id
),
rfm_raw AS (
    SELECT
        m.customer_id,
        m.last_order_date,
        DATEDIFF(s.snapshot_date, m.last_order_date)        AS recency_days,
        m.frequency,
        m.monetary
    FROM customer_metrics AS m, snapshot AS s
    WHERE m.last_order_date IS NOT NULL -- Excludes users who only have returns and no base purchases
),
rfm_scored AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_days DESC)          AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)              AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)               AS m_score
    FROM rfm_raw
)
SELECT
    customer_id, last_order_date, recency_days, frequency, monetary,
    r_score, f_score, m_score,
    (r_score + f_score + m_score)                           AS rfm_total,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3                    THEN 'Loyal'
        WHEN r_score >= 4                                    THEN 'Recent'
        WHEN r_score <= 2 AND f_score >= 3                    THEN 'At Risk'
        ELSE                                                      'Inactive'
    END                                                     AS rfm_segment
FROM rfm_scored;

-- 5I. Average Order Value by Month
DROP VIEW IF EXISTS vw_avg_order_value;
CREATE VIEW vw_avg_order_value AS
SELECT
    `year_month`,
    COUNT(DISTINCT CASE WHEN invoiceno NOT LIKE 'C%' THEN invoiceno END) AS total_orders,
    ROUND(SUM(revenue), 2)                                  AS total_revenue,
    ROUND(SUM(revenue) / NULLIF(COUNT(DISTINCT CASE WHEN invoiceno NOT LIKE 'C%' THEN invoiceno END), 0), 2) AS avg_order_value,
    ROUND(SUM(CASE WHEN invoiceno NOT LIKE 'C%' THEN quantity ELSE 0 END) / NULLIF(COUNT(DISTINCT CASE WHEN invoiceno NOT LIKE 'C%' THEN invoiceno END), 0), 1) AS avg_items_per_order
FROM clean_orders
GROUP BY `year_month`
ORDER BY `year_month`;

-- 5J. Product Return Rate (Massively Simplified!)
-- Because sales and returns live in the same clean table, we no longer need complex cross-table joins.
DROP VIEW IF EXISTS vw_product_return_rate;
CREATE VIEW vw_product_return_rate AS
SELECT
    stockcode                                               AS stock_code,
    description,
    SUM(CASE WHEN invoiceno NOT LIKE 'C%' THEN quantity ELSE 0 END) AS units_sold,
    SUM(CASE WHEN invoiceno LIKE 'C%' THEN ABS(quantity) ELSE 0 END) AS units_returned,
    COUNT(DISTINCT CASE WHEN invoiceno NOT LIKE 'C%' THEN invoiceno END) AS times_ordered,
    ROUND(SUM(revenue), 2)                                  AS net_revenue,
    ROUND(
        SUM(CASE WHEN invoiceno LIKE 'C%' THEN ABS(quantity) ELSE 0 END) * 100.0 
        / NULLIF(SUM(CASE WHEN invoiceno NOT LIKE 'C%' THEN quantity ELSE 0 END), 0)
    , 1)                                                    AS return_rate_pct
FROM clean_orders
WHERE stockcode NOT IN ('POST', 'DOT', 'M', 'm', 'C2', 'B', 'S', 'AMAZONFEE', 'BANK CHARGES', 'PADS')
  AND stockcode NOT LIKE 'gift_%'
GROUP BY stockcode, description
HAVING units_sold > 0
ORDER BY return_rate_pct DESC, units_sold DESC;

-- 5K. Basket Size Views
DROP VIEW IF EXISTS vw_basket_size_by_month;
CREATE VIEW vw_basket_size_by_month AS
SELECT
    `year_month`,
    COUNT(DISTINCT CASE WHEN invoiceno NOT LIKE 'C%' THEN invoiceno END) AS total_orders,
    ROUND(SUM(CASE WHEN invoiceno NOT LIKE 'C%' THEN quantity ELSE 0 END) / NULLIF(COUNT(DISTINCT CASE WHEN invoiceno NOT LIKE 'C%' THEN invoiceno END), 0), 1) AS avg_items_per_order,
    ROUND(COUNT(CASE WHEN invoiceno NOT LIKE 'C%' THEN 1 END) / NULLIF(COUNT(DISTINCT CASE WHEN invoiceno NOT LIKE 'C%' THEN invoiceno END), 0), 1) AS avg_lines_per_order,
    ROUND(SUM(revenue) / NULLIF(COUNT(DISTINCT CASE WHEN invoiceno NOT LIKE 'C%' THEN invoiceno END), 0), 2) AS avg_order_value
FROM clean_orders
GROUP BY `year_month`
ORDER BY `year_month`;

DROP VIEW IF EXISTS vw_basket_size_by_country;
CREATE VIEW vw_basket_size_by_country AS
SELECT
    country,
    COUNT(DISTINCT CASE WHEN invoiceno NOT LIKE 'C%' THEN invoiceno END) AS total_orders,
    ROUND(SUM(CASE WHEN invoiceno NOT LIKE 'C%' THEN quantity ELSE 0 END) / NULLIF(COUNT(DISTINCT CASE WHEN invoiceno NOT LIKE 'C%' THEN invoiceno END), 0), 1) AS avg_items_per_order,
    ROUND(COUNT(CASE WHEN invoiceno NOT LIKE 'C%' THEN 1 END) / NULLIF(COUNT(DISTINCT CASE WHEN invoiceno NOT LIKE 'C%' THEN invoiceno END), 0), 1) AS avg_lines_per_order,
    ROUND(SUM(revenue) / NULLIF(COUNT(DISTINCT CASE WHEN invoiceno NOT LIKE 'C%' THEN invoiceno END), 0), 2) AS avg_order_value
FROM clean_orders
GROUP BY country
HAVING total_orders >= 10
ORDER BY avg_order_value DESC;
 
 -- ------------------------------------------------------------
-- 5L. Revenue concentration (Pareto / 80-20 analysis)
--
-- Shows what percentage of total revenue comes from the top
-- X% of customers. The classic 80-20 rule suggests roughly
-- 80% of revenue comes from 20% of customers.
--
-- NTILE(10) splits customers into ten equal groups (deciles)
-- ordered by total spend descending, so decile 1 = top 10%
-- of customers by spend, decile 10 = bottom 10%.
--
-- The cumulative revenue column shows the running total as
-- you add each decile, making it easy to read off "the top
-- 20% of customers (deciles 1-2) account for X% of revenue."
-- ------------------------------------------------------------
DROP VIEW IF EXISTS vw_revenue_concentration;
 
CREATE VIEW vw_revenue_concentration AS
WITH customer_spend AS (
    SELECT
        customer_id,
        ROUND(SUM(revenue), 2)                              AS total_spend
    FROM clean_orders
    WHERE customer_id != 'Guest'
    GROUP BY customer_id
),
deciles AS (
    SELECT
        customer_id,
        total_spend,
        NTILE(10) OVER (ORDER BY total_spend DESC)          AS decile
    FROM customer_spend
),
decile_summary AS (
    SELECT
        decile,
        COUNT(*)                                            AS customers_in_decile,
        ROUND(SUM(total_spend), 2)                          AS decile_revenue
    FROM deciles
    GROUP BY decile
)
SELECT
    decile,
    customers_in_decile,
    decile_revenue,
    ROUND(
        decile_revenue * 100.0
        / (SELECT SUM(total_spend) FROM customer_spend)
    , 1)                                                    AS pct_of_total_revenue,
    ROUND(
        SUM(decile_revenue) OVER (ORDER BY decile)
        * 100.0
        / (SELECT SUM(total_spend) FROM customer_spend)
    , 1)                                                    AS cumulative_revenue_pct
FROM decile_summary
ORDER BY decile;
 
 - ------------------------------------------------------------
-- 5M. Guest vs identified customer revenue by month
--
-- Tracks whether the share of revenue from guest checkouts
-- (no CustomerID) is growing or shrinking over time.
-- ------------------------------------------------------------
DROP VIEW IF EXISTS vw_guest_vs_identified;
 
CREATE VIEW vw_guest_vs_identified AS
SELECT
    `year_month`,
    ROUND(SUM(CASE WHEN customer_id = 'Guest' THEN revenue ELSE 0 END), 2)
                                                            AS guest_revenue,
    ROUND(SUM(CASE WHEN customer_id != 'Guest' THEN revenue ELSE 0 END), 2)
                                                            AS identified_revenue,
    ROUND(SUM(revenue), 2)                                  AS total_revenue,
    ROUND(
        SUM(CASE WHEN customer_id = 'Guest' THEN revenue ELSE 0 END)
        * 100.0 / SUM(revenue)
    , 1)                                                    AS guest_revenue_pct,
    COUNT(DISTINCT CASE WHEN customer_id = 'Guest'
          THEN invoiceno END)                               AS guest_orders,
    COUNT(DISTINCT CASE WHEN customer_id != 'Guest'
          THEN invoiceno END)                               AS identified_orders
FROM clean_orders
GROUP BY `year_month`
ORDER BY `year_month`;
 
 

-- ============================================================
-- 6. SHOWCASE QUERIES
-- Run these interactively in Workbench after the script
-- has built the views above.
-- ============================================================

-- Validation: row counts before and after cleaning
SELECT * FROM vw_data_quality_summary;

-- Full monthly trend with growth rates
SELECT * FROM vw_monthly_revenue;

-- Top 10 products by revenue
SELECT * FROM vw_top_products LIMIT 10;

-- Top 10 customers by spend
SELECT * FROM vw_top_customers LIMIT 10;

-- All countries ranked by revenue
SELECT * FROM vw_revenue_by_country;

-- One-time vs repeat customer split
SELECT * FROM vw_customer_segments;

-- RFM segment summary
SELECT * FROM vw_rfm_summary;

-- Full RFM scores (all customers)
SELECT * FROM vw_rfm;

-- Cancellations by month
SELECT * FROM vw_returns_overview;

-- Average order value and basket size by month
SELECT * FROM vw_avg_order_value;
 
-- Product return rates (top 20 most returned)
SELECT * FROM vw_product_return_rate LIMIT 20;
 
-- Basket size by month
SELECT * FROM vw_basket_size_by_month;
 
-- Basket size by country (min 10 orders)
SELECT * FROM vw_basket_size_by_country;
 
-- Revenue concentration by customer decile
SELECT * FROM vw_revenue_concentration;
 
-- Guest vs identified revenue by month
SELECT * FROM vw_guest_vs_identified;
