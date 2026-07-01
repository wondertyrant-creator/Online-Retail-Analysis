# Online Retail SQL & Power BI Analysis

End-to-end analytics project on a real UK e-commerce transaction dataset. A MySQL 8.0 pipeline takes raw, unvalidated invoice-line data through cleaning, star-schema modelling, and thirteen analytical views, feeding a three-page Power BI dashboard covering revenue trends, product performance, and customer/RFM segmentation.

---

## Project Overview

**Business problem.** The source data is a raw export of invoice lines from a UK-based online gift/wholesale retailer — no cleaning, no typed columns, blank customer IDs, and cancellations mixed in with sales. In that state it cannot be trusted for reporting: totals would double-count, exclude, or misrepresent revenue depending on how each analyst happened to filter it.

**Purpose of the analysis.** Build a repeatable, auditable pipeline that turns that raw export into a clean, typed, well-documented dataset, then answer a defined set of recurring business questions from it — consistently, not ad hoc — via a set of SQL views and a Power BI dashboard.

**Questions the dashboard answers:**
- How is revenue trending month to month, and what's the average order value?
- Which products and countries generate the most (net) revenue?
- What share of revenue comes from repeat customers versus one-time buyers, and from guest checkouts versus identified accounts?
- Which customers are most valuable, and how concentrated is revenue among the top few?
- Where does each customer sit on recency, frequency, and monetary value (RFM), and which segment do they fall into?
- Which products get returned most often, and how large is the impact of cancellations by month?

**Intended audience.** Recruiters and hiring managers reviewing SQL and BI capability, and business stakeholders (e.g. sales/ops leads at a similar retailer) who would use the dashboard to monitor revenue health, customer loyalty, and product/return performance.

---

## Dataset

**Source:** UCI Machine Learning Repository — [Online Retail Dataset](https://archive.ics.uci.edu/dataset/352/online+retail).
**Coverage:** December 2010 – December 2011 (13 months; the final month is a partial 9 days).
**Grain:** one row per invoice line item (one order/invoice typically spans several rows).
**Raw columns:** `InvoiceNo`, `StockCode`, `Description`, `Quantity`, `InvoiceDate`, `UnitPrice`, `CustomerID`, `Country`.

### Core tables

| Table | Type | Grain | Notes |
|---|---|---|---|
| `raw_orders` | Table | One row per source CSV line | All columns typed `VARCHAR`/`DATETIME` deliberately, so a single malformed row can't abort the bulk load |
| `clean_orders` | Table (materialised) | One row per valid invoice line | Typed, filtered, and enriched — the single source every view reads from |
| `dim_date` | Table | One row per calendar day | Recursively generated to span the full order-date range, so days with zero sales still exist for reporting |

### Analysis views (built on `clean_orders`)

| View | What it answers |
|---|---|
| `vw_data_quality_summary` | Row counts before/after cleaning, and % retained |
| `vw_monthly_revenue` | Revenue, order count, AOV, and month-on-month growth |
| `vw_top_products` | Top 20 products by net revenue |
| `vw_top_customers` | Top 20 identified customers by net spend |
| `vw_revenue_by_country` | Orders, unique customers, revenue, and revenue share by country |
| `vw_customer_segments` | One-time vs repeat buyer revenue split |
| `vw_rfm` | Recency/Frequency/Monetary scores and segment per identified customer |
| `vw_avg_order_value` | AOV and average items per order, by month |
| `vw_product_return_rate` | Units sold, units returned, net revenue, and return rate per product |
| `vw_basket_size_by_month` | Average items/lines per order and AOV, by month |
| `vw_basket_size_by_country` | Same basket metrics, by country (min. 10 orders) |
| `vw_revenue_concentration` | Pareto/decile analysis — % of revenue by customer decile |
| `vw_guest_vs_identified` | Guest vs identified-customer revenue and order split, by month |

### Star schema layer (built on top of the same `clean_orders` source)

| Object | Grain | Notes |
|---|---|---|
| `vw_fact_orders` | One row per invoice line | Thin pass-through of `clean_orders`, adds an `is_cancellation` flag |
| `vw_dim_customer` | One row per `customer_id` (incl. one `Guest` row) | Carries all-time order count, lifetime revenue, customer type, and full RFM scoring reused from `vw_rfm` |
| `vw_dim_product` | One row per `stock_code` | Picks the single most frequent description per code; flags non-product admin codes via `is_product` |
| `vw_dim_geography` | One row per country | Distinct country list |
| `dim_date` | One row per calendar day | Shared with the analysis-view layer above |

**Relationships (as documented in the script, one-to-many from each dimension into the fact table):**
```
dim_date.date              -> vw_fact_orders.order_date
vw_dim_customer.customer_id -> vw_fact_orders.customer_id
vw_dim_product.stock_code   -> vw_fact_orders.stock_code
vw_dim_geography.country    -> vw_fact_orders.country
```
No other table relationships are declared in the script; none are assumed beyond these four.

---

## Technologies Used

| Tool | Purpose |
|---|---|
| **MySQL 8.0** | Data cleaning, transformation, view layer, and star schema (confirmed by `WITH RECURSIVE`, `NTILE()`, backtick-quoted identifiers, and `LOAD DATA INFILE` syntax) |
| **MySQL Workbench** | Script execution and the initial CSV import step |
| **Power BI Desktop** | Dashboard modelling and visualisation |
| **DAX** | Dashboard measures (e.g. repeat customer rate, cancellation rate, top 20% revenue share) — confirmed by the KPI cards visible on each dashboard page |
| **GitHub** | Version control and portfolio hosting |

> Power Query's role could not be confirmed from the artefacts provided (no M code was supplied) — the transformation logic that can be verified lives entirely in the SQL layer.

---

## Data Preparation

All transformation logic lives in SQL, in `raw_orders` → `clean_orders`:

- **Type conversion.** `quantity` cast to `SIGNED`, `unitprice` cast to `DECIMAL(10,2)` — both loaded as text originally so a single bad row can't fail the whole import.
- **Date parsing.** `InvoiceDate` parsed at import time with `STR_TO_DATE(@dummy_date, '%m/%d/%Y %H:%i')`; `clean_orders` derives both a full timestamp (`invoice_date`) and a date-only join key (`order_date`).
- **Text cleanup.** `TRIM()` applied to `description` and `country` to remove stray whitespace that would otherwise split identical values into duplicates.
- **Row-level filtering.** Rows excluded where `unit_price <= 0`, `quantity = 0`, or `description` is null/blank — 2,521 of 541,909 raw rows (0.5%), confirmed by `vw_data_quality_summary`.
- **Guest bucketing.** Blank/null `CustomerID` mapped to an explicit `'Guest'` label rather than left as `NULL`, so anonymous checkouts can be grouped and filtered intentionally.
- **Derived columns.** `revenue` (quantity × unit price) calculated once in `clean_orders` so every downstream view can simply `SUM(revenue)`; `year_month` derived once for repeated monthly grouping; `is_outlier` flags (but does not filter) any line with `ABS(quantity) > 5000`, left available for optional use in future views.
- **Cancellations retained, not removed.** Invoices beginning with `C` (negative quantity/revenue) are kept in `clean_orders` rather than stripped out. Every downstream `SUM()` therefore nets a sale against its own cancellation automatically. Where a view specifically needs to isolate cancellations (e.g. return rate), it does so via `CASE WHEN invoiceno LIKE 'C%'` at query time, not by filtering the source table.
- **Aggregation patterns used throughout the view layer:** conditional aggregation (`SUM(CASE WHEN ...)`, `COUNT(DISTINCT CASE WHEN ...)`) to separate purchase invoices from cancellation invoices within a single `GROUP BY`; window functions (`LAG`, `NTILE`, `ROW_NUMBER`, running `SUM() OVER`) for growth rates, scoring, and Pareto analysis; `HAVING` for post-aggregation thresholds (e.g. minimum order count per country); `NULLIF(...,0)` guards throughout to prevent division-by-zero.
- **Indexing.** Indexes added on `order_date`, `year_month`, `customer_id`, `country`, and `is_outlier` on `clean_orders`, plus `invoiceno` on `raw_orders`, supporting the filters/joins/group-bys used repeatedly across the view layer.

---

## SQL Architecture

**1. Landing → clean → calendar.** `raw_orders` (untyped landing table) → `clean_orders` (typed, filtered, materialised as a physical table — not a view — so every downstream object queries pre-filtered data without repeating the cleaning logic) → `dim_date` (recursive calendar spanning the order-date range, for gap-free time-series reporting).

**2. Validation.** `vw_data_quality_summary` proves the cleaning step's math: raw row count, excluded row count, clean row count, retained cancellations, and % retained — runnable independently as evidence the cleaning logic behaves as documented.

**3. Reporting views (Section 5 of the script).** Thirteen views, each built directly on `clean_orders`, each answering one specific business question (see the Dataset table above). Several reuse the same conditional-aggregation pattern (`invoiceno NOT LIKE 'C%'` for purchases only) so that "orders" consistently excludes cancellations across every view.

**4. Star schema layer.** A second pass over the same `clean_orders` source, reshaped into one fact view (`vw_fact_orders`) and three dimension views (`vw_dim_customer`, `vw_dim_product`, `vw_dim_geography`), plus the shared `dim_date`. This is the layer actually imported into Power BI — it lets the dashboard build relationships and DAX measures against a conventional star shape instead of querying a different bespoke view per chart. `vw_dim_customer` deliberately reuses `vw_rfm` via a `LEFT JOIN` rather than recalculating recency/frequency/monetary a second time, so the RFM definition exists in exactly one place.

**Data flow summary:**
```
raw_orders  →  clean_orders  →  ┬─→  Section 5 reporting views (13)
                                 │
              dim_date  ────────┤
                                 │
                                 └─→  Star schema: vw_fact_orders + vw_dim_customer /
                                      vw_dim_product / vw_dim_geography  →  Power BI
```

**Design notes worth flagging to a reviewer:**
- `vw_monthly_revenue` and `vw_avg_order_value` compute overlapping figures (`total_orders`, `total_revenue`, `avg_order_value`) from two separate views. This is intentional duplication rather than a bug, and could be consolidated into a single monthly-summary view if desired.
- `is_outlier` (flagging lines with `ABS(quantity) > 5000`) is computed in `clean_orders` but not currently filtered on by any view — it's a flag for optional future use, not dead code.
- `vw_rfm` cannot be dropped even after the star schema replaces the Section 5 views, because `vw_dim_customer` depends on it.

---

## Dashboard Overview

The Power BI dashboard has three pages, each sharing a synced date-range slider plus `quarter` and `year` slicers across the top.

### Page 1 — Executive Overview
**Purpose:** top-line business health at a glance.
**KPI cards:** Total Revenue, Total Orders, Average Order Value, Unique Customers.
**Visuals:**
- *Total Revenue, AOV and MoM Growth % by year_month* — combo line/area chart
- *Sum of revenue by country* — horizontal bar (top countries)
- *Total Revenue by Month for identified and guest* — stacked area, split by `is_guest`
- *Total Revenue by customer type* — donut, Repeat buyer vs One-time buyer
**Slicers/interactions:** date range, quarter, year — all cross-filter every visual on the page.

### Page 2 — Product Analysis
**Purpose:** which products drive revenue, and where returns are concentrated.
**KPI cards:** Total Revenue, Avg Lines per Order, Avg Items per Order, Total Products.
**Visuals:**
- *Total Revenue by description* — top products, filtered to `is_product = 1` (excludes postage/fee/admin codes)
- *Sum of quantity by Month* — units sold trend
- *Units Returned by description* — top returned products by absolute unit volume
**Slicers/interactions:** same date/quarter/year controls as Page 1.

### Page 3 — Customer Analysis
**Purpose:** loyalty, concentration risk, and RFM segmentation.
**KPI cards:** Repeat Customer Rate %, At Risk Customers, Cancellation Rate %, Top 20% Revenue Share.
**Visuals:**
- *Total Revenue by rfm_segment* — horizontal bar
- *Cumulative Revenue % by revenue decile* — line chart (Pareto curve)
- *Count of customer_id by rfm_segment* — donut
- *Total Cancelled Value by Month* — bar chart
**Slicers/interactions:** same date/quarter/year controls as Pages 1–2.

---

## Key Features

- **KPI reporting** — headline metrics (revenue, orders, AOV, customer counts) surfaced as cards on every page
- **Trend analysis** — monthly revenue, AOV, and cancellation trends across the full 13-month window
- **Customer segmentation** — one-time vs repeat buyers, RFM quintile scoring, and revenue-decile concentration
- **Product performance & returns analysis** — net-revenue ranking with a dedicated return-rate view
- **Guest vs identified tracking** — separates anonymous checkouts from account-holder revenue, since guest activity can't be tied to a customer profile
- **Cross-filtering dashboard** — shared date/quarter/year slicers driving all three pages
- **Auditable data cleaning** — a dedicated validation view proves exactly what was excluded and why

---

## Repository Structure

```
online-retail-analysis/
│
├── SQL/
│   └── online_retail_analysis.sql     — full MySQL pipeline (raw → clean → views → star schema)
├── PowerBI/
│   └── online_retail_dashboard.pbix   — three-page dashboard
├── assets/
│   ├── Executive_Overview.png
│   ├── Product_Analysis.png
│   └── Customer_Analysis.png
├── README.md                          — this file
└── insights.md                        — business findings and recommendations
```

---

## Skills Demonstrated

- SQL data cleaning and type coercion from an untyped landing table
- Window functions: `LAG()`, `NTILE()`, `ROW_NUMBER()`, running `SUM() OVER()`
- Recursive CTEs (`WITH RECURSIVE`) for calendar-table generation
- Multi-stage CTE pipelines (up to four chained CTEs in `vw_rfm`)
- Conditional aggregation (`CASE WHEN` inside `SUM`/`COUNT`) to separate purchases from cancellations without extra joins
- View-based analytical layer design, plus a separate star-schema (fact/dimension) layer over the same source
- Index design aligned to actual query filter/join/group-by patterns
- RFM customer segmentation and Pareto/decile revenue concentration analysis
- Power BI dashboard design: multi-page layout, synced slicers, KPI cards
- DAX measure design (repeat customer rate, cancellation rate, top-N revenue share)

---

## Future Improvements

- Consolidate `vw_monthly_revenue` and `vw_avg_order_value` into a single monthly-summary view to remove the current duplication.
- Add a returns/cancellations SQL view (mirroring `vw_guest_vs_identified`'s structure) so the "Total Cancelled Value by Month" chart is backed by an auditable, version-controlled view rather than an in-report DAX calculation only.
- Materialise `vw_dim_customer` as a physical table (with supporting indexes) if the dataset scales meaningfully beyond its current ~540K rows, since it recomputes RFM window functions on every refresh.
- Incorporate a second year of trading data to test whether the September–November revenue ramp observed in this single year is a genuine recurring seasonal pattern.
- Investigate the "Top 20% Revenue Share" dashboard KPI (77.70%) directly in the live `.pbix`. Tracing its exact DAX formula (`DIVIDE(CALCULATE([Total Revenue], revenue_decile <= 2), [Total Revenue])`) against the SQL views and CSV exports — including testing three plausible denominators and re-running the decile split on the RFM-eligible population directly — never reproduces a figure within 4 percentage points of the card's displayed value. The formula itself is legitimate; the specific discrepancy is unresolved and documented in detail in `insights.md`.
- Add a SQL view mirroring the dashboard's DAX-based cancellation measures (`Cancellation Rate %`, monthly cancelled value) so those figures are independently queryable outside Power BI, not just derivable from `vw_fact_orders.is_cancellation` inside a DAX measure.
