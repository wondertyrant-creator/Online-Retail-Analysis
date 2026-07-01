# Business Insights — Online Retail Analysis

Findings below are drawn directly from the SQL view outputs (`vw_*` CSV exports) and the three Power BI dashboard pages. Where a dashboard figure could not be reconciled against a SQL view, that discrepancy is called out explicitly rather than resolved by assumption. December 2011 covers only 9 days of trading and is not directly comparable to other months.

---

## Executive Summary

The business generated **£9,769,872** in net revenue from **19,960 orders** and **4,371 unique identified customers** (plus a Guest bucket) over 13 months (Dec 2010–Dec 2011). Revenue is heavily concentrated: the top 10% of identified customers generate 60.0% of identified-customer revenue, and a 982-customer "Champions" RFM segment alone accounts for 67.7% of it. The UK supplies 84.0% of all revenue, with a handful of very-high-AOV international accounts (Netherlands, Australia, EIRE) standing out as narrow but valuable relationships. Revenue rose sharply from September through November 2011 before the dataset's partial final month — a pattern that cannot be confirmed as seasonal without a second year of data.

---

## KPI Analysis

| KPI | Value | Business Significance |
|---|---|---|
| Total Revenue | £9.77M | Net revenue after cancellations across the 13-month period. |
| Total Orders | 19,960 | Purchase invoices only; cancellations excluded. |
| Average Order Value | £489.47 | Customers spend nearly £500 per order on average — consistent with wholesale, not retail, buying behaviour. |
| Unique Customers | 4,371 | Identified customer accounts, excluding the Guest bucket. |
| Repeat Customer Rate | 65.1% | Most identified customers return, supporting a retention-focused growth strategy. |
| At Risk Customers | 526 | A meaningful group of previously engaged customers has gone quiet and is still recoverable. |
| Guest Revenue | 15.0% | A meaningful share of revenue cannot be tied to individual customers, limiting retention and personalisation efforts. |
| Cancellation Rate | 16.1% | Cancellation activity is significant enough to monitor over time. |
| Top 20% Revenue Share | 77.7% | Revenue is highly concentrated in a small group of top customers — a concentration risk as much as an opportunity. This figure does not reconcile with the SQL layer's own decile calculation (73.8%); see the appendix. |

*Full DAX definitions, formulas, and independent recalculations for every KPI above are in the appendix, for anyone who wants to verify the numbers rather than take them on faith.*

---

## Key Business Insights

**1. Revenue concentration is extreme.** The top decile (438 customers) generates £4,984,121 — 60.0% of identified-customer revenue — while the bottom five deciles (2,185 customers) combine for only 10.8%. This means the business's revenue is disproportionately dependent on a small number of accounts; losing even a handful of top-decile customers would have an outsized impact that broad-based customer counts don't reflect.

**2. Champions drive two-thirds of identified revenue.** The RFM "Champions" segment (982 customers, average 10.9 orders, average £5,730 spend) contributes £5,626,547 — 67.7% of the £8,310,477 in total identified-customer monetary value captured by `vw_rfm`. Losing 10% of this segment alone would represent roughly £563k in lost revenue, more than the entire Loyal, At Risk, and Recent segments combined.

**3. Repeat buyers are the overwhelming majority of value, not volume.** Repeat buyers are 65.1% of identified customers (2,845 of 4,371) but generate 93.8% of identified-customer revenue (£7,789,363 of £8,300,066), spending on average 8.2× more than one-time buyers (£2,738 vs £335). The 1,526 one-time buyers collectively represent only £510,702.

**4. The UK dominates, but a few international accounts carry outsized average order values.** The UK accounts for 84.0% of total revenue (£8,209,930) from 3,950 customers. By contrast, the Netherlands generates £284,662 from just 9 customers at an average order value of £3,028 — over 6× the UK's £455.63 average — and Australia shows a similar pattern (9 customers, £2,405 AOV). EIRE generates £263,277 from only 4 customers, the highest revenue-per-customer concentration of any country. These figures are consistent with a small number of wholesale/trade accounts rather than typical retail buyers, though the transaction data alone cannot confirm account type.

**5. Guest checkouts represent a real but secondary share of revenue.** Guest (no `CustomerID`) transactions total £1,469,806 — 15.0% of all revenue — across 1,610 orders, none of which can be tied to a customer profile for retention or segmentation purposes. Guest share was lowest in September and October (8.7% and 9.0%) — the same months driving the Q4 revenue ramp — and spiked in November (22.5%, £329,349), a divergence from trend worth investigating before drawing conclusions about guest channel behaviour.

**6. Revenue rose sharply into Q4 2011, but this is one observation, not a confirmed trend.** Monthly revenue grew from £704,805 in August to £1,019,688 in September (+44.7%), £1,070,705 in October (+5.0%), and £1,461,756 in November (+36.5%) — the highest month in the dataset. With only 13 months of history and no prior-year data to compare against, this cannot be distinguished from a one-off pattern versus genuine seasonality.


---

## Trend Analysis

**Monthly revenue** was volatile in H1 2011 (month-on-month swings from –27.8% in April to +46.7% in May) before a sustained step-up from September onward. December 2011's –70.3% drop is an artefact of the partial month (9 days only) and should be excluded from any trend read.

**Average order value** ranged from £395.83 (April 2011, the lowest) to £555.08 (September 2011). AOV does not track revenue growth cleanly — November had the highest revenue (£1.46M) but a mid-range AOV (£527.90), meaning the November peak was driven more by order volume (2,769 orders, the highest in the dataset) than by larger individual orders.

**Basket size** (average items per order) was highest in January 2011 (357.1 units/order) despite January being a relatively low-revenue month — consistent with a small number of very large orders skewing the average in a lower-volume month, rather than a broad shift in typical order size.

**No multi-year comparison is possible.** The dataset spans a single 13-month window; any statement describing a pattern as "seasonal" should be read as a hypothesis based on one observed cycle, not a confirmed recurring pattern.

---

## Segment Analysis

### Customer segments (RFM)

| Segment | Customers | Share | Avg Days Since Last Order | Avg Orders | Avg Spend | Total Revenue |
|---|---|---|---|---|---|---|
| Champions | 982 | 22.6% | 12.4 | 10.9 | £5,730 | £5,626,547 |
| Loyal | 1,094 | 25.2% | 33.0 | 3.6 | £1,210 | £1,323,855 |
| At Risk | 526 | 12.1% | 124.9 | 3.8 | £1,308 | £688,089 |
| Inactive | 1,503 | 34.6% | 187.0 | 1.2 | £397 | £596,318 |
| Recent | 233 | 5.4% | 18.2 | 1.0 | £325 | £75,668 |

All figures above were independently recomputed from the `vw_rfm` export and match the dashboard's customer-count donut (Inactive 34.65%, Loyal 25.22%, Champions 22.64%, At Risk 12.13%, Recent 5.37%) and revenue-by-segment bar chart ordering exactly.

**Loyal vs Champions spend gap.** Loyal customers have healthy recency (33 days) and order frequency (3.6 orders) but average only £1,210 in spend — less than a quarter of the £5,730 Champions average. This gap (roughly 4.7×) is the largest unexplained difference in the segmentation and worth investigating: it may reflect a difference in typical order size, product mix, or buyer type (e.g. trade account vs smaller retailer) rather than pure engagement level.

**At Risk represents recoverable value.** 526 customers averaging £1,308 in historical spend haven't ordered in an average of 125 days. Their spend level is close to Loyal customers, suggesting disengagement rather than low intrinsic value — a distinct opportunity from Inactive customers, whose low average spend (£397) and near-single-order frequency (1.2) suggest most never had a strong relationship to begin with.

### Product segments

The top 10 products by net revenue (`vw_top_products`) are led by REGENCY CAKESTAND 3 TIER (£164,762 across 1,988 orders) and WHITE HANGING HEART T-LIGHT HOLDER (£99,668 across 2,256 orders — the most broadly ordered product in the top 10). All top-10 products are decorative home/gift items spread across hundreds to thousands of distinct orders, indicating broad-based rather than single-account-driven demand.

One product — PAPER CRAFT, LITTLE BIRDIE (stock code `23843`) — generated £168,470 in gross line value from a single 80,995-unit order (visible in the raw exploratory query results), but that order was returned in full, netting to £0.00 in `vw_product_return_rate`. It correctly does not appear in the net-revenue-ranked top-10 list, which is the right outcome for product planning: a fully-reversed bulk order represents no realised value to the business.

### Geographic segments

Revenue is bifurcated between broad-based and narrow-but-high-value markets:

- **Broad-based:** UK (3,950 customers, £455.63 AOV), Germany (95 customers), France (88 customers) — closer to a conventional retail/mixed-buyer spread.
- **Narrow, high-value:** Netherlands (9 customers, £3,028 AOV), Australia (9 customers, £2,405 AOV), EIRE (4 customers, £914 AOV) — consistent with a small number of large trade accounts. Losing a single Netherlands or EIRE customer would have a materially larger proportional impact than losing a single UK customer.

---

## Dashboard Interpretation

**Page 1 — Executive Overview.** Start with the four KPI cards for a snapshot, then use the combo chart (Total Revenue vs AOV by month) to check whether a revenue swing is being driven by order volume or order size — the two lines diverge noticeably in H1 2011, confirming volume/size are moving somewhat independently that period. The country bar chart and the guest/identified area chart share the same underlying revenue base, so a spike in one should be checked against the other (e.g. the November guest revenue spike is visible in the area chart but not obviously in the country bar, since Guest activity is spread across countries).

**Page 2 — Product Analysis.** The "Total Revenue by description" bar chart is filtered to `is_product = 1`, so postage, fees, and admin codes are correctly excluded — a business user comparing this to a raw revenue total elsewhere should expect it to be lower for that reason, not treat it as an error. The "Units Returned by description" chart ranks by absolute volume, not return rate — a product can appear here with a high unit count while still having a low return rate relative to its (much larger) sales volume, so this chart should be read alongside the return-rate view rather than in isolation.

**Page 3 — Customer Analysis.** The RFM revenue bar chart and the RFM customer-count donut should be read together: Inactive is the largest segment by customer count (34.65%) but one of the smallest by revenue, while Champions is a mid-sized segment by count (22.64%) but by far the largest by revenue — the visual pairing makes that imbalance immediately clear. The cumulative-revenue-by-decile line chart answers "what % of revenue comes from the top X% of customers" directly off the curve (roughly 74% by decile 2), which reads lower than the "Top 20% Revenue Share" KPI card above it (77.70%) — the two don't fully reconcile (see the KPI Analysis appendix), so treat them as directionally consistent rather than expecting an exact match.

**Filter behaviour.** All three pages share the same date-range slider plus quarter/year slicers. Because December 2011 is only 9 days of data, any filtered view that isolates December in isolation (rather than as part of a full year) will understate that month relative to others — this applies to every page.

---

## Recommendations

| Priority | Recommendation | Evidence | Caveat |
|---|---|---|---|
| High | Protect the Champions segment and understand what drives it | 982 customers = 67.7% of identified-customer revenue; a 10% loss ≈ £563k | RFM scores are relative to this dataset's customer base only, not an absolute benchmark |
| High | Investigate the Loyal-to-Champions spend gap (£1,210 vs £5,730 avg) | Largest unexplained gap in the segmentation; closing it even partially could be high-value | May reflect buyer type rather than engagement — needs context beyond this dataset |
| High | Prioritise outreach to At Risk customers | 526 customers, £688,089 historical spend, avg. 125 days since last order — still plausibly recoverable | Some may have already churned prior to the dataset's start date; recency is only known within this 13-month window |
| Medium | Treat the Netherlands, Australia, and EIRE relationships as strategic accounts | AOV of £3,028 / £2,405 / £914 vs £455.63 for the UK, from very small customer counts (4–9 each) | Account type (wholesale vs retail) cannot be confirmed from transaction data alone |
| Medium | Validate the Sep–Nov revenue ramp against a second year of data before committing to seasonal resourcing | +44.7% (Sep), +36.5% (Nov) MoM growth is compelling but is a single observed cycle | Cannot be distinguished from a one-off pattern without additional years of data |
| Medium | Verify the "Top 20% Revenue Share" KPI (77.70%) against the live Power BI model | Does not reconcile with `vw_revenue_concentration`'s decile 1+2 figure (73.8%) or any denominator/population combination tested against the supplied data | Calculation logic is known and legitimate; only the displayed value couldn't be reproduced from the exports provided |
| Lower | Review the 8 customers with negative net monetary value individually | Combined –£2,818 across `vw_rfm`; small in aggregate but each is a net cost | Sample is small; may reflect legitimate returns, disputes, or data issues — cannot be determined from aggregated figures alone |

---

## Limitations

- **Single year of trading data.** All seasonal or cyclical observations are based on one 13-month window and should be treated as hypotheses, not confirmed patterns.
- **Partial final month.** December 2011 contains only 9 days of activity and is not directly comparable to full months elsewhere in this report.
- **Guest transactions are unattributable.** 15.0% of revenue (£1,469,806) comes from rows where `CustomerID` is already blank or null in the raw source data — not something dropped or excluded by the cleaning/analysis logic, which retains these rows and labels them `'Guest'` explicitly rather than stripping them out. This revenue is included in totals but entirely excluded from customer-level, RFM, and segment analysis. The data confirms the *ID is missing*; it does not reveal *why* (e.g. genuine guest checkout, a POS/export limitation, or something else specific to the source system) — that cause cannot be determined from the artefacts provided.
- **Return-rate denominators are window-bound.** Products purchased before December 2010 but returned within the observation window will show inflated return rates, since only in-window sales are counted as the denominator. This is visible directly in the data (several products exceed 100% return rate) and affects the low-volume tail of `vw_product_return_rate` specifically, not the top-revenue products (which don't appear in that view's current top-20 cut).
- **The "Top 20% Revenue Share" KPI (77.70%) does not reconcile with the SQL views supplied.** The calculation logic is known and legitimate, but the displayed value couldn't be reproduced from the exports provided — see the KPI Analysis section and appendix.
- **Correlation, not causation.** All findings describe patterns present in the data. Explanations offered for *why* those patterns exist (e.g. wholesale buyer behaviour, seasonal demand) are reasonable interpretations, not conclusions the data itself proves.
- **Product return rates should be interpreted with caution.** Several low-volume products show return rates above 100%, because returns recorded during the analysis period can relate to purchases made before the dataset begins. This is a limitation of the observation window rather than evidence of unusually high return behaviour. The highest-revenue products do not appear among the highest-return-rate products, so the return performance of best-selling items would require a separate analysis.
- **A small number of customers have negative net monetary value.** 8 identified customers show negative `monetary` totals in `vw_rfm` (combined –£2,818), meaning their cancellations exceeded their purchases within the observation window. All 8 are scored `m_score = 1` and fall into the Inactive segment. The value involved is small, but each represents a net cost rather than a contribution.
---

## Appendix: KPI Validation Notes

This appendix documents the detailed working behind claims in the main report, for anyone who wants to check the reasoning rather than take it on faith. It's kept separate from the business findings above so the main report stays focused.

### Top 20% Revenue Share — full investigation

DAX: `DIVIDE(CALCULATE([Total Revenue], revenue_decile <= 2), [Total Revenue])`. Dashboard value: 77.70%. `vw_revenue_concentration`'s decile 1+2 cumulative value: 73.8%.

**Hypothesis tested — different ranking population.** `vw_dim_customer.revenue_decile` is assigned via `NTILE(10)` over the 4,338 customers present in `vw_rfm`, while `vw_revenue_concentration` runs its own `NTILE(10)` over the full 4,371-customer identified base (a difference of ~33 customers whose only activity was a cancellation, with no real purchase). Re-running the decile split directly against `vw_rfm.csv`'s `monetary` values (sorted descending, sliced into deciles of 434/433 customers) gives a decile 1+2 cumulative of **73.6%** — within 0.2 points of the SQL view's 73.8%, not the ~4-point gap actually observed. **Ruled out** as the primary cause.

**Denominators tested against the decile 1+2 numerator (≈£6.13M):**

| Denominator | Result |
|---|---|
| Grand total revenue, including Guest (£9,769,872) | 62.7% |
| Identified-customer-only total (£8,300,066) | 73.8–73.9% |
| RFM-eligible-only total (£8,310,477) | 73.8% |

None reproduces 77.70%. Reverse-solving for the numerator that would produce 77.70% against the identified-only denominator implies ≈£6.45M in decile 1+2 revenue — about £320k (45% of decile 3's entire revenue) more than any figure derivable from the supplied data. Too large to attribute to decile-boundary rounding.

**Conclusion:** the calculation logic is transparent and legitimate; the specific 77.70% figure cannot be reproduced from the SQL views, CSV exports, or DAX definitions supplied. The most likely explanation is a page- or visual-level filter active in the live `.pbix` that isn't visible from the measure text alone — a hypothesis, not a confirmed cause.

### Other KPIs independently re-derived

- **Total Revenue** (£9,769,872): `SUM('vw_fact_orders'[revenue])`, no filters. Matches `vw_monthly_revenue`'s summed total exactly.
- **Total Orders** (19,960): `CALCULATE(DISTINCTCOUNT(invoice_no), is_cancellation = 0)`. Matches every SQL view's non-cancellation invoice count exactly.
- **AOV** (£489.47): `DIVIDE([Total Revenue], [Total Orders])` = £9,769,872.05 ÷ 19,960 orders = 489.47. Exact match.
- **Avg Items per Order** (279.98): weighting each month's `avg_items_per_order` from `vw_avg_order_value` by that month's order count gives 279.97. Match within rounding.
- **Unique Customers** (4,371): `CALCULATE(DISTINCTCOUNT(customer_id), is_guest = 0)`. Matches `vw_dim_customer` (4,372 rows total, minus the single Guest row).
- **Repeat Customer Rate** (65.09%): `DISTINCTCOUNT(customer_id, customer_type="Repeat buyer") / DISTINCTCOUNT(customer_id, is_guest=0)` = 2,845 repeat buyers ÷ 4,371 identified customers (`vw_customer_segments`) = 65.09%. Exact match.
- **At Risk Customers** (526): `CALCULATE(DISTINCTCOUNT(customer_id), rfm_segment="At Risk")`. Matches `vw_rfm`'s At Risk count exactly.
- **Guest Revenue %** (15.0%): `[Guest Revenue] / [Total Revenue]` = £1,469,806 ÷ £9,769,872.05 (`vw_guest_vs_identified`, summed) = 15.04%. Exact match.
- **RFM segment revenue/counts**: independently recomputed from `vw_rfm.csv` and matched the dashboard's revenue-by-segment bar chart and customer-count donut exactly.
- **Cancellation Rate** (16.12%): `DIVIDE([Cancelled Orders], [Cancelled Orders] + [Total Orders])`, both counting distinct invoices off `vw_fact_orders.is_cancellation`. Implies ≈3,836 cancelled invoices, consistent with the 9,288 cancellation line items in `clean_orders` (≈2.4 lines per cancelled invoice, versus ≈26 lines on a typical purchase order).
