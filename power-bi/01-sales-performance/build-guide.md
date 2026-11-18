# 01 — Build Guide: Sales Performance Dashboard

Follow in order. Nothing here assumes prior Power BI experience beyond opening the app. Estimated time: 45–90 minutes.

## Step 1 — Import the four files

1. Open Power BI Desktop. Close the welcome splash if it appears.
2. **Home tab → Get data → Text/CSV.**
3. Select `data/superstore.csv` → **Open**. In the preview, check the delimiter is **Comma** and the file origin is **65001: Unicode (UTF-8)**. Click **Transform Data** (NOT Load) — we need to clean it first.
4. Repeat for the other three files, one at a time: **Home tab → Get data → Text/CSV** → select `data/SAMPLE_Targets_by_Region_Month.csv` → **Transform Data**. Then `data/DimCalendar.csv`, then `data/DimRegion.csv`. Each opens in the same Power Query Editor window as a new query in the left-hand Queries pane.

## Step 2 — Clean the Sales query in Power Query

In the Queries pane, click the `superstore` query.

1. **Remove the 806 junk rows.** These are repeated header rows embedded in the export (rows where `Row ID` reads "Person" and every other column is blank). They are not truly blank rows, so "Remove Blank Rows" will not catch them. Instead, filter on the date column:
   - Click the dropdown arrow on the `Order Date` column header → uncheck **(null)** / blank entries → **OK**. This removes every row with no order date, which is exactly the junk rows.
   - Confirm the row count at the bottom left drops from 10,800 to **9,994**.
2. **Fix the date columns.** Select `Order Date` (click its header). **Transform tab → Data Type → Date**. A "Change Column Type" dialog appears → **Replace current**. Repeat for `Ship Date`. If any values fail to parse, Power Query will show errors — check the error count at the bottom; it should be 0 after the junk rows are gone.
3. **Fix the number columns.** Select `Sales`, then **Transform tab → Data Type → Decimal Number** → Replace current. Repeat: `Quantity` → **Whole Number**; `Discount` → **Decimal Number**; `Profit` → **Decimal Number**.
4. **Keep Postal Code as text.** If Power Query guessed it as a number, set it back: select `Postal Code` → **Data Type → Text**. (Postal codes are identifiers, not quantities, and leading zeros matter.)
5. **Add the MonthStart column.** **Add Column tab → Custom Column.** Name: `MonthStart`. Formula: `Date.StartOfMonth([Order Date])`. Click **OK**. Set its type to **Date** if it is not already.
6. **Rename the query.** In the Queries pane, right-click `superstore` → **Rename** → type `Sales`.
7. Leave the other three queries alone except renaming: right-click `SAMPLE_Targets_by_Region_Month` → **Rename** → `Targets`; `DimCalendar` → `Calendar`; `DimRegion` → `Region`. (Their types should already be correct; spot-check that `Targets[MonthStart]` and `Calendar[MonthStart]` are Date type.)
8. **Home tab → Close & Apply.** Power BI loads the four tables.

## Step 3 — Build the relationships (Model view)

1. Click the **Model view** icon on the left rail (the diagram icon, third from top).
2. You should see four table cards: Sales, Targets, Calendar, Region. If any card is missing, go back to Data view and check the load completed.
3. Create each relationship by dragging from the dimension field to the fact field:
   - Drag `Calendar[MonthStart]` onto `Sales[MonthStart]`.
   - Drag `Calendar[MonthStart]` onto `Targets[MonthStart]`.
   - Drag `Region[Region]` onto `Sales[Region]`.
   - Drag `Region[Region]` onto `Targets[Region]`.
4. Each relationship line should show a **1** on the dimension end and a **\*** on the fact end, with the arrow pointing toward the fact table. If a relationship shows as many-to-many, you dragged the wrong direction — delete it (click the line, press Delete) and redo it.
5. Do NOT create a direct relationship between Sales and Targets. The shared dimensions are the join.

## Step 4 — Create the DAX measures

1. Switch to **Data view** (the table icon) or stay in Model view — measures can be created in either.
2. In the Fields pane, right-click the `Sales` table → **New measure**. Replace the default text with the `Total Sales` formula from `dax.md`, press Enter. Repeat for the remaining measures, each in its table:
   - `Sales` table: `Total Sales`, `Variance`, `MTD Sales`
   - `Targets` table: `Target Sales`, `MTD Target`
   - `Sales` table: `Achievement %` (it references both, but measures live in one table — Sales is the natural home)
3. Set formats: select each measure → **Measure tools** tab → set Currency (0 decimals) for the money measures, Percentage (1 decimal) for `Achievement %`.
4. Sanity check: create a temporary Card visual with `Total Sales`. It should read roughly **$2,297,201**. If it reads far higher, the junk rows were not removed — go back to Step 2.1.

## Step 5 — Build the report page

Create one page named "Sales Performance". Place visuals in this order:

### Row 1 — KPI cards (4 cards across the top)
- **Visualizations pane → Card.** Drag `MTD Sales` into the card's Fields well. Repeat for `MTD Target`, `Achievement %`, `Variance`.
- **Title each card:** select the card → Format visual → General → Title → type "MTD Sales", "MTD Target", "Achievement %", "Variance".
- **Achievement % conditional formatting:** select the Achievement % card → Format visual → Callout value → Colors → click **fx** → Format by: **Rules** → "If value >= 1, green; if value < 1, red". (Values are decimals: 1 = 100%.)

### Visual 2 — Region breakdown (clustered bar chart)
- **Visualizations pane → Clustered bar chart.**
- Y-axis: `Region[Region]`. X-axis: `Total Sales` and `Target Sales`. Legend will show Actual vs Target automatically.
- **Conditional formatting for below-target regions:** this is done with a helper approach — select the chart → Format visual → Bars → Colors → click **fx** next to Default color → Format by: **Field value** → select `Achievement %`... Note: field-value coloring colors by the row's achievement; to color the *bar* per region, use the `Achievement %` measure with "Minimum / Maximum" gradient rules, or simpler: add a second visual, a **table** listing Region + Achievement %, and apply cell conditional formatting (Format visual → Cell elements → Background color → fx → Rules: < 1 = light red, >= 1 = light green). The table is what makes "which region needs attention" unmistakable.

### Visual 3 — Monthly trend (line chart)
- **Visualizations pane → Line chart.**
- X-axis: `Calendar[MonthName]`. Y-axis: `Total Sales` and `Target Sales`.
- Sort the X-axis chronologically: click the chart → ... (More options) → Sort axis → sort by `Calendar[MonthStart]` ascending (MonthName alone sorts alphabetically, which scrambles the timeline — this is the most common beginner mistake in this project).

### Slicers (left side or top)
- **Slicer** visual → Field: `Calendar[Year]`, style: dropdown or list.
- **Slicer** visual → Field: `Calendar[MonthName]` — or better, a single **Date range slicer** on `Calendar[MonthStart]`.
- **Slicer** visual → Field: `Region[Region]`, style: horizontal buttons.
- Test: pick Region = West and a single month — all four KPI cards and both charts should update together. If targets do not move but sales do, a relationship is missing (Step 3).

## Step 6 — Final formatting pass

1. **Report theme:** View tab → Themes → pick a clean built-in theme (e.g. "Light" or "Executive"). Keep it consistent across pages.
2. **Titles:** give every visual a plain-English title ("Sales vs Target by Region", "Monthly Sales vs Target").
3. **Data labels:** turn on for the bar chart (Format visual → Data labels → On) so values are readable without hovering.
4. **Save:** File → Save As → `Sales_Performance_Dashboard.pbix`. This `.pbix` is YOUR file, built by you — it is not part of this kit, and that is expected.

## Common mistakes and fixes

| Symptom | Cause | Fix |
|---|---|---|
| Total Sales ≈ $2.30M + a small extra | Junk rows not removed | Step 2.1: filter out null Order Dates |
| Targets don't respond to slicers | Missing Calendar/Region relationship | Step 3: check all four lines exist |
| Monthly line jumps around | MonthName sorted alphabetically | Sort X-axis by MonthStart |
| Achievement % shows 0% or blank | Target Sales blank for the selection | Check Targets loaded (192 rows) and MonthStart types are Date |
| KPI card shows a huge number | Wrong column summed (e.g. Quantity) | Re-check the measure formula in dax.md |
