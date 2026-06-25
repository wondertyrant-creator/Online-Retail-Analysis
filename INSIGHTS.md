# Business Insights — Online Retail Analysis

Analysis of UCI Online Retail dataset covering December 2010 – December 2011.
All figures are derived from the SQL views built on the cleaned dataset (487,398 rows).

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

## Data Quality Summary

| Exclusion | Rows | Reason |
|---|---|---|
| Cancelled invoices | 9,288 | InvoiceNo begins with C |
| Negative quantities | 1,336 | Returns not tagged as cancellations |
| Zero or invalid unit prices | 43,887 | Includes empty values and non-numeric entries cast to 0 |
| **Total excluded** | **54,511** | |
| **Clean rows retained** | **487,398** | **89.9% of raw data** |

Note: the excluded_bad_price count (43,887) is higher than a simple count of zero-price rows because MySQL's CAST returns 0 for empty strings and non-numeric values — all of which are correctly excluded.

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
| 2011-12 | £621,955 | 819 | £759 | -57.3% (partial — ends 9 Dec) |

**Key findings:**
- Revenue was volatile in H1 2011, ranging from £505k to £744k
- A consistent Q4 ramp-up began in September 2011 (+38.9% MoM)
- November 2011 was the peak at £1.46M — nearly 3× February
- The December drop is a data boundary effect, not a real decline (only 9 days of data)
- AOV peaked in January 2011 (£619) due to a large bulk order, and again in December (£759) for the same reason

**Recommendation:** Plan stock, fulfilment capacity, and marketing spend ahead of September each year. The Q4 ramp-up is consistent and predictable.

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

**Key findings:**
- PAPER CRAFT, LITTLE BIRDIE sold 80,995 units in a single order (customer 16446) — one transaction generated £168k
- MEDIUM CERAMIC TOP STORAGE JAR sold 78,033 units across only 247 orders — another bulk buyer pattern
- REGENCY CAKESTAND spread £174k across 1,988 orders — consistent retail demand at higher unit price
- WHITE HANGING HEART appeared in 2,256 distinct orders — the most broadly purchased product in the top 10

**Recommendation:** Distinguish bulk-driven revenue (PAPER CRAFT, MEDIUM CERAMIC) from consistent demand products (REGENCY CAKESTAND, WHITE HANGING HEART). Forecasting and restocking strategies should differ between these two types.

---

## 3. Product Return Rate

**View:** `vw_product_return_rate`

**Top products by units returned:**

| Product | Units Sold | Units Returned | Return Rate |
|---|---|---|---|
| CREAM HANGING HEART T-LIGHT HOLDER | 61 | 2,578 | 4,226% |
| SET OF 36 VINTAGE CHRISTMAS DOILIES | 38 | 325 | 855% |
| GEMSTONE CHANDELIER T-LIGHT HOLDER | 78 | 433 | 555% |
| ENAMEL BOWL PANTRY | 24 | 121 | 504% |
| PAINTED HEART WREATH WITH BELL | 12 | 60 | 500% |
| GIN AND TONIC DIET METAL SIGN | 498 | 2,030 | 408% |

**Important note on return rates above 100%:**
These occur when returns span order periods outside the dataset window — a customer may have bought a product before December 2010 and returned it within our 13-month window, meaning the return count exceeds the visible sales count.

**Key findings:**
- PAPER CRAFT, LITTLE BIRDIE (top 2nd revenue product) had its entire £168k almost entirely negated by a single return — most likely a defective batch or recalled product
- MEDIUM CERAMIC TOP STORAGE JAR had a similarly high return value relative to sales
- A small number of products are responsible for a disproportionate share of returns

**Recommendation:** Investigate the top return-rate products with the product and operations teams. High-return products are both a customer satisfaction risk and a revenue risk.

---

## 4. Average Order Value and Basket Size

**View:** `vw_avg_order_value`, `vw_basket_size_by_month`, `vw_basket_size_by_country`

| Metric | Value |
|---|---|
| Overall AOV | £518 |
| Avg units per order | 222 |
| Avg lines per order | 24.6 |

**Context:** These figures are significantly higher than typical retail averages. This reflects the wholesale nature of the customer base — individual orders frequently involve hundreds or thousands of units. This is consistent with the high AOV seen in markets like the Netherlands and Australia.

**AOV by month:** Ranged from £411 (April 2011) to £759 (December 2011). The December figure is driven by partial-month large orders and should not be treated as a trend.

**Basket size by country (top 5 by AOV):**

| Country | Orders | Avg Units/Order | AOV |
|---|---|---|---|
| Netherlands | 93 | 1,782 | £2,929 |
| Australia | 57 | 1,191 | £2,331 |
| Japan | 19 | 938 | £1,819 |
| Hong Kong | 11 | 391 | £1,412 |
| Denmark | 18 | 375 | £1,021 |
| United Kingdom | 17,873 | ~217 | £518 |

**Key finding:** The Netherlands averages £2,929 per order with 1,782 units — nearly 6× the UK average. With only 93 orders this strongly indicates wholesale or trade accounts, not retail customers.

**Recommendation:** Investigate whether the Netherlands, Australia, and Japan represent deliberate wholesale channels. If they are, dedicated account management could scale this revenue stream.

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
| Spain | 90 | 30 | £60,043 | 0.6% |
| Switzerland | 54 | 22 | £54,578 | 0.5% |

**Key finding:** EIRE has only 4 unique customers generating £272k — an average of £68k per customer. The Netherlands has 9 customers generating £272k — £30k each. Both strongly suggest a small number of high-value wholesale accounts rather than retail customers.

---

## 6. Customer Segments — One-time vs Repeat

**View:** `vw_customer_segments`

| Segment | Customers | Total Revenue | Avg Spend | Avg Orders |
|---|---|---|---|---|
| One-time buyer | 1,499 | £590,927 | £394 | 1.0 |
| Repeat buyer | 2,829 | £7,928,174 | £2,802 | 6.0 |

**Key findings:**
- Repeat buyers are 65.4% of identified customers but account for **93.1% of identified-customer revenue**
- The average repeat buyer spends 7.1× more than a one-time buyer (£2,802 vs £394)
- 1,499 one-time buyers represent an opportunity — converting even 10% to repeat buyers would meaningfully increase revenue

**Recommendation:** Invest in early retention activity targeted at first-time buyers — follow-up communications, product recommendations, or loyalty incentives in the weeks after their first purchase.

---

## 7. RFM Customer Segmentation

**View:** `vw_rfm`, `vw_rfm_summary`

Each identified customer (excluding Guest) is scored 1–5 on three dimensions relative to the full customer base using NTILE(5):
- **Recency** — days since last order (score 5 = most recent)
- **Frequency** — number of distinct orders (score 5 = most frequent)
- **Monetary** — total spend (score 5 = highest spender)

Segment labels are assigned by combining R and F scores.

| Segment | Customers | Avg Days Since Purchase | Avg Orders | Avg Spend | Total Revenue |
|---|---|---|---|---|---|
| Champions | 980 | 12 | 10.8 | £5,667 | £5,553,398 |
| Loyal | 1,090 | 33 | 3.6 | £1,373 | £1,496,389 |
| At Risk | 526 | 125 | 3.7 | £1,389 | £730,685 |
| Inactive | 1,499 | 188 | 1.2 | £445 | £667,684 |
| Recent | 233 | 18 | 1.0 | £304 | £70,946 |

**Champions revenue share:** £5,553,398 / £8,519,102 = **65.2% of identified-customer revenue**

**Key findings:**
- Champions are 22.7% of identified customers but generate 65.2% of identified-customer revenue
- Champions average 10.8 orders each — the business depends heavily on this group's continued engagement
- At Risk customers averaged 3.7 orders historically but haven't bought in ~4 months — £730k in potentially recoverable revenue
- Recent customers bought within 18 days on average but have only 1 order — they are the natural pipeline for Loyal and Champion segments
- Inactive customers (1,499 people, 34.6% of base) have low frequency and spend — broad re-engagement campaigns are unlikely to be cost-effective

**Recommendations:**
- **Protect Champions** — understand what drives their behaviour and prioritise their experience. Any churn in this group has an outsized revenue impact
- **Re-engage At Risk** — 526 customers with proven purchase history who have gone quiet. Targeted outreach with personalised offers is commercially justified given £730k at stake
- **Nurture Recent** — early retention activity for the 233 newest customers while they are still engaged
- **Deprioritise Inactive** — average spend of £445 and very low order frequency makes broad campaigns unlikely to be cost-effective

---

## 8. Revenue Concentration (Pareto Analysis)

**View:** `vw_revenue_concentration`

| Customer Decile | Customers | Revenue | % of Total | Cumulative % |
|---|---|---|---|---|
| Top 10% (Decile 1) | 433 | £5,267,961 | 61.8% | 61.8% |
| 11–20% (Decile 2) | 433 | £1,117,944 | 13.1% | 75.0% |
| 21–30% (Decile 3) | 433 | £686,828 | 8.1% | 83.0% |
| 31–40% (Decile 4) | 433 | £465,365 | 5.5% | 88.5% |
| 41–50% (Decile 5) | 433 | £326,190 | 3.8% | 92.3% |
| 51–60% (Decile 6) | 433 | £238,364 | 2.8% | 95.1% |
| 61–70% (Decile 7) | 433 | £170,701 | 2.0% | 97.1% |
| 71–80% (Decile 8) | 433 | £123,015 | 1.4% | 98.6% |
| 81–90% (Decile 9) | 432 | £80,619 | 0.9% | 99.5% |
| Bottom 10% (Decile 10) | 432 | £42,114 | 0.5% | 100.0% |

**The top 20% of customers account for 75.0% of total identified-customer revenue.**

The Pareto principle holds strongly — revenue is highly concentrated. The top 10% alone account for 61.8% of revenue. This makes the Champions segment finding even more significant: protecting the top tier has a leverage effect far beyond their customer count.

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

**Key findings:**
- Guest revenue share ranged from 10.4% (September and October) to 31.2% (December 2010)
- The November 2011 spike in guest revenue (£346k, 23.8%) is unusual — worth investigating whether this was driven by a specific product or campaign
- Guest share was lowest during peak Q4 months (September and October) when identified customers drove the growth
- Without CustomerIDs, guest buyers cannot be tracked for retention, remarketing, or lifetime value analysis

**Recommendation:** Introduce account creation incentives at checkout — a discount, early access, or loyalty points. Converting guest buyers to account holders would make retention analysis more complete and unlock remarketing options for a segment currently invisible to CRM.

---

## 10. Returns and Cancellations

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

**Cancellation rate:** 3,768 cancelled orders out of 22,064 placed orders (including cancellations) = **17.1%**

**Key findings:**
- Cancelled order value was consistent at £25k–£83k for most months — structural rather than seasonal
- January 2011 (£131k) and December 2011 (£205k) are outliers
  - January: likely the MEDIUM CERAMIC TOP STORAGE JAR bulk order being returned
  - December: large orders placed and reversed before shipment at the dataset boundary
- The consistency across months confirms this is not caused by isolated events

**Recommendation:** Investigate whether cancellations are concentrated in specific products, order sizes, or customer types. That breakdown would identify where to focus improvement efforts.

---

## Top Customers

**View:** `vw_top_customers`

| Customer ID | Orders | Total Items | Total Spend |
|---|---|---|---|
| 14646 | 72 | 162,938 | £267,416 |
| 18102 | 60 | 64,124 | £259,657 |
| 17450 | 46 | 69,993 | £194,551 |
| 16446 | 2 | 80,997 | £168,473 |
| 14911 | 201 | 60,182 | £137,402 |
| 12415 | 21 | 61,748 | £119,391 |
| 14156 | 55 | 46,364 | £113,355 |
| 17511 | 31 | 47,966 | £85,913 |
| 16029 | 63 | 40,208 | £81,025 |
| 12346 | 1 | 74,215 | £77,184 |

**Notable patterns:**
- Customer 16446 spent £168k in just 2 orders (80,997 items) — the PAPER CRAFT bulk buyer
- Customer 12346 spent £77k in a single order (74,215 units of MEDIUM CERAMIC TOP STORAGE JAR) — this was almost entirely returned
- Customer 14911 placed 201 orders for £137k — a very different pattern of frequent smaller purchases
- Customers 14646 and 18102 show consistent high-frequency, high-value behaviour — classic Champions

---

## Overall Business Recommendations

| Priority | Recommendation | Evidence |
|---|---|---|
| 1 — High | Plan aggressively for Q4 from September | Sep–Nov drove 35%+ of annual revenue; Sep +38.9% MoM is consistent |
| 2 — High | Protect the Champions segment | 980 customers = 65.2% of identified-customer revenue; avg £5,667 spend |
| 3 — High | Re-engage At Risk customers | 526 customers, £730k spend history, ~4 months inactive |
| 4 — Medium | Convert guest buyers to accounts | Guest orders cannot be tracked for retention or remarketing |
| 5 — Medium | Investigate Netherlands/Australia as wholesale channels | £2,929 and £2,331 AOV respectively vs £518 UK average |
| 6 — Medium | Nurture Recent segment into Loyal | 233 customers, bought within 18 days, only 1 order each |
| 7 — Lower | Investigate 17.1% cancellation rate | Consistent across months — structural cause rather than isolated events |
| 8 — Lower | Review top return-rate products | Small number of products driving disproportionate returns and complaints |
