# 02 — Data Model: Finance / Budget

## Tables

### Spending (fact) — from `SAMPLE_Monthly_Spending.csv`, renamed from its file name

| Column | Type | Notes |
|---|---|---|
| Date | Date | First day of each month, Jan 2024 – Dec 2025. Must be Date type (not text) or the time-intelligence DAX will fail. |
| Category | Text | Rent / Salaries / Marketing / Travel / Supplies / Software. |
| Amount | Decimal number | Dollars spent in that category that month. |

**All data in this table is SAMPLE / illustrative data.** It is synthetic spending made for this portfolio project.

## Relationships

None. This is a deliberate single-table model:

- With one fact table and no dimensions, there is nothing to relate.
- Time intelligence (`DATEADD`) operates on `Spending[Date]` directly.
- Category breakdowns use `Spending[Category]` on the visual axis/legend, which needs no relationship.

## Grain (what one row means)

One row = one category's total spending in one month. 144 rows = 24 months × 6 categories. There is exactly one row per category-month, so summing `Amount` never double-counts.

## Why no calendar table here (and when to add one)

- For a first time-intelligence project, DATEADD on the fact's own date column is simpler and works: every month is present, with no gaps, so "previous month" is always defined (except Jan 2024, the first month, which correctly returns blank).
- **Stretch goal:** add a Calendar table (one row per date, or per month) and relate `Calendar[Date]` → `Spending[Date]`. That becomes necessary the moment months can be missing (a gap would make "previous month" skip) or when you want fiscal-year logic. The DAX in `dax.md` keeps working if you point DATEADD at the calendar date column instead.

## Data-quality notes

- No nulls, no duplicates in the sample file (verified at build time).
- Amounts are already clean decimals — no currency symbols or thousands separators to strip. A real finance export would usually need that step in Power Query; here it is documented as a step to check, not a step to perform.
