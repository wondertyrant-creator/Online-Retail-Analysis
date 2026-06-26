# Online Retail SQL & Power BI Analysis
Built an end-to-end retail analytics solution using MySQL and Power BI to analyse over 540,000 e-commerce transactions from a UK retailer. Designed a complete SQL reporting pipeline with data cleaning, RFM customer segmentation, revenue concentration analysis, and analytical views before developing a three-page interactive dashboard that delivers actionable insights into sales performance, customer behaviour, and product trends.

---

## Tech Stack

| Tool | Purpose |
|---|---|
| MySQL Workbench | Data cleaning, transformation, analysis |
| Power BI Desktop | Interactive dashboard and visualisation |

---

## Dataset

**Source:** https://www.kaggle.com/datasets/carrie1/ecommerce-data/data

**Coverage:** December 2010 – December 2011 (13 months)
**Raw rows:** 541,909 transaction lines
**Columns:** InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country

A real dataset from a UK-based online gift retailer. Each row is a line item on an invoice — one order typically contains multiple rows. The dataset is not included in this repository due to its size. Download it from the link above and place `data.csv` in the project folder before running the script.

---

## Project Structure

```
online-retail-analysis/
│
├── online_retail_analysis.sql    — full MySQL pipeline
├── online_retail_dashboard.pbix  — Power BI dashboard
├── README.md                     — this file
├── INSIGHTS.md                   — detailed business findings and recommendations
├── CODE_EXPLAINED.md             — CTEs and window functions explained line by line
└── DAX_MEASURES.md               — all Power BI DAX measures with usage notes
```

---

## How to Run

### MySQL

1. Open MySQL Workbench and create a schema called `online_retail`
2. Run the `CREATE TABLE raw_orders` block from the script
4. Run the rest of the script — it builds all tables, indexes, and views automatically

### Power BI

1. Open `online_retail_dashboard.pbix` in Power BI Desktop
2. Go to **Home → Transform Data → Data Source Settings**
3. Update the MySQL connection to point to your local server
4. Click **Refresh** — all visuals will update

---

## Data Cleaning Decisions

Every exclusion is documented in the SQL script with inline comments. Summary:

| Decision | Rows Excluded | Reason |
|---|---|---|
| Cancelled invoices (`invoiceno LIKE 'C%'`) | 9,288 | Represent order reversals, not sales |
| Negative or zero quantities | 1,336 | Returns logged without cancellation prefix |
| Zero or invalid unit prices | 43,887 | Includes empty values, samples, and data entry errors — `CAST` to DECIMAL returns 0 for non-numeric entries, all are excluded |
| Null CustomerIDs labelled Guest | 135,080 | Included in revenue totals, excluded from customer-level analysis |
| Non-product stock codes excluded from product views | — | POST, DOT, M, AMAZONFEE etc. are operational charges not products |

**Result:** 487,398 clean rows retained — **89.9%** of the raw dataset.

---

## Analysis Layer

Thirteen SQL views built on `clean_orders`:

| View | What it answers |
|---|---|
| `vw_monthly_revenue` | Revenue and order count with month-on-month growth rate |
| `vw_top_products` | Top 20 products by revenue (excl. non-products) |
| `vw_top_customers` | Top 20 customers by total spend |
| `vw_revenue_by_country` | Revenue, order count, and share by country |
| `vw_customer_segments` | One-time vs repeat buyer revenue split |
| `vw_rfm` | Full RFM scores and segment per identified customer |
| `vw_rfm_summary` | Segment-level totals, averages, and customer counts |
| `vw_returns_overview` | Cancelled order count and value by month |
| `vw_avg_order_value` | AOV and units per order by month |
| `vw_product_return_rate` | Return rate per product by units |
| `vw_basket_size_by_month` | Items and lines per order over time |
| `vw_basket_size_by_country` | Order size comparison across countries |
| `vw_revenue_concentration` | Pareto analysis — revenue share by customer decile |
| `vw_guest_vs_identified` | Guest vs identified revenue and order split by month |

---

## Power BI Dashboard

Three-page interactive dashboard with date, year, and quarter slicers synced across all pages. Visuals built from `clean_orders` respond to slicers; pre-aggregated views display all-time figures.

**Page 1 — Executive Overview**
Total revenue · Total orders · AOV · Unique customers · Monthly revenue and AOV trend · Revenue by country · Guest vs identified split by month · Repeat vs one-time customer donut

**Page 2 — Product Analysis**
Total revenue · Avg lines per order · Avg items per order · Total products · Top products by revenue · Avg items per order by month · Products by units returned

**Page 3 — Customer Analysis**
Repeat customer rate · At risk customers · Cancellation rate · Top 20% revenue share · RFM segment revenue · Revenue concentration by decile · Customers by segment

---

## Key Findings

- **£10.27M** total revenue from **19,812 orders** across 13 months
- **Q4 seasonality** is strong — November 2011 peaked at £1.46M with +31.9% MoM; the Q4 ramp began in September (+38.9%)
- **UK dominates** at 84.6% of revenue; the Netherlands averages **£2,929 per order** vs £518 for the UK — strongly suggesting wholesale accounts
- **Repeat buyers** are 65.4% of identified customers but drive **93% of identified-customer revenue**, spending 7× more on average (£2,802 vs £394)
- **Champions segment** — 980 customers (23%) but **65.2% of identified-customer revenue** at an average of £5,667 per customer
- **Top 20% of customers** account for **75% of total revenue** — the Pareto principle holds strongly
- **526 At Risk customers** averaged 3.7 orders historically but haven't bought in ~4 months — representing £730k in potentially recoverable revenue
- **17.4% cancellation rate** is consistent across months, suggesting structural causes rather than isolated events
- **Average order value: £518** — higher than typical retail, consistent with wholesale buying behaviour (avg 222 units per order)
- **Guest orders** contribute significant monthly revenue but cannot be tracked for retention analysis

Full findings with data tables and recommendations: see [INSIGHTS.md](./INSIGHTS.md)

---

## SQL Techniques Used

- `LOAD DATA INFILE` with `STR_TO_DATE` for date parsing at import time
- `CREATE TABLE ... AS SELECT` to materialise filtered, typed data as a physical table
- `WITH RECURSIVE` CTE for calendar table generation (`INTERVAL 1 DAY`)
- `WITH` (CTE) for multi-step query logic — up to four chained CTEs in `vw_rfm`
- `LAG()` window function for month-on-month growth rate
- `NTILE(5)` window function for RFM scoring relative to full customer base
- `NTILE(10)` window function for revenue concentration decile analysis
- Running `SUM() OVER (ORDER BY ...)` for cumulative Pareto percentage
- `DATEDIFF` for customer recency calculation in days
- `LEFT JOIN` with `COALESCE` for return rate product matching
- Conditional aggregation with `CASE WHEN` inside `SUM` and `COUNT`
- `HAVING` for post-aggregation filtering (minimum order count)
- `CREATE INDEX` on `order_date`, `year_month`, `customer_id`, `country`
- `DATE_FORMAT`, `MONTHNAME`, `QUARTER` for date component extraction
