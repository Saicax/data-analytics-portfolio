# 05 — Data Model: Capstone

## Tables

### Sales (fact) — from `superstore.csv`, renamed from its file name

| Column | Type | Notes |
|---|---|---|
| Row ID | Whole number | Row identifier. The 806 junk rows have text here ("Person") — they are removed in Power Query, not in the model. |
| Order ID | Text | One order = many rows (many products). Never deduplicate on this. |
| Order Date | Date | Converted from text (M/D/YYYY) in Power Query. |
| Ship Date | Date | Converted from text. Kept for completeness; not used in the loss analysis. |
| Ship Mode | Text | Not used in this question. Kept, not deleted — deleting source columns is a decision you should be able to reverse. |
| Customer ID / Customer Name | Text | Not used in this question. |
| Segment | Text | Consumer / Corporate / Home Office. Used for a secondary cut of profit. |
| Country / City / State | Text | Country is United States throughout. Region is the geographic grain for this dashboard. |
| Postal Code | Text | Kept as text. 11 blanks left blank. |
| Region | Text | Central / East / South / West. |
| Product ID / Product Name | Text | Product Name is the grain for the worst-products table. |
| Category / Sub-Category | Text | The primary loss-analysis grain. |
| Sales | Decimal number | Converted from text in Power Query. |
| Quantity | Whole number | |
| Discount | Decimal number | 0–0.8. The key explanatory variable for the losses. |
| Profit | Decimal number | Converted from text in Power Query. Negative values are real and kept. |

## Relationships

None. One fact table.

## Why one table is the right call here (and what would change that)

- The question — "where are we losing money" — is answered entirely by grouping and summing one fact table. Every visual groups `Sales` by a column already in the table (Sub-Category, Region, Month, Product Name).
- A Calendar dimension would add value the moment the dashboard needs fiscal periods, year-over-year comparisons, or gap-free months. None of those are in this question.
- A Product dimension would add value if product attributes (supplier, cost, launch date) existed in a second file. They do not — everything about a product is already in this table.
- Building dimensions you do not need is a common beginner mistake: it adds relationships that can break, without changing any answer. The capstone discipline is to justify every table. Here, one table is justified; the rest is listed as stretch goals.

## Grain (what one row means)

One row = one product line on one order, after the 806 junk rows are removed: 9,994 rows. Summing `Sales` or `Profit` over rows is always valid; counting rows counts order lines, not orders and not customers.

## Cleaning decisions log (the "why" behind the Power Query steps)

| # | Issue found | Decision | Why |
|---|---|---|---|
| 1 | 806 embedded header rows (Row ID = "Person", rest blank) | Filter out rows with blank Order Date | They are export artifacts, not orders; keeping them inflates row counts and breaks date conversion |
| 2 | Dates stored as text (M/D/YYYY) | Convert Order Date, Ship Date to Date type | Monthly trend and any date math require real dates |
| 3 | Sales, Quantity, Discount, Profit stored as text | Convert to Decimal / Whole Number | Aggregation requires numeric types; text sums silently fail |
| 4 | 11 blank Postal Codes in valid rows | Leave blank | Inventing a postal code fabricates data; the column is unused in this analysis anyway |
| 5 | Same Order ID on many rows | Do NOT deduplicate | One order legitimately contains many products; deduplication would delete real sales |
| 6 | 1,871 negative-profit rows | Keep, and make them the analysis | They are the answer to the business question, not dirt |
