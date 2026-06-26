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
    country     VARCHAR(100)STOP HERE AND IMPORT data.csv BEFORE CONTINUING
-- Right-click raw_orders in the left panel
-- → Table Data Import Wizard → select data.csv → Finish
-- Then continue running the rest of this script
);

-- ============================================================
-- DATA IMPORT VIA AUTOMATED SCRIPT
-- Bypasses the Import Wizard limitations.
-- Parses dates into standard SQL format dynamically on ingestion.
-- ============================================================
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data.csv' 
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
WHERE invoiceno NOT LIKE 'C%'           -- exclude cancellations 
  AND CAST(quantity AS SIGNED) > 0      -- exclude returns        
  AND CAST(unitprice AS DECIMAL) > 0;   -- exclude free/errors    

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
     WHERE invoiceno LIKE 'C%')                                 AS excluded_cancellations,
    (SELECT COUNT(*) FROM raw_orders
     WHERE invoiceno NOT LIKE 'C%'
       AND CAST(quantity AS SIGNED) <= 0)                       AS excluded_neg_quantity,
    (SELECT COUNT(*) FROM raw_orders
     WHERE invoiceno NOT LIKE 'C%'
       AND CAST(quantity AS SIGNED) > 0
       AND CAST(unitprice AS DECIMAL) <= 0)                     AS excluded_bad_price,
    (SELECT COUNT(*) FROM clean_orders)                         AS clean_rows,
    ROUND(
        (SELECT COUNT(*) FROM clean_orders) * 100.0
        / (SELECT COUNT(*) FROM raw_orders)
    , 1)                                                        AS pct_retained;


-- ============================================================
-- 5. ANALYSIS VIEWS
-- ============================================================

-- ------------------------------------------------------------
-- 5A. Monthly revenue trend
--
-- Revenue, order count, and average order value per month.
-- LAG() retrieves the previous month's revenue so growth rate
-- can be calculated without a self-join. The CTE separates
-- aggregation from the growth rate calculation.
-- ------------------------------------------------------------
DROP VIEW IF EXISTS vw_monthly_revenue;

CREATE VIEW vw_monthly_revenue AS
WITH monthly AS (
    SELECT
        `year_month`,
        ROUND(SUM(revenue), 2)                              AS total_revenue,
        COUNT(DISTINCT invoiceno)                           AS total_orders,
        ROUND(SUM(revenue) / COUNT(DISTINCT invoiceno), 2)  AS avg_order_value
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
        / LAG(total_revenue) OVER (ORDER BY `year_month`) * 100
    , 1)                                                    AS mom_growth_pct
FROM monthly
ORDER BY `year_month`;


-- ------------------------------------------------------------
-- 5B. Top 20 products by revenue
--
-- Postage, manual adjustments, and gift vouchers excluded.
-- See README: Decision 5.
-- ------------------------------------------------------------
DROP VIEW IF EXISTS vw_top_products;

CREATE VIEW vw_top_products AS
SELECT
    stockcode                                               AS stock_code,
    description,
    SUM(quantity)                                           AS total_units_sold,
    COUNT(DISTINCT invoiceno)                               AS times_ordered,
    ROUND(SUM(revenue), 2)                                  AS total_revenue
FROM clean_orders
WHERE stockcode NOT IN (
        'POST', 'DOT', 'M', 'm', 'C2',
        'B', 'S', 'AMAZONFEE', 'BANK CHARGES', 'PADS'
      )
  AND stockcode NOT LIKE 'gift_%'
GROUP BY stockcode, description
ORDER BY total_revenue DESC
LIMIT 20;


-- ------------------------------------------------------------
-- 5C. Top 20 customers by spend
--
-- Guest orders excluded — no stable ID to link purchases.
-- ------------------------------------------------------------
DROP VIEW IF EXISTS vw_top_customers;

CREATE VIEW vw_top_customers AS
SELECT
    customer_id,
    COUNT(DISTINCT invoiceno)                               AS total_orders,
    SUM(quantity)                                           AS total_items_bought,
    ROUND(SUM(revenue), 2)                                  AS total_spend
FROM clean_orders
WHERE customer_id != 'Guest'
GROUP BY customer_id
ORDER BY total_spend DESC
LIMIT 20;


-- ------------------------------------------------------------
-- 5D. Revenue by country
-- ------------------------------------------------------------
DROP VIEW IF EXISTS vw_revenue_by_country;

CREATE VIEW vw_revenue_by_country AS
SELECT
    country,
    COUNT(DISTINCT invoiceno)                               AS total_orders,
    COUNT(DISTINCT customer_id)                             AS unique_customers,
    ROUND(SUM(revenue), 2)                                  AS total_revenue,
    ROUND(
        SUM(revenue) * 100.0
        / (SELECT SUM(revenue) FROM clean_orders)
    , 1)                                                    AS revenue_share_pct
FROM clean_orders
GROUP BY country
ORDER BY total_revenue DESC;


-- ------------------------------------------------------------
-- 5E. One-time vs repeat customers
-- ------------------------------------------------------------
DROP VIEW IF EXISTS vw_customer_segments;

CREATE VIEW vw_customer_segments AS
WITH purchase_counts AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoiceno)                           AS order_count,
        ROUND(SUM(revenue), 2)                              AS total_spend
    FROM clean_orders
    WHERE customer_id != 'Guest'
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN order_count = 1 THEN 'One-time buyer'
        ELSE 'Repeat buyer'
    END                                                     AS segment,
    COUNT(*)                                                AS customer_count,
    ROUND(SUM(total_spend), 2)                              AS total_revenue,
    ROUND(AVG(total_spend), 2)                              AS avg_spend_per_customer,
    ROUND(AVG(order_count), 1)                              AS avg_orders_per_customer
FROM purchase_counts
GROUP BY segment;


-- ------------------------------------------------------------
-- 5F. RFM analysis — individual customer scores and segments
--
-- Scores each customer 1-5 on Recency, Frequency, Monetary
-- using NTILE(5) relative to the full customer base.
--
-- DATEDIFF(snapshot_date, last_order_date) returns the number
-- of days between two dates.
-- ------------------------------------------------------------
DROP VIEW IF EXISTS vw_rfm;

CREATE VIEW vw_rfm AS
WITH snapshot AS (
    SELECT MAX(order_date) AS snapshot_date
    FROM clean_orders
),
customer_metrics AS (
    SELECT
        customer_id,
        MAX(order_date)                                     AS last_order_date,
        COUNT(DISTINCT invoiceno)                           AS frequency,
        ROUND(SUM(revenue), 2)                              AS monetary
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
),
rfm_scored AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_days DESC)          AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)              AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)               AS m_score
    FROM rfm_raw
)
SELECT
    customer_id,
    last_order_date,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    r_score + f_score + m_score                             AS rfm_total,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3                   THEN 'Loyal'
        WHEN r_score >= 4                                    THEN 'Recent'
        WHEN r_score <= 2 AND f_score >= 3                   THEN 'At Risk'
        ELSE                                                      'Inactive'
    END                                                     AS rfm_segment
FROM rfm_scored
ORDER BY rfm_total DESC, customer_id;


-- ------------------------------------------------------------
-- 5G. RFM segment summary
-- ------------------------------------------------------------
DROP VIEW IF EXISTS vw_rfm_summary;

CREATE VIEW vw_rfm_summary AS
SELECT
    rfm_segment,
    COUNT(*)                                                AS customer_count,
    ROUND(AVG(recency_days))                                AS avg_recency_days,
    ROUND(AVG(frequency), 1)                                AS avg_orders,
    ROUND(AVG(monetary), 0)                                 AS avg_spend,
    ROUND(SUM(monetary), 0)                                 AS total_revenue
FROM vw_rfm
GROUP BY rfm_segment
ORDER BY total_revenue DESC;


-- ------------------------------------------------------------
-- 5H. Returns overview by month
--
-- Queries raw_orders directly so cancellations are visible.
-- ABS() presents values as positive figures for clean trend analysis.
-- ------------------------------------------------------------
DROP VIEW IF EXISTS vw_returns_overview;

CREATE VIEW vw_returns_overview AS
SELECT
    DATE_FORMAT(invoicedate, '%Y-%m') AS `year_month`,
    COUNT(DISTINCT invoiceno)                               AS cancelled_orders,
    ABS(ROUND(SUM(
        CAST(quantity AS DECIMAL(10,2))
        * CAST(unitprice AS DECIMAL(10,2))
    ), 2))                                                  AS cancelled_value
FROM raw_orders
WHERE invoiceno LIKE 'C%'
  AND CAST(unitprice AS DECIMAL) > 0
GROUP BY `year_month`
ORDER BY `year_month`;

-- ------------------------------------------------------------
-- 5I. Average order value by month
--
-- Tracks how much each order is worth on average over time.
-- AOV = total revenue / number of distinct orders per month.
-- Separating this from vw_monthly_revenue makes it easier to
-- spot months where revenue grew because of more orders versus
-- months where it grew because each order was worth more —
-- two very different commercial situations.
-- ------------------------------------------------------------
DROP VIEW IF EXISTS vw_avg_order_value;
 
CREATE VIEW vw_avg_order_value AS
SELECT
    `year_month`,
    COUNT(DISTINCT invoiceno)                               AS total_orders,
    ROUND(SUM(revenue), 2)                                  AS total_revenue,
    ROUND(SUM(revenue) / COUNT(DISTINCT invoiceno), 2)      AS avg_order_value,
    ROUND(SUM(quantity) / COUNT(DISTINCT invoiceno), 1)     AS avg_items_per_order
FROM clean_orders
GROUP BY `year_month`
ORDER BY `year_month`;
 
 -- -----------------------------------------------------------
-- 5J. Product return rate
--
-- Joins cancelled invoices back to their original invoices to
-- find which products are returned most often. A C-prefixed
-- invoice (e.g. C536379) corresponds to the original invoice
-- with the same number minus the C (536379). Matching on both
-- stockcode and the numeric part of invoiceno links each
-- cancellation to the product that was returned.
--
-- return_rate is cancelled quantity as a percentage of total
-- sold quantity for each product. Only products with at least
-- 10 sales are included to avoid noise from rare items.
-- ------------------------------------------------------------
DROP VIEW IF EXISTS vw_product_return_rate;
 
CREATE VIEW vw_product_return_rate AS
WITH sales AS (
    SELECT
        stockcode,
        description,
        SUM(quantity)                                       AS units_sold,
        COUNT(DISTINCT invoiceno)                           AS times_ordered,
        ROUND(SUM(revenue), 2)                              AS total_revenue
    FROM clean_orders
    WHERE stockcode NOT IN (
            'POST', 'DOT', 'M', 'm', 'C2',
            'B', 'S', 'AMAZONFEE', 'BANK CHARGES', 'PADS'
          )
      AND stockcode NOT LIKE 'gift_%'
    GROUP BY stockcode, description
),
returns AS (
    SELECT
        stockcode,
        ABS(SUM(CAST(quantity AS SIGNED)))                  AS units_returned
    FROM raw_orders
    WHERE invoiceno LIKE 'C%'
      AND CAST(unitprice AS DECIMAL) > 0
      AND CAST(quantity AS SIGNED) < 0
    GROUP BY stockcode
)
SELECT
    s.stockcode,
    s.description,
    s.units_sold,
    COALESCE(r.units_returned, 0)                           AS units_returned,
    s.times_ordered,
    s.total_revenue,
    ROUND(
        COALESCE(r.units_returned, 0) * 100.0 / s.units_sold
    , 1)                                                    AS return_rate_pct
FROM sales AS s
LEFT JOIN returns AS r ON r.stockcode = s.stockcode
WHERE s.units_sold >= 10
ORDER BY return_rate_pct DESC, s.units_sold DESC;
 
 -- ------------------------------------------------------------
-- 5K. Basket size by month and country
--
-- Basket size = number of distinct products per order.
-- A growing basket size means customers are buying more
-- product lines per visit, which increases revenue without
-- needing more orders or customers.
--
-- by month (to spot trends) and by country
-- ------------------------------------------------------------
DROP VIEW IF EXISTS vw_basket_size_by_month;
 
CREATE VIEW vw_basket_size_by_month AS
SELECT
    `year_month`,
    COUNT(DISTINCT invoiceno)                               AS total_orders,
    ROUND(SUM(quantity) / COUNT(DISTINCT invoiceno), 1)     AS avg_items_per_order,
    ROUND(COUNT(*) / COUNT(DISTINCT invoiceno), 1)          AS avg_lines_per_order,
    ROUND(SUM(revenue) / COUNT(DISTINCT invoiceno), 2)      AS avg_order_value
FROM clean_orders
GROUP BY `year_month`
ORDER BY `year_month`;
 
DROP VIEW IF EXISTS vw_basket_size_by_country;
 
CREATE VIEW vw_basket_size_by_country AS
SELECT
    country,
    COUNT(DISTINCT invoiceno)                               AS total_orders,
    ROUND(SUM(quantity) / COUNT(DISTINCT invoiceno), 1)     AS avg_items_per_order,
    ROUND(COUNT(*) / COUNT(DISTINCT invoiceno), 1)          AS avg_lines_per_order,
    ROUND(SUM(revenue) / COUNT(DISTINCT invoiceno), 2)      AS avg_order_value
FROM clean_orders
GROUP BY country
HAVING COUNT(DISTINCT invoiceno) >= 10
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