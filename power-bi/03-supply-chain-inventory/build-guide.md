# 03 — Build Guide: Supply Chain / Inventory Dashboard

Follow in order. Estimated time: 30–60 minutes.

## Step 1 — Import the two files

1. Open Power BI Desktop.
2. **Home tab → Get data → Text/CSV** → select `data/SAMPLE_Locations_Dimension.csv` → **Open** → **Transform Data**.
3. **Home tab → Get data → Text/CSV** → select `data/SAMPLE_Inventory_Fact.csv` → **Open** → **Transform Data**.

## Step 2 — Check types in Power Query

1. Click the `SAMPLE_Locations_Dimension` query. Verify: `LocationID`, `LocationName`, `City`, `Region` are Text; `CapacityUnits` is Whole Number. Fix any wrong type (select column → **Transform tab → Data Type**).
2. Click the `SAMPLE_Inventory_Fact` query. Verify: `Date` is Date; `ItemID`, `ItemName`, `Category`, `LocationID` are Text; `StockLevel`, `ReorderPoint` are Whole Number. Fix any wrong type.
3. Sanity checks: Locations should read **8 rows**; Inventory should read **960 rows** (20 items × 8 locations × 6 months).
4. Rename: `SAMPLE_Locations_Dimension` → `Locations`; `SAMPLE_Inventory_Fact` → `Inventory`.
5. **Home tab → Close & Apply.**

## Step 3 — Build the relationship (Model view)

1. Click the **Model view** icon (diagram icon, left rail).
2. Drag `Locations[LocationID]` onto `Inventory[LocationID]`.
3. The line should show **1** on the Locations end and **\*** on the Inventory end, arrow pointing toward Inventory.
4. If it shows many-to-many, the LocationIDs do not match exactly (check for trailing spaces in Power Query: select `LocationID` in both queries → **Transform tab → Format → Trim**).
5. Do NOT add any other relationship. One line is the whole model — that is the point.

## Step 4 — Create the DAX measures

1. Right-click the `Inventory` table in the Fields pane → **New measure**. Paste from `dax.md`:
   - `Inventory` table: `Total Stock`, `Total Reorder Point`, `Understocked Item-Locations`
   - `Locations` table: `Understocked Flag`, `% Locations Understocked`, `Months Understocked`
   (Measures can live in either table; placing location-level measures in Locations keeps the Fields pane readable.)
2. Set formats: whole numbers with thousands separators for the stock measures; percentage (1 decimal) for `% Locations Understocked`.
3. Sanity check: a Card with `% Locations Understocked` should read **25.0%** (2 of 8 locations) with no slicer selected. If it reads 100%, the relationship direction is reversed — go back to Step 3.

## Step 5 — Build the report page

Create one page named "Supply Chain / Inventory".

### Visual 1 — Understocked locations table (the answer)
- **Visualizations pane → Table.**
- Columns, in order: `Locations[LocationName]`, `Locations[City]`, `Locations[Region]`, `Total Stock`, `Total Reorder Point`, `Understocked Flag`, `Months Understocked`.
- **Sort:** click the `Months Understocked` column header until it sorts descending. WH-03 (Vancouver) and WH-07 (Montreal) should sit at the top with **6** months; the rest read 0.
- **Conditional formatting:** select the table → Format visual → Cell elements → `Understocked Flag` → Background color → **fx** → Rules: "If value = Understocked, light red; if value = OK, light green".

### Visual 2 — Stock vs reorder point (clustered column chart)
- **Visualizations pane → Clustered column chart.**
- X-axis: `Locations[LocationName]`. Y-axis: `Total Stock` and `Total Reorder Point`.
- Read it: any location whose stock column is shorter than its reorder column is understocked. WH-03 and WH-07 will show this clearly.

### Visual 3 — Location ranking (bar chart)
- **Visualizations pane → Clustered bar chart.**
- Y-axis: `Locations[LocationName]`. X-axis: `Understocked Item-Locations`.
- Sort descending. This is the "which location is worst" ranking: WH-03 and WH-07 at 120 each, the rest at 5–14.
- Note for the portfolio write-up: a true filled map visual needs latitude/longitude or Bing-recognized regions; with 8 warehouses the bar ranking answers the client's question more precisely than a map would. If you want the map anyway, add a Filled map with `Locations[City]` — Power BI will geocode Canadian cities — and color it by `Understocked Item-Locations`.

### KPI card (top of page)
- **Card** with `% Locations Understocked` — the headline: "25% of locations understocked".

### Slicers
- **Slicer** → `Inventory[Date]` (Between slider style) — pick a single month and watch the table update; WH-03 and WH-07 stay flagged in every month, which is exactly the "consistently" test.
- **Slicer** → `Locations[Region]`, buttons.
- **Slicer** → `Inventory[Category]`, dropdown — so the team can check whether the problem is one product category or everything.

## Step 6 — Final formatting pass

1. **Titles:** "Understocked Locations — Ranked by Months Understocked", "Stock vs Reorder Point by Location", "Understocked Item-Months by Location".
2. **Save:** File → Save As → `Supply_Chain_Inventory_Dashboard.pbix`. This `.pbix` is YOUR file, built by you — it is not part of this kit.

## Common mistakes and fixes

| Symptom | Cause | Fix |
|---|---|---|
| Every location shows Understocked | Relationship reversed or StockLevel imported as text | Step 3 direction; Step 2 types |
| Months Understocked is 0 for WH-03/WH-07 | Measure placed in the wrong table or used without a location grouping | Put it in the Locations table; use it in a visual grouped by location |
| % Locations Understocked reads 100% | Filter context includes only understocked rows (e.g. a visual-level filter) | Remove visual-level filters when testing the KPI card |
| Location names show as codes (WH-01) | LocationName column not used | Use LocationName/City in visuals, keep LocationID for the relationship only |

## Stretch goal (for the portfolio write-up)

Add an **Items dimension**: in Power Query, create a reference query from Inventory, keep only `ItemID`, `ItemName`, `Category`, remove duplicates → name it `Items`, relate `Items[ItemID]` → `Inventory[ItemID]`. You now have a two-dimension star schema (Locations + Items), and the same "one place for facts" argument applies to product names and categories.
