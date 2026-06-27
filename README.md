
# Online Retail SQL & Power BI Analysis

End-to-end data analysis project using a real e-commerce dataset. Built a MySQL analytics pipeline from raw data to a three-page Power BI dashboard, covering data cleaning, RFM customer segmentation, product performance, and revenue concentration analysis.

---

## Tech Stack

| Tool | Purpose |
|---|---|
| MySQL 8.0 | Data cleaning, transformation, and analysis |
| MySQL Workbench | Query development and execution |
| Power BI Desktop | Interactive dashboard and visualisation |

---

## Dataset

**Source:** UCI Online Retail Dataset — publicly available at the [UCI Machine Learning Repository](https://archive.ics.uci.edu/dataset/352/online+retail)

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
├── SQL_CODE.md                   — every SQL section explained line by line
└── DAX_MEASURES.md               — all Power BI DAX measures with usage notes
```

---

## How to Run

### MySQL

1. Open MySQL Workbench and create a schema called `online_retail`
2. Run the `CREATE TABLE raw_orders` block from the script
3. Right-click `raw_orders` → **Table Data Import Wizard** → select `data.csv` → Finish
4. Run the rest of the script — it builds all tables, indexes, and views automatically

### Power BI

1. Open `online_retail_dashboard.pbix` in Power BI Desktop
2. Go to **Home → Transform Data → Data Source Settings**
3. Update the MySQL connection to point to your local server
4. Click **Refresh** — all visuals will update

---

## Data Cleaning Decisions

Every exclusion is documented in the SQL script with inline comments.

| Decision | Rows Affected | Reason |
|---|---|---|
| Truly invalid rows excluded at table level | 2,521 | Blank or non-parseable fields |
| Cancellation invoices retained but tracked | 9,288 | Kept in `clean_orders`, filtered at view level so each view's logic is explicit |
| Null CustomerIDs labelled Guest | ~135,000 | Included in revenue totals, excluded from customer-level analysis |
| Non-product stock codes excluded from product views | — | POST, DOT, M, AMAZONFEE etc. are charges not products |
| Net revenue used for product and customer ranking | — | Gross revenue from transactions later reversed by returns misrepresents performance |

**Result:** 539,388 clean rows retained — **99.5%** of the raw dataset.

Keeping cancellations in `clean_orders` rather than excluding them at the table level is a deliberate choice. It means each view decides what to filter, making the business logic visible and auditable in one place rather than hidden inside the cleaning step.

---

## Analysis Layer

Thirteen SQL views built on `clean_orders`:

| View | What it answers |
|---|---|
| `vw_monthly_revenue` | Revenue and order count with month-on-month growth rate |
| `vw_top_products` | Top 20 products by net revenue (excl. non-products) |
| `vw_top_customers` | Top 20 customers by net spend |
| `vw_revenue_by_country` | Revenue, order count, and share by country |
| `vw_customer_segments` | One-time vs repeat buyer revenue split |
| `vw_rfm` | Full RFM scores and segment per identified customer |
| `vw_rfm_summary` | Segment-level totals, averages, and customer counts |
| `vw_returns_overview` | Cancelled order count and value by month |
| `vw_avg_order_value` | AOV and units per order by month |
| `vw_product_return_rate` | Net revenue and return rate per product |
| `vw_basket_size_by_month` | Items and lines per order over time |
| `vw_basket_size_by_country` | Order size comparison across countries |
| `vw_revenue_concentration` | Pareto analysis — revenue share by customer decile |
| `vw_guest_vs_identified` | Guest vs identified revenue and order split by month |

---

## Power BI Dashboard

Three-page interactive dashboard with date, year, and quarter slicers synced across all pages. Visuals built from `clean_orders` respond to slicers; pre-aggregated views display all-time figures.

**Page 1 — Executive Overview**
Total revenue · Total orders · AOV · Unique customers · Monthly revenue and AOV trend · Revenue by country · Guest vs identified split · Repeat vs one-time customer donut

**Page 2 — Product Analysis**
Total revenue · Avg lines per order · Avg items per order · Total products · Top products by net revenue · Avg items per order by month · Products by return rate

**Page 3 — Customer Analysis**
Repeat customer rate · At risk customers · Cancellation rate · Top 20% revenue share · RFM segment revenue · Revenue concentration by decile · Customers by segment

---

## Key Findings

- **£9.77M** total revenue from **19,960 orders** across 13 months
- **Product ranking uses net revenue** — one product (PAPER CRAFT, LITTLE BIRDIE) generated £168k gross from a single bulk order but was almost entirely returned, correctly dropping it from the top products list
- **Return rates for top products are 1.5%–6.8%** — healthy and consistent with a functioning wholesale operation
- **Q4 revenue ramp is pronounced in this dataset** — November peaked at £1.46M (+36.5% MoM) after a September surge of +44.7%. With one year of data, this cannot be confirmed as a recurring annual pattern
- **UK dominates** at 84.0% of revenue; the Netherlands averages **£3,028 per order** vs £455 for the UK — consistent with wholesale accounts
- **Repeat buyers** are 65.1% of identified customers but drive **93.8% of revenue**, spending 8.2× more on average (£2,738 vs £335)
- **Champions segment** — 982 customers (22.7%) generate **67.7% of identified-customer revenue** at an average of £5,730 each
- **Top 20% of customers account for 73.8% of revenue** — highly concentrated, creating concentration risk
- **526 At Risk customers** averaged 3.8 orders but haven't bought in ~4 months — £688k of spend that has gone quiet
- **Some customers show negative net revenue** — a small number returned more than they purchased within the observation window, visible in the RFM analysis

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

---

## DAX Techniques Used

- `SUM`, `DISTINCTCOUNT`, `COUNTROWS` for aggregation across filtered contexts
- `CALCULATE` to modify filter context — used in every segment and RFM measure
- `DIVIDE` for safe division that returns blank rather than an error on zero denominators
- `FILTER` with `VALUES` for row-level conditions within an aggregation
- `VAR ... RETURN` to store intermediate results and keep complex measures readable
- `DATEADD` for time intelligence — shifting context back one month for MoM growth
- `ALL` to remove filter context for percentage-of-total calculations
- `FORMAT` to output numbers as formatted percentage strings
- `AND` function for combining multiple conditions inside `FILTER`
- Conditional measures using `CALCULATE` with inline filter arguments
- `_Measures` table to centralise all measures separate from data tables
