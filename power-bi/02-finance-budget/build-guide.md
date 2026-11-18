# 02 — Build Guide: Finance / Budget Dashboard

Follow in order. Estimated time: 30–60 minutes.

## Step 1 — Import the file

1. Open Power BI Desktop.
2. **Home tab → Get data → Text/CSV** → select `data/SAMPLE_Monthly_Spending.csv` → **Open**. Delimiter: **Comma**. Click **Transform Data**.

## Step 2 — Check types in Power Query

1. In the Queries pane, click the `SAMPLE_Monthly_Spending` query.
2. Verify the column types shown in the headers: `Date` should show a calendar icon (Date), `Category` an "ABC" icon (Text), `Amount` a "1.2" icon (Decimal Number).
3. If `Date` came in as text: select the column → **Transform tab → Data Type → Date** → Replace current. If `Amount` came in as text: **Data Type → Decimal Number**.
4. Sanity check: the row count at the bottom left should read **144**.
5. Rename the query: right-click `SAMPLE_Monthly_Spending` → **Rename** → type `Spending`.
6. **Home tab → Close & Apply.**

## Step 3 — Create the DAX measures

1. In the Fields pane, right-click the `Spending` table → **New measure**. Paste `Total Spend` from `dax.md`, press Enter.
2. Repeat for `Previous Month Spend`, `MoM % Change`, `MoM Flag`.
3. Set formats: select each measure → **Measure tools** tab → Currency (0 decimals) for the two money measures, Percentage (1 decimal) for `MoM % Change`.
4. Sanity check: create a temporary Card visual with `Total Spend`. It should read roughly **$1.23M** (24 months of sample spending). The exact figure depends on the seeded sample data in this kit; what matters is that it is a plausible 7-figure total, not blank and not zero.

## Step 4 — Build the report page

Create one page named "Finance / Budget".

### Visual 1 — MoM trend (line chart)
- **Visualizations pane → Line chart.**
- X-axis: `Spending[Date]`. Y-axis: `Total Spend`. Legend: `Spending[Category]`.
- This gives six lines, one per category, across 24 months. Salaries will dominate the scale — that is expected and is itself a finding (payroll is the budget).
- Optional readability fix: turn on **Format visual → Lines → Smooth**? Leave it off for an honest chart; smoothing hides real spikes.

### Visual 2 — Category comparison (bar chart)
- **Visualizations pane → Clustered bar chart** (or column chart).
- Axis: `Spending[Category]`. Values: `Total Spend`.
- Sort descending so the largest category is on top.

### Visual 3 — Flagged-jump table (the alert)
- **Visualizations pane → Table.**
- Columns, in order: `Spending[Category]`, `Spending[Date]`, `Total Spend`, `Previous Month Spend`, `MoM % Change`, `MoM Flag`.
- **Filter to flagged rows only:** with the table selected, open the **Filters pane** → "Filter on this visual" → find `MoM Flag` → check only **FLAGGED**. The table should now list the jumps: Marketing Nov 2024, Mar 2025, Nov 2025; Travel Jun 2024, Jun 2025, Jul 2025; Software Jan 2025.
- **Conditional formatting:** select the table → Format visual → Cell elements → select `MoM % Change` → Background color → click **fx** → Format by: **Rules** → "If value > 0.2, red background; otherwise no formatting". (Rules use decimals: 0.2 = 20%.) The flagged cells will read red at a glance.

### Slicers
- **Slicer** → `Spending[Date]` as a **date range slider** (in the slicer settings, change Style to "Between" if it defaults to a list). This is the date control for the dashboard.
- **Slicer** → `Spending[Category]`, horizontal buttons, multi-select on.
- Test: select only Marketing — the trend line, bar, and flagged table should all narrow to Marketing, and the flagged table should still show its three jumps.

## Step 5 — Final formatting pass

1. **Titles:** "Monthly Spending Trend by Category", "Total Spend by Category", "Categories That Jumped > 20% MoM".
2. **Number formats:** make sure the table shows currency with commas, not raw decimals.
3. **Save:** File → Save As → `Finance_Budget_Dashboard.pbix`. This `.pbix` is YOUR file, built by you — it is not part of this kit.

## Common mistakes and fixes

| Symptom | Cause | Fix |
|---|---|---|
| Previous Month Spend is blank everywhere | Date is a text column | Step 2: set Date type to Date |
| Flagged table is empty | MoM Flag compared against the wrong scale | Check the measure uses `> 0.2`, not `> 20` (DAX percentages are decimals) |
| MoM % Change shows 4000% | Previous Month Spend is 0 or blank in the denominator | DIVIDE handles blanks, but check the Date column has no gaps — every month must be present |
| Trend lines connect across missing months | A month is missing from the data | The sample file has all 24 months; re-check the import row count is 144 |
| Slicer on Date shows a list of days, not months | Date is daily-granularity in the slicer | Use the "Between" slider style, or group the slicer by Year/Month hierarchy |
