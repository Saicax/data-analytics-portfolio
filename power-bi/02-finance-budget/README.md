# 02 — Finance / Budget Dashboard

> **Finished dashboard included:** `Finance_Budget_Dashboard.pbix` — open it in Power BI Desktop. The kit below (prepared data, data model, written-out DAX measures including time intelligence, click-by-click build guide) shows how it was built.

## Business question

> "Show me month-over-month spending trends by category, and flag any category that jumped more than 20% from last month."

This dashboard answers two things:
1. **Trend:** how spending in each category moves month to month.
2. **Alert:** which categories jumped more than 20% versus the previous month — the ones a budget owner needs to explain.

## Data

| File | Rows | What it is |
|---|---|---|
| `data/SAMPLE_Monthly_Spending.csv` | 144 | **SAMPLE / illustrative data.** Monthly spending for 24 months (Jan 2024 – Dec 2025) × 6 categories: Rent, Salaries, Marketing, Travel, Supplies, Software. This is synthetic data made for this portfolio project — it is not a real company's finances. |

### Columns
- `Date` — first day of the month (e.g. 2024-01-01). Type: Date.
- `Category` — spending category. Type: Text.
- `Amount` — dollars spent that month in that category. Type: Decimal number.

### Built-in stories (so the flag visual has real content)
The sample data deliberately contains jumps above the 20% rule, including seasonal ones — a good reminder that a flag is a prompt to investigate, not proof of a problem:
- **Marketing, Nov 2024: +40%** (holiday-season push), **Mar 2025: +82%** (campaign launch), **Nov 2025: +109%** (holiday push again).
- **Travel, Jun 2024: +55%** and **Jun 2025: +37%** (summer travel season), **Jul 2025: +83%** (conference trip).
- **Software, Jan 2025: +40%** (annual license renewal).
- Rent, Salaries, and Supplies stay smooth — they should almost never flag.

## Data model

See `model.md`. This is the simplest model in the portfolio on purpose: **one fact table, no dimensions**. One table, `Spending`, with `Date`, `Category`, `Amount`. Time intelligence (PREVIOUSMONTH / DATEADD) works directly on `Spending[Date]` for a beginner build; a separate calendar table is the natural next improvement and is noted as a stretch goal in the build guide.

## DAX

See `dax.md`. The measures you will create:

| Measure | Purpose |
|---|---|
| `Total Spend` | Sum of Amount |
| `Previous Month Spend` | Same total, shifted one month back (DATEADD) |
| `MoM % Change` | (This month − Last month) ÷ Last month |
| `MoM Flag` | "FLAGGED" when MoM % Change > 20%, otherwise "OK" |

The 20% rule lives in exactly one place — the `MoM Flag` measure — so changing the threshold later means editing one line.

## Visuals (what you will build)

1. **MoM trend (line chart):** Amount by month, one line per category (legend = Category).
2. **Category comparison (bar chart):** Total spend by category.
3. **Flagged-jump table:** Category, Month, Amount, Previous Month Spend, MoM % Change — filtered to flagged rows only, with the MoM % Change column conditionally formatted red above 20%.
4. **Slicers:** Year and Category.

## What you will see when you build it

No screenshots or result figures are included in this kit (nothing here was rendered in Power BI). What you should expect: the trend lines show Salaries dominating total spend, Rent flat, and visible spikes in Marketing (Mar 2025, Nov 2025) and Travel (Jul 2025). The flagged table should list the jumps named above. If your flagged table is empty, check that `Previous Month Spend` uses DATEADD on the Date column and that Date is a Date type, not text.

## How to build it

Follow `build-guide.md` step by step: import → Power Query type check → DAX measures → visuals → conditional formatting. Estimated time: 30–60 minutes.
