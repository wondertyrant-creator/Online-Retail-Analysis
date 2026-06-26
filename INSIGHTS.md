# Business Insights — Online Retail Analysis

Analysis of UCI Online Retail dataset covering December 2010 – December 2011.
All figures are derived from the SQL views built on the cleaned dataset (487,398 rows).

Revenue is highly concentrated: the top 20% of identified customers generate 75% of sales, while Champion customers alone contribute 65% of identified-customer revenue. Revenue increased sharply from September to November 2011, although only one annual cycle is available, preventing confirmation of seasonal patterns. Several international markets, particularly the Netherlands, Australia, and EIRE, exhibit exceptionally high average order values, suggesting a small number of high-value accounts. Finally, approximately 16.5% of revenue is associated with guest customers, limiting customer retention analysis and highlighting an opportunity to improve customer identification.

---

## Limitations

Being transparent about what the data can and cannot support strengthens the credibility of any finding that follows.

**One year of data:** The dataset covers just over 13 months — from December 2010 to 9 December 2011. Any pattern described as seasonal or recurring (such as the Q4 revenue ramp) is observed within a single annual cycle. Additional years of data would be needed to confirm whether these patterns repeat consistently.

**Partial December 2011:** The dataset ends on 9 December 2011, meaning December figures represent only 9 days of trading. December revenue, AOV, and cancellation numbers should not be compared directly to other months.

**Wholesale rather than retail:** The customer base appears to be primarily wholesale or trade buyers rather than end consumers. Average order values (£518), average units per order (222), and country-level AOV figures (Netherlands: £2,929) are all consistent with bulk buying behaviour. Retail benchmarks — typical AOV around £30–60, typical basket of 2–4 items — do not apply here.

**Guest customers limit retention tracking:** Approximately 25% of raw rows have no CustomerID. These are included in revenue totals but excluded from all customer-level analysis (RFM, repeat rate, top customers). A significant portion of buying behaviour is therefore unobservable.

**Return rates can exceed 100% by units:** The product return rate analysis compares returns within the 13-month window against sales within the same window. If a product was purchased before December 2010 and returned within the window, units returned will exceed visible units sold — producing rates above 100%. These are flagged as "Review" and should be investigated with domain knowledge rather than treated as data errors.

**Correlation vs causation:** Findings describe patterns in the data. Explanations for why those patterns exist (e.g. Netherlands buyers being wholesale accounts) are reasonable inferences but are not confirmed by the data itself.

---

## Summary Numbers

| Metric | Value |
|---|---|
| Total Revenue | £10,265,739 |
| Total Orders | 19,812 |
| Average Order Value | £518 |
| Average Units per Order | 222 |
| Unique Customers (incl. Guest) | 4,328 |
| Identified Customers | 4,328 |
| Countries | 38 |
| Products Analysed | 3,658 |
| Date Range | Dec 2010 – Dec 2011 |
| Raw Rows | 541,909 |
| Clean Rows Retained | 487,398 (89.9%) |

---

## Data Quality

| Exclusion | Rows | Reason |
|---|---|---|
| Cancelled invoices (`C%` prefix) | 9,288 | Order reversals, not sales |
| Negative quantities | 1,336 | Returns logged without cancellation prefix |
| Zero or invalid unit prices | 43,887 | Includes empty values — MySQL CAST returns 0 for non-numeric entries |
| **Total excluded** | **54,511** | |
| **Clean rows retained** | **487,398** | **89.9%** |

The `excluded_bad_price` count of 43,887 is higher than a simple count of zero-price rows because MySQL's `CAST` function returns 0 for empty strings and non-numeric values — all of which are correctly excluded from analysis.

---

## Dashboard — Executive Overview

![Executive Overview](Executive_Overview.png)

---

## 1. Revenue Trend

**View:** `vw_monthly_revenue`

| Month | Revenue | Orders | AOV | MoM Growth |
|---|---|---|---|---|
| 2010-12 | £802,002 | 1,548 | £518 | — |
| 2011-01 | £669,415 | 1,081 | £619 | -16.5% |
| 2011-02 | £504,894 | 1,087 | £464 | -24.6% |
| 2011-03 | £691,548 | 1,447 | £478 | +37.0% |
| 2011-04 | £508,542 | 1,236 | £411 | -26.5% |
| 2011-05 | £744,006 | 1,668 | £446 | +46.3% |
| 2011-06 | £733,758 | 1,519 | £483 | -1.4% |
| 2011-07 | £684,986 | 1,462 | £469 | -6.6% |
| 2011-08 | £730,257 | 1,348 | £542 | +6.6% |
| 2011-09 | £1,014,569 | 1,821 | £557 | +38.9% |
| 2011-10 | £1,104,056 | 2,029 | £544 | +8.8% |
| 2011-11 | £1,455,751 | 2,747 | £530 | +31.9% |
| 2011-12 | £621,955 | 819 | £759 | -57.3% (partial month) |

**Findings:**
- Revenue was volatile in H1 2011, ranging from £505k to £744k with no consistent direction
- Revenue increased sharply from September 2011 onwards — September +38.9%, October +8.8%, November +31.9%
- November 2011 was the highest month at £1.46M — nearly 3× February
- The December drop (-57.3%) is a data boundary effect, not a business signal. December 2011 has only 9 days of data

**Caveat on seasonality:** The September–November ramp is a notable pattern within this dataset. However, with only one year of data it is not possible to confirm that this recurs annually. If this were a live business, the appropriate next step would be to request the prior year's data before drawing conclusions about seasonal planning cycles.

---

## 2. Product Performance

**View:** `vw_top_products`

**Top 10 products by revenue:**

| Product | Units Sold | Orders | Revenue |
|---|---|---|---|
| REGENCY CAKESTAND 3 TIER | 13,879 | 1,988 | £174,485 |
| PAPER CRAFT, LITTLE BIRDIE | 80,995 | 1 | £168,470 |
| WHITE HANGING HEART T-LIGHT HOLDER | 37,891 | 2,256 | £106,293 |
| PARTY BUNTING | 18,295 | 1,685 | £99,504 |
| JUMBO BAG RED RETROSPOT | 48,474 | 2,089 | £94,340 |
| MEDIUM CERAMIC TOP STORAGE JAR | 78,033 | 247 | £81,701 |
| RABBIT NIGHT LIGHT | 30,788 | 994 | £66,965 |
| PAPER CHAIN KIT 50'S CHRISTMAS | 19,355 | 1,160 | £64,952 |
| ASSORTED COLOUR BIRD ORNAMENT | 36,461 | 1,455 | £59,095 |
| CHILLI LIGHTS | 10,306 | 661 | £54,118 |

**Findings:**
- PAPER CRAFT, LITTLE BIRDIE generated £168k from a single order — one customer (16446) bought 80,995 units. This is an outlier, not a measure of consistent product demand
- MEDIUM CERAMIC TOP STORAGE JAR sold 78,033 units across only 247 orders — another bulk buying pattern
- REGENCY CAKESTAND spread similar revenue across 1,988 distinct orders — a more reliable signal of consistent demand
- WHITE HANGING HEART T-LIGHT HOLDER appeared in 2,256 orders — the most broadly purchased product in the top 10

---

## Dashboard — Product Analysis

![Product Analysis](Product_Analysis.png)

---

## 3. Product Return Rate

**View:** `vw_product_return_rate`

| Product | Units Sold | Units Returned | Return Rate | Flag |
|---|---|---|---|---|
| CREAM HANGING HEART T-LIGHT HOLDER | 61 | 2,578 | 4,226% | Review |
| SET OF 36 VINTAGE CHRISTMAS DOILIES | 38 | 325 | 855% | Review |
| GEMSTONE CHANDELIER T-LIGHT HOLDER | 78 | 433 | 555% | Review |
| ENAMEL BOWL PANTRY | 24 | 121 | 504% | Review |
| GIN AND TONIC DIET METAL SIGN | 498 | 2,030 | 408% | Review |

**Note on rates above 100%:** As described in the Limitations section, these occur when returns span purchase periods outside the dataset window. These rows are flagged "Review" and should be investigated with product and operations knowledge before drawing conclusions.

**Findings:**
- PAPER CRAFT, LITTLE BIRDIE and MEDIUM CERAMIC TOP STORAGE JAR both show near-complete revenue reversal through returns. One possible explanation is a defective batch or product recall — but this cannot be confirmed from the transaction data alone
- A small number of products account for a disproportionate share of return volume

---

## 4. Average Order Value and Basket Size

**View:** `vw_avg_order_value`, `vw_basket_size_by_country`

| Metric | Value |
|---|---|
| Overall AOV | £518 |
| Avg units per order | 222 |
| Avg lines per order | 24.6 |

**Context:** These metrics are significantly higher than retail norms (typically £30–60 AOV, 2–4 items). This reflects wholesale buying behaviour — individual orders regularly involve hundreds or thousands of units. These numbers should be interpreted in that context rather than benchmarked against retail industry averages.

**Basket size by country (top 5 by AOV):**

| Country | Orders | Avg Units/Order | AOV |
|---|---|---|---|
| Netherlands | 93 | 1,782 | £2,929 |
| Australia | 57 | 1,191 | £2,331 |
| Japan | 19 | 938 | £1,819 |
| Hong Kong | 11 | 391 | £1,412 |
| United Kingdom | 17,873 | ~217 | £518 |

**Findings:**
- The Netherlands generates £2,929 per order on average — 5.6× the UK average — across only 93 orders and 9 customers. This pattern is consistent with wholesale or trade accounts rather than retail buyers, though this cannot be confirmed without additional customer data
- Australia and Japan show a similar pattern at a smaller scale

---

## 5. Geographic Revenue

**View:** `vw_revenue_by_country`

| Country | Orders | Customers | Revenue | Share |
|---|---|---|---|---|
| United Kingdom | 17,873 | 3,911 | £8,688,635 | 84.6% |
| EIRE | 288 | 4 | £272,682 | 2.7% |
| Netherlands | 93 | 9 | £272,411 | 2.7% |
| Germany | 457 | 94 | £221,333 | 2.2% |
| France | 391 | 88 | £203,280 | 2.0% |
| Australia | 57 | 9 | £132,852 | 1.3% |

**Findings:**
- EIRE generates £272k from just 4 customers — an average of £68k per customer. This is a notable concentration of revenue in very few accounts
- The Netherlands indicates  a similar pattern — 9 customers, £272k, averaging £30k each

---

## 6. One-time vs Repeat Customers

**View:** `vw_customer_segments`

| Segment | Customers | Total Revenue | Avg Spend | Avg Orders |
|---|---|---|---|---|
| One-time buyer | 1,499 | £590,927 | £394 | 1.0 |
| Repeat buyer | 2,829 | £7,928,174 | £2,802 | 6.0 |

**Findings:**
- Repeat buyers represent 65.4% of identified customers and 93.1% of identified-customer revenue
- The average repeat buyer generated seven times more revenue on average than a one-time buyer (£2,802 vs £394)

**Caveat:** The one-time vs repeat split is based on the 13-month observation window. A customer classified as one-time may have purchased before December 2010 or after December 2011 — the data cannot confirm their full relationship with the business.

---

## Dashboard — Customer Analysis

![Customer Analysis](Customer_Analysis.png)

---

## 7. RFM Segmentation

**View:** `vw_rfm`, `vw_rfm_summary`

Each identified customer is scored 1–5 on Recency, Frequency, and Monetary using `NTILE(5)` relative to the full customer base. Score 5 is best on every dimension. Segment labels are assigned by combining R and F scores.

| Segment | Customers | Avg Days Since Purchase | Avg Orders | Avg Spend | Total Revenue |
|---|---|---|---|---|---|
| Champions | 980 | 12 | 10.8 | £5,667 | £5,553,398 |
| Loyal | 1,090 | 33 | 3.6 | £1,373 | £1,496,389 |
| At Risk | 526 | 125 | 3.7 | £1,389 | £730,685 |
| Inactive | 1,499 | 188 | 1.2 | £445 | £667,684 |
| Recent | 233 | 18 | 1.0 | £304 | £70,946 |

**Champions revenue share:** £5,553,398 / £8,519,102 = **65.2% of identified-customer revenue**

**Findings:**
- Champions — 22.7% of identified customers — account for 65.2% of identified-customer revenue and average 10.8 orders at £5,667 each
- At Risk customers averaged 3.7 orders historically but have not purchased in approximately 4 months (avg 125 days). They represent £730k in spend that has gone quiet within the observation window
- Recent customers have bought within the last 18 days on average but placed only one order each — they are the natural pipeline into the Loyal and Champion segments

**Caveat on RFM scores:** Scores are relative to this specific dataset and customer base. A customer scored 5 on recency simply means they bought more recently than 80% of customers in this 13-month window — it does not carry over to a different dataset or time period.

---

## 8. Revenue Concentration

**View:** `vw_revenue_concentration`

| Customer Decile | Customers | Revenue | % of Total | Cumulative % |
|---|---|---|---|---|
| Top 10% (D1) | 433 | £5,267,961 | 61.8% | 61.8% |
| 11–20% (D2) | 433 | £1,117,944 | 13.1% | 75.0% |
| 21–30% (D3) | 433 | £686,828 | 8.1% | 83.0% |
| 31–40% (D4) | 433 | £465,365 | 5.5% | 88.5% |
| 41–50% (D5) | 433 | £326,190 | 3.8% | 92.3% |
| Bottom 50% (D6–D10) | 2,165 | £649,813 | 7.7% | 100.0% |

**The top 20% of identified customers account for 75.0% of identified-customer revenue.**

**Finding:** Revenue is highly concentrated in a small number of customers. This is consistent with a wholesale business model where a few large accounts drive the majority of volume. It also means the business carries meaningful customer concentration risk — the loss of a small number of key accounts would have a disproportionate revenue impact.

---

## 9. Guest vs Identified Revenue

**View:** `vw_guest_vs_identified`

| Month | Guest Revenue | Identified Revenue | Guest % |
|---|---|---|---|
| 2010-12 | £250,116 | £551,887 | 31.2% |
| 2011-01 | £120,226 | £549,188 | 18.0% |
| 2011-02 | £76,179 | £428,715 | 15.1% |
| 2011-03 | £121,720 | £569,828 | 17.6% |
| 2011-04 | £68,345 | £440,196 | 13.4% |
| 2011-05 | £91,605 | £652,401 | 12.3% |
| 2011-06 | £99,832 | £633,925 | 13.6% |
| 2011-07 | £118,028 | £566,958 | 17.2% |
| 2011-08 | £113,488 | £616,769 | 15.5% |
| 2011-09 | £105,094 | £909,475 | 10.4% |
| 2011-10 | £115,055 | £989,001 | 10.4% |
| 2011-11 | £346,717 | £1,109,033 | 23.8% |
| 2011-12 | £120,230 | £501,724 | 19.3% |

**Findings:**
- Guest revenue share ranged from 10.4% to 31.2% across the period — the variation month to month is notable but there is not enough data to identify a trend
- Without CustomerIDs, guest buyers cannot be tracked for retention, lifetime value, or remarketing

---

## 10. Cancellations

**View:** `vw_returns_overview`

| Month | Cancelled Orders | Cancelled Value |
|---|---|---|
| 2010-12 | 320 | £74,283 |
| 2011-01 | 259 | £131,221 |
| 2011-02 | 215 | £25,427 |
| 2011-03 | 312 | £34,110 |
| 2011-04 | 236 | £44,333 |
| 2011-05 | 308 | £46,690 |
| 2011-06 | 325 | £70,441 |
| 2011-07 | 262 | £37,531 |
| 2011-08 | 270 | £53,825 |
| 2011-09 | 327 | £38,463 |
| 2011-10 | 355 | £83,117 |
| 2011-11 | 436 | £47,164 |
| 2011-12 | 143 | £204,920 |
| **Total** | **3,768** | **~£891,525** |

**Cancellation rate:** 3,768 / (19,812 + 3,768) = **16.0% of all invoices placed**

**Findings:**
- Cancelled order volume was relatively consistent across most months (215–436 orders)
- January 2011 shows an elevated cancelled value (£131k). One possible explanation is the large MEDIUM CERAMIC TOP STORAGE JAR order being returned, though this cannot be confirmed from the aggregated view alone
- December 2011 (£205k cancelled) coincides with the partial dataset boundary — large orders placed and reversed before the dataset end date is one possible explanation, but again this is an inference rather than a confirmed finding
- The broad consistency in cancellation volume across months suggests this is a structural feature of operations rather than an isolated problem

---

## Recommendations

These are directional suggestions based on the observed data patterns. Each is qualified by the limitations of the dataset.

| Priority | Recommendation | Evidence | Caveat |
|---|---|---|---|
| High | Investigate what drives Champions and protect that segment | 980 customers = 65.2% of revenue, avg 10.8 orders | Scores are relative to this dataset only |
| High | Build a re-engagement programme for At Risk customers | 526 customers, £730k historical spend, ~4 months quiet | Observation window limits; some may have churned before Dec 2010 |
| High | Request prior years' data before committing to Q4 planning assumptions | Sep–Nov revenue ramp is strong within this dataset | Single year — cannot confirm this pattern repeats annually |
| Medium | Investigate Netherlands, Australia, EIRE as potential wholesale channels | Very high AOV relative to order count in all three | Cannot confirm account type from transaction data alone |
| Medium | Introduce account creation incentives for guest buyers | 16.5% of revenue has no CustomerID — invisible to retention analysis | |
| Medium | Nurture the Recent segment before they go cold | 233 customers, bought within 18 days, only 1 order each | |
| Lower | Investigate consistently high cancellation rate | 16% of all invoices — consistent across months | Cause is unknown without further data |
| Lower | Review top return-rate products with operations team | Small number of products driving high return volume | Return rates >100% need domain knowledge to interpret |
| 7 — Lower | Investigate 17.1% cancellation rate | Consistent across months — structural cause rather than isolated events |
| 8 — Lower | Review top return-rate products | Small number of products driving disproportionate returns and complaints |
