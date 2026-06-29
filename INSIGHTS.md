# Business Insights — Online Retail Analysis

Analysis Online Retail dataset covering December 2010 – December 2011.
All figures are derived from the SQL views built on the cleaned dataset (539,388 rows).

---

## Limitations

**One year of data:** The dataset covers just over 13 months. Any pattern described as seasonal is observed within a single annual cycle. Additional years of data would be needed to confirm whether patterns repeat consistently. Recommendations that depend on seasonality should be treated as hypotheses to test, not confirmed strategies.

**Partial December 2011:** The dataset ends on 9 December 2011. December figures represent only 9 days of trading and should not be compared directly to other months.

**Wholesale rather than retail:** The customer base appears to be primarily wholesale or trade buyers. Average order values (£489), average units per order (~280), and country-level AOV figures (Netherlands: £3,028) are all consistent with bulk buying behaviour. Retail benchmarks do not apply.

**Guest customers limit retention tracking:** Rows with no CustomerID are included in revenue totals but excluded from all customer-level analysis. A meaningful portion of buying behaviour is unobservable.

**Observation window for returns:** Return rates compare returns within the 13-month window against sales within the same window. If a product was purchased before December 2010 and returned within the window, the denominator (units sold) is understated.

**Negative net revenue customers:** A small number of customers returned more value than they purchased within the observation window, producing negative monetary values in the RFM analysis. These are correctly included and scored — they represent a real cost to the business — but their full purchase history outside this window is unknown.

**Correlation vs causation:** Findings describe patterns in the data. Explanations for why those patterns exist are reasonable inferences but are not confirmed by the data itself.

---

## Summary Numbers

| Metric | Value | Note |
|---|---|---|
| Total Revenue | £9,769,872 | Net of returns at view level |
| Total Orders | 19,960 | Excludes cancellations |
| Average Order Value | £489 | Reflects wholesale buying — not comparable to retail benchmarks |
| Unique Customers (incl. Guest) | 4,339 | |
| Countries | 38 | UK accounts for 84.0% of revenue |
| Products Analysed | 3,827 | Excludes postage and admin codes |
| Date Range | Dec 2010 – Dec 2011 | December 2011 is partial (9 days only) |
| Raw Rows | 541,909 | |
| Clean Rows Retained | 539,388 | 99.5% — only truly invalid rows excluded at table level |

---

## Data Quality

| Metric | Count |
|---|---|
| Raw rows | 541,909 |
| Excluded — invalid data | 2,521 |
| Clean rows | 539,388 |
| Cancellations retained in clean_orders | 9,288 |
| % retained | 99.5% |

**Methodology note:** Cancellation rows are kept in `clean_orders` and filtered at the individual view level rather than excluded at the table level. This keeps each view's business logic visible and explicit — a reader can see exactly what each view includes and excludes, rather than having those decisions hidden inside the cleaning step. It also means the cancellations data remains available for return analysis without querying the raw table directly.

---

## Dashboard — Executive Overview

![Executive Overview](Executive_Overview.png)

---

## 1. Revenue Trend

**View:** `vw_monthly_revenue`

| Month | Revenue | Orders | AOV | MoM Growth |
|---|---|---|---|---|
| 2010-12 | £748,957 | 1,559 | £480 | — |
| 2011-01 | £560,000 | 1,086 | £515 | -25.2% |
| 2011-02 | £498,062 | 1,100 | £452 | -11.1% |
| 2011-03 | £683,267 | 1,454 | £469 | +37.2% |
| 2011-04 | £493,207 | 1,246 | £395 | -27.8% |
| 2011-05 | £723,333 | 1,681 | £430 | +46.7% |
| 2011-06 | £691,123 | 1,533 | £450 | -4.5% |
| 2011-07 | £681,300 | 1,475 | £461 | -1.4% |
| 2011-08 | £704,804 | 1,361 | £517 | +3.4% |
| 2011-09 | £1,019,687 | 1,837 | £555 | +44.7% |
| 2011-10 | £1,070,704 | 2,040 | £524 | +5.0% |
| 2011-11 | £1,461,756 | 2,769 | £527 | +36.5% |
| 2011-12 | £433,668 | 819 | £529 | -70.3% (partial month) |

**Findings:**
- Revenue was highly volatile in H1 2011 — swings of -27.8% and +46.7% within consecutive months suggest the business is sensitive to a small number of large orders rather than driven by steady demand
- A step-change in both revenue and order count occurred from September 2011 onwards — September +44.7%, October +5.0%, November +36.5%
- November 2011 was the highest month at £1.46M — nearly 3× February and nearly double the average H1 monthly figure
- The H1 volatility and H2 ramp are two distinct patterns requiring different explanations. The H2 ramp could be seasonal, could reflect sales activity, or could be a coincidence of large orders — one year of data is insufficient to distinguish between these explanations

**What this means for planning:** The September–November ramp is a compelling pattern but should not drive resource planning decisions on the basis of a single year. The appropriate action is to validate the pattern against prior year data before committing to seasonal stock or staffing changes. If prior data confirms the pattern, the September ramp at +44.7% would be the key trigger point to plan around.

---

## 2. Product Performance

**View:** `vw_top_products`

**Top 10 products by net revenue:**

| Product | Units Sold | Orders | Net Revenue |
|---|---|---|---|
| REGENCY CAKESTAND 3 TIER | 13,022 | 1,988 | £164,762 |
| WHITE HANGING HEART T-LIGHT HOLDER | 35,313 | 2,256 | £99,668 |
| PARTY BUNTING | 18,018 | 1,685 | £98,302 |
| JUMBO BAG RED RETROSPOT | 47,359 | 2,089 | £92,356 |
| RABBIT NIGHT LIGHT | 30,680 | 994 | £66,756 |
| PAPER CHAIN KIT 50'S CHRISTMAS | 18,902 | 1,160 | £63,791 |
| ASSORTED COLOUR BIRD ORNAMENT | 36,381 | 1,455 | £58,959 |
| CHILLI LIGHTS | 10,226 | 661 | £53,768 |
| SPOTTY BUNTING | 8,217 | 1,140 | £42,065 |
| JUMBO BAG PINK POLKADOT | 21,009 | 1,218 | £41,619 |

**Why PAPER CRAFT, LITTLE BIRDIE does not appear:** In gross terms, this product generated £168k from a single bulk order by customer 16446 — which would have placed it second. However, that order was almost entirely returned, making its net revenue contribution near zero. Using net revenue correctly removes it from the ranking. This is the more meaningful measure for product planning — a product that was immediately returned delivered no actual value to the business regardless of its gross revenue figure.

**Findings:**
- The top 10 products are all distributed across hundreds or thousands of distinct orders, suggesting genuine and consistent demand — no single bulk order is distorting the list
- REGENCY CAKESTAND leads at £164k across 1,988 orders — the strongest signal of reliable, repeatable demand in the dataset
- WHITE HANGING HEART appears in 2,256 orders — the most broadly purchased product in the top 10, appearing in more distinct invoices than any other
- The top 10 are all decorative home or gift items, consistent with the business profile as a gift retailer

**What this means for planning:** Products in this list with high order counts (REGENCY CAKESTAND, WHITE HANGING HEART, PARTY BUNTING, JUMBO BAG RED RETROSPOT) are the most reliable for stock planning — their demand is spread across many customers rather than concentrated in one account. Products with lower order counts (RABBIT NIGHT LIGHT at 994) may carry more concentration risk despite strong revenue.

---

## Dashboard — Product Analysis

![Product Analysis](Product_Analysis.png)

---

## 3. Product Return Rate

**View:** `vw_product_return_rate`

| Product | Units Sold | Units Returned | Net Revenue | Return Rate |
|---|---|---|---|---|
| REGENCY CAKESTAND 3 TIER | 13,879 | 857 | £164,762 | 6.2% |
| WHITE HANGING HEART T-LIGHT HOLDER | 37,891 | 2,578 | £99,668 | 6.8% |
| PARTY BUNTING | 18,295 | 277 | £98,302 | 1.5% |
| JUMBO BAG RED RETROSPOT | 48,474 | 1,115 | £92,356 | 2.3% |
| PAPER CHAIN KIT 50'S CHRISTMAS | 19,355 | 453 | £63,791 | 2.3% |
| JUMBO BAG PINK POLKADOT | 21,465 | 456 | £41,619 | 2.1% |
| DOORMAT KEEP CALM AND COME IN | 5,491 | 225 | £36,565 | 4.1% |
| JUMBO BAG APPLES | 14,920 | 723 | £29,166 | 4.8% |

**Findings:**
- Return rates for the top revenue products range from 1.5% to 6.8% — these are reasonable figures for a wholesale operation and do not indicate a systemic returns problem
- WHITE HANGING HEART has the highest return rate among top products at 6.8% (2,578 units). At this volume it is worth monitoring but does not represent an immediate concern
- PARTY BUNTING at 1.5% return rate is the cleanest product in the top group — very low returns relative to volume
- The absence of products with return rates above 10% among the top revenue items is a positive signal

**Revised conclusion from earlier analysis:** A previous version of this analysis flagged return rates above 100% for some products (e.g. CREAM HANGING HEART T-LIGHT HOLDER at 4,000%+). These were an artefact of the observation window — products returned in bulk during the 13 months but purchased in bulk before December 2010, meaning returns exceeded visible sales. The updated SQL handles this correctly. For the products that actually matter by revenue, return rates are within a normal operating range.

**What this means for planning:** Returns are not a major operational concern based on this data. The highest-volume products have return rates of 2–7%, which is consistent with wholesale norms. WHITE HANGING HEART is the only top product worth monitoring given its 2,578 units returned, but its net revenue (£99k) remains strong.

---

## 4. Average Order Value and Basket Size

**Views:** `vw_avg_order_value`, `vw_basket_size_by_month`, `vw_basket_size_by_country`

| Metric | Value |
|---|---|
| Overall AOV | £489 |
| Avg units per order (overall) | ~280 |
| Avg lines per order (overall) | ~26 |

**Context:** These figures are significantly higher than retail norms (typically £30–60 AOV, 2–5 items per order). They are consistent with wholesale buying behaviour where individual orders regularly involve hundreds or thousands of units. Any comparison to retail industry benchmarks should account for this.

**Basket size by country (top 6 by AOV):**

| Country | Orders | Avg Units/Order | Avg Lines/Order | AOV |
|---|---|---|---|---|
| Netherlands | 94 | 2,131 | 25.1 | £3,028 |
| Australia | 57 | 1,472 | 20.7 | £2,405 |
| Japan | 19 | 1,369 | 16.9 | £1,860 |
| EIRE | 288 | 511 | 27.4 | £914 |
| Sweden | 36 | 1,002 | 12.5 | £1,016 |
| Switzerland | 54 | 567 | 36.4 | £1,044 |
| United Kingdom | 18,019 | 258 | 26.9 | £455 |

**Basket size by month:**

| Month | Orders | Avg Units/Order | Avg Lines/Order | AOV |
|---|---|---|---|---|
| 2011-01 | 1,086 | 357 | 31.6 | £515 |
| 2011-04 | 1,246 | 248 | 23.4 | £395 |
| 2011-09 | 1,837 | 310 | 26.8 | £555 |
| 2011-11 | 2,769 | 272 | 30.1 | £527 |

**Findings:**
- The Netherlands averages 2,131 units per order and £3,028 AOV across only 94 orders and 9 customers — far above any other country and consistent with a small number of wholesale accounts rather than retail buyers
- Australia shows a similar pattern (1,472 units, £2,405) at an even smaller scale (57 orders, 9 customers)
- January 2011 shows the highest monthly avg units per order (357) — likely driven by a small number of very large individual orders in a lower-volume month, which inflates the average
- AOV was lowest in April (£395) and highest in September (£555) — the September figure aligns with the revenue ramp and may reflect a different order mix rather than a true price change

**What this means:** The Netherlands and Australia's outsized AOV figures are the most commercially interesting finding in this section. If these represent deliberate wholesale channel relationships, understanding and developing them further could be highly valuable. If they are opportunistic one-off buyers, the numbers could look very different next year.

---

## 5. Geographic Revenue

**View:** `vw_revenue_by_country`

| Country | Orders | Customers | Revenue | Share |
|---|---|---|---|---|
| United Kingdom | 18,019 | 3,950 | £8,209,930 | 84.0% |
| Netherlands | 94 | 9 | £284,661 | 2.9% |
| EIRE | 288 | 4 | £263,276 | 2.7% |
| Germany | 457 | 95 | £221,698 | 2.3% |
| France | 392 | 88 | £197,403 | 2.0% |
| Australia | 57 | 9 | £137,077 | 1.4% |
| Switzerland | 54 | 22 | £56,385 | 0.6% |
| Spain | 90 | 31 | £54,774 | 0.6% |

**Findings:**
- EIRE generates £263k from just 4 customers — an average of £65k per customer. This is the highest revenue concentration per customer of any country and likely reflects a very small number of large accounts
- Germany and France have substantially more customers (95 and 88) at much lower average order values — closer to a retail or mixed buyer profile
- The Netherlands and EIRE together account for 5.6% of revenue from a combined 13 customers — a meaningful concentration in very few accounts that should be tracked as a risk as much as an opportunity

**What this means:** The geographic revenue picture is bifurcated. Germany, France, and the UK represent broad-based customer demand. Netherlands, EIRE, and Australia represent high-value but narrow account relationships. The revenue risk profile is different for each group — losing one Netherlands customer would hurt far more proportionally than losing one UK customer.

---

## 6. One-time vs Repeat Customers

**View:** `vw_customer_segments`

| Segment | Customers | Total Revenue | Avg Spend | Avg Orders |
|---|---|---|---|---|
| One-time buyer | 1,526 | £510,702 | £335 | 1.0 |
| Repeat buyer | 2,845 | £7,789,363 | £2,738 | 6.0 |

**Findings:**
- Repeat buyers represent 65.1% of identified customers but 93.8% of identified-customer revenue
- The average repeat buyer spends 8.2× more than a one-time buyer (£2,738 vs £335)
- 1,526 one-time buyers collectively spent £510k — an average of £335 each. Converting even 10% of these to repeat buyers (adding one additional order at the repeat buyer average) would add approximately £245k in incremental revenue

**Important caveat:** The one-time vs repeat classification is based on the 13-month observation window only. A customer who bought twice before December 2010 and once during this window would appear as a one-time buyer. The true repeat rate is likely higher than the data shows. This also means the 1,526 "one-time buyers" are not all genuinely new customers — some will have history outside the window.

**What this means for strategy:** The 8.2× spend multiplier for repeat buyers is a strong signal for retention investment. However, because of the observation window caveat, any retention campaign should focus on recency of last purchase rather than simply classifying buyers as one-time vs repeat. The RFM segmentation addresses this more precisely.

---

## Dashboard — Customer Analysis

![Customer Analysis](Customer_Analysis.png)

---

## 7. RFM Segmentation

**View:** `vw_rfm`, `vw_rfm_summary`

Each identified customer is scored 1–5 on Recency, Frequency, and Monetary using `NTILE(5)` relative to the full customer base within this 13-month window. Score 5 is best on every dimension. Segments are assigned by combining R and F scores.

| Segment | Customers | Avg Days Since Purchase | Avg Orders | Avg Spend | Total Revenue |
|---|---|---|---|---|---|
| Champions | 982 | 12 | 10.9 | £5,730 | £5,626,547 |
| Loyal | 1,094 | 33 | 3.6 | £1,210 | £1,323,855 |
| At Risk | 526 | 125 | 3.8 | £1,308 | £688,089 |
| Inactive | 1,503 | 187 | 1.2 | £397 | £596,318 |
| Recent | 233 | 18 | 1.0 | £325 | £75,668 |

**Champions revenue share:** £5,626,547 / £8,310,477 = **67.7% of identified-customer revenue**

**Findings:**

**Champions** — 982 customers averaging 10.9 orders at £5,730 each generate 67.7% of all identified-customer revenue. The business is heavily dependent on this relatively small group. Any churn within Champions has an outsized revenue impact — losing 10% of Champions would reduce identified-customer revenue by approximately £562k.

**Loyal** — 1,094 customers with good recency (33 days) and consistent ordering (3.6 orders) but significantly lower average spend (£1,210) than Champions (£5,730). The spend gap between Loyal and Champions is large — nearly 5× — which is worth investigating. Is this a product mix difference, order size difference, or buyer type difference? Understanding this gap could identify what specifically drives Champions' higher value.

**At Risk** — 526 customers who averaged 3.8 orders historically but haven't purchased in approximately 4 months. Their average spend (£1,308) is close to Loyal, suggesting these were engaged customers who have recently gone quiet rather than low-value customers. The £688k they represent is at risk of being lost permanently. At 125 days since last purchase, they are still within a recoverable window for most wholesale relationships.

**Inactive** — 1,503 customers (the largest segment) with very low frequency (1.2 orders) and low spend (£397). These customers are largely single-purchase buyers who never returned. Broad re-engagement campaigns for this group are unlikely to be cost-effective given the low historical spend — targeted outreach would need very high conversion rates to justify the cost.

**Recent** — 233 customers who bought within the last 18 days on average but have only placed 1 order each. These are the business's newest relationships and represent the pipeline into Loyal and Champions segments. Early intervention — a good first experience, timely follow-up, personalised next purchase suggestions — has the highest potential return here because the relationship is still forming.

**Customers with negative net revenue:** A small number of customers appear in the RFM data with negative monetary values, meaning their returns exceeded their purchases within the observation window. These customers have low monetary scores (1) and are classified as Inactive. While the numbers are small, these customers represent a net cost rather than a revenue contribution and may warrant specific investigation — particularly if they are repeat returners rather than one-off incidents.

**What this means for strategy:** The RFM analysis produces three distinct priorities:
1. Protect Champions — the cost of losing them far outweighs the cost of any retention programme
2. Re-engage At Risk — they have demonstrated value (avg £1,308) and are still within a reasonable outreach window
3. Develop Recent — the cheapest window to establish a lasting relationship is immediately after the first purchase

---

## 8. Revenue Concentration

**View:** `vw_revenue_concentration`

| Customer Decile | Customers | Revenue | % of Total | Cumulative % |
|---|---|---|---|---|
| Top 10% (D1) | 438 | £4,984,121 | 60.0% | 60.0% |
| 11–20% (D2) | 437 | £1,145,234 | 13.8% | 73.8% |
| 21–30% (D3) | 437 | £708,041 | 8.5% | 82.4% |
| 31–40% (D4) | 437 | £477,331 | 5.8% | 88.1% |
| 41–50% (D5) | 437 | £333,354 | 4.0% | 92.1% |
| 51–60% (D6) | 437 | £244,828 | 2.9% | 95.1% |
| 61–70% (D7) | 437 | £173,204 | 2.1% | 97.2% |
| 71–80% (D8) | 437 | £126,464 | 1.5% | 98.7% |
| 81–90% (D9) | 437 | £82,539 | 1.0% | 99.7% |
| Bottom 10% (D10) | 437 | £24,944 | 0.3% | 100.0% |

**The top 20% of identified customers account for 73.8% of identified-customer revenue.**
**The top 10% alone account for 60.0%.**

**Findings:**
- Revenue concentration is extreme — the top decile (438 customers) generates 60p in every £1 of identified-customer revenue
- The drop-off from decile 1 to decile 2 is steep (60.0% to 13.8%), meaning even within the "top 20%" there is enormous variation in customer value
- The bottom 50% of customers (deciles 6–10) collectively generate only 7.9% of revenue

**What this means:** This level of concentration is consistent with a wholesale business where a small number of large trade accounts dominate revenue. It is not unusual but it does mean the business carries significant concentration risk — the top 10% of customers are not interchangeable with the next 10%. A retention or growth strategy that treats all customers equally would be misallocating effort. Resources should be heavily weighted toward the top decile.

---

## 9. Guest vs Identified Revenue

**View:** `vw_guest_vs_identified`

| Month | Guest Revenue | Identified Revenue | Total | Guest % | Guest Orders | Identified Orders |
|---|---|---|---|---|---|---|
| 2010-12 | £194,353 | £554,604 | £748,957 | 25.9% | 177 | 1,708 |
| 2011-01 | £84,925 | £475,074 | £560,000 | 15.2% | 110 | 1,236 |
| 2011-02 | £61,516 | £436,546 | £498,062 | 12.4% | 118 | 1,201 |
| 2011-03 | £103,302 | £579,964 | £683,267 | 15.1% | 153 | 1,619 |
| 2011-04 | £67,159 | £426,047 | £493,207 | 13.6% | 102 | 1,384 |
| 2011-05 | £75,082 | £648,251 | £723,333 | 10.4% | 146 | 1,849 |
| 2011-06 | £83,109 | £608,013 | £691,123 | 12.0% | 155 | 1,707 |
| 2011-07 | £107,061 | £574,238 | £681,300 | 15.7% | 152 | 1,593 |
| 2011-08 | £88,436 | £616,368 | £704,804 | 12.5% | 96 | 1,543 |
| 2011-09 | £88,247 | £931,440 | £1,019,687 | 8.7% | 93 | 2,077 |
| 2011-10 | £96,101 | £974,603 | £1,070,704 | 9.0% | 139 | 2,263 |
| 2011-11 | £329,348 | £1,132,407 | £1,461,756 | 22.5% | 125 | 3,085 |
| 2011-12 | £91,161 | £342,506 | £433,668 | 21.0% | 44 | 921 |

**Total guest revenue: ~£1,469,800 (approximately 15.0% of total revenue)**

**Findings:**
- Guest revenue share is lowest in September and October (8.7% and 9.0%) — the months with the highest identified customer activity. This is consistent with the Q4 ramp being driven primarily by existing account holders
- November 2011 shows a notable guest spike — £329k at 22.5% share, which is £242k above the monthly average for guest revenue. This is worth investigating: it could reflect seasonal buyers who don't hold accounts, new accounts not yet set up, or a specific promotional channel attracting anonymous buyers
- The December 2010 guest share (25.9%) is the highest in the dataset. Without a prior December for comparison, it is unclear whether this is a seasonal baseline or an anomaly

**What this means:** The pattern suggests that the Q4 revenue ramp is largely driven by identified customers — the businesses and trade buyers who hold accounts. Guest revenue is relatively stable in absolute terms across most months. The November spike is the only point where guest behaviour materially diverges from the trend and is worth investigating before drawing any conclusions about the guest channel.

---

## 10. Top Customers

**View:** `vw_top_customers`

| Customer ID | Orders | Total Items Bought | Total Spend |
|---|---|---|---|
| 14646 | 73 | 196,143 | £279,489 |
| 18102 | 60 | 64,122 | £256,438 |
| 17450 | 46 | 69,029 | £187,482 |
| 14911 | 201 | 76,930 | £132,572 |
| 12415 | 21 | 76,946 | £123,725 |
| 14156 | 55 | 57,025 | £113,384 |
| 17511 | 31 | 63,012 | £88,125 |
| 16684 | 28 | 49,390 | £65,892 |
| 13694 | 50 | 61,803 | £62,653 |
| 15311 | 91 | 37,720 | £59,419 |

**Notable absence — customer 16446:** This customer previously ranked second with £168k in gross spend — entirely on PAPER CRAFT, LITTLE BIRDIE. After that purchase was returned, their net contribution to the business is near zero. They do not appear in this ranking. This is a good example of why net revenue is the appropriate measure for customer value — a customer who purchases and immediately returns at scale is not a high-value customer.

**Findings:**
- Customer 14646 leads at £279k across 73 orders — high frequency and high volume, consistent with a regular trade account
- Customer 14911 placed 201 orders for £132k — the most frequent buyer in the dataset at roughly £659 per order, suggesting a very different buying pattern from 14646 (~£3,827 per order). Both are valuable but for different reasons
- The top 3 customers (14646, 18102, 17450) collectively account for approximately £723k — about 7.4% of total revenue from just 3 accounts

---

## 11. Cancellations

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

**Cancellation rate:** 3,768 / (19,960 + 3,768) = **15.9% of all invoices placed**

**Findings:**
- Cancelled order count was consistent across most months (215–436) — a structural feature rather than isolated events
- Cancelled value was more variable — January 2011 (£131k) and December 2011 (£205k) stand out
- January's elevated cancelled value likely reflects a large order being returned shortly after placement. December's figure coincides with the dataset boundary — large orders placed in early December may have been cancelled before shipment and before the dataset ends
- The 15.9% cancellation rate by invoice count is notable but without industry benchmarks it is difficult to assess whether this is high, typical, or low for a wholesale operation

**What this means:** Cancellations represent approximately £891k of reversed transactions. The consistency of the count across months suggests the business has a structural level of order reversal that is baked into operations. Understanding whether this is driven by a small number of high-value order reversals (as suggested by January and December) or widespread low-value cancellations would determine where to focus improvement efforts.

---

## Recommendations

| Priority | Recommendation | Evidence | Caveat |
|---|---|---|---|
| High | Protect and understand what drives Champions | 982 customers = 67.7% of identified revenue; losing 10% would cost ~£562k | Scores are relative to this dataset only |
| High | Investigate the gap between Loyal and Champions avg spend (£1,210 vs £5,730) | Understanding this gap could convert Loyal buyers to Champions | May reflect different buyer types, not just engagement levels |
| High | Re-engage At Risk customers within the next 2–3 months | 526 customers, £688k historical spend, avg 125 days inactive | Some may have permanently churned before Dec 2010 |
| Medium | Request prior year data before committing to Q4 seasonal planning | Sep–Nov ramp is strong but based on a single year | Cannot confirm annual recurrence |
| Medium | Investigate Netherlands, EIRE, Australia as high-value accounts | AOV of £3,028 / £914 / £2,405 vs £455 for UK — very different buyer profiles | Cannot confirm account type from transaction data alone |
| Medium | Act early on Recent segment while relationships are still forming | 233 customers, bought within 18 days, only 1 order each — easiest conversion window | |
| Medium | Introduce account creation incentives for guest buyers | ~£1.47M revenue (15.0%) from buyers with no CustomerID — cannot be tracked or remarketed | |
| Lower | Investigate the January 2011 and December 2011 cancellation spikes | Both show cancelled values 2–4× the monthly average | Cause cannot be confirmed from aggregated data |
| Lower | Monitor negative net revenue customers | Small number visible in RFM data — may indicate quality, fraud, or dispute issues | Numbers are small; context needed before acting |
