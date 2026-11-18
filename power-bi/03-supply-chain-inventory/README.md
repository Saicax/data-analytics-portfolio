# 03 — Supply Chain / Inventory Dashboard

> **Finished dashboard included:** `Supply_Chain_Inventory_Dashboard.pbix` — open it in Power BI Desktop. The kit below (prepared data, data model, written-out DAX measures, click-by-click build guide) shows how it was built.

## Business question

> "I need to see which warehouse locations are consistently understocked so we can rebalance inventory between them."

This dashboard answers one thing, three ways:
1. **Which locations** are understocked (stock below reorder point)?
2. **How consistently** — a one-month dip is noise; understocked in most months is a structural problem.
3. **What to rebalance** — which locations hold surplus of the same items.

## Data

| File | Rows | What it is |
|---|---|---|
| `data/SAMPLE_Inventory_Fact.csv` | 960 | **SAMPLE / illustrative data.** Monthly stock snapshots: 20 items × 8 warehouse locations × 6 months (Jan–Jun 2025). Columns: Date, ItemID, ItemName, Category, LocationID, StockLevel, ReorderPoint. |
| `data/SAMPLE_Locations_Dimension.csv` | 8 | **SAMPLE / illustrative data.** One row per warehouse: LocationID, LocationName, City, Region, CapacityUnits. |

All data in this project is synthetic, made for this portfolio project. It is not a real company's inventory.

### Built-in story (so the dashboard has a real finding)
Two locations are **understocked on every single item-month in the data** — WH-03 (Vancouver) and WH-07 (Montreal), 120/120 rows below reorder point each. The other six locations sit at 4–12% of rows below reorder point (normal operational noise). When you build the ranking visual, WH-03 and WH-07 will stand out immediately — that is the "consistently understocked" pattern the client asked about, and the rebalancing conversation starts with them.

## Data model — the point of this project

See `model.md` for the full documentation. The headline: this is a **star schema with one dimension and one fact**:

- `Locations[LocationID]` (one side) → `Inventory[LocationID]` (many side), many-to-one, single direction.

Why this beats one flat table (the lesson this project exists to teach):
- **One place for location facts.** City, region, and capacity live in one row per warehouse. In a flat table they would repeat on all 120 rows per location — and the first time a warehouse's capacity changed, you would have to update 120 rows and hope you caught them all.
- **Clean location-level analysis.** Counting locations, averaging capacity, or ranking locations is trivial against the dimension; against a flat table every such calculation must deduplicate first.
- **Room to grow.** A second fact (say, shipments) can plug into the same Locations dimension later without restructuring anything.

## DAX

See `dax.md`. The measures you will create:

| Measure | Purpose |
|---|---|
| `Total Stock` | Sum of StockLevel |
| `Total Reorder Point` | Sum of ReorderPoint |
| `Understocked Flag` | "Understocked" when stock < reorder point in the current context |
| `Understocked Item-Locations` | Count of fact rows below reorder point |
| `% Locations Understocked` | Share of locations currently understocked |
| `Months Understocked` | How many months a location was understocked (the "consistency" measure) |

## Visuals (what you will build)

1. **Understocked locations table:** Location, City, Region, Total Stock, Total Reorder Point, Understocked Flag, Months Understocked — sorted by Months Understocked descending. WH-03 and WH-07 sit at the top with 6/6 months.
2. **Stock vs reorder point (clustered column chart):** by location, with the two bars side by side — any location whose stock bar is shorter than its reorder bar is understocked.
3. **Location ranking (bar chart):** % of item-months understocked by location — the "map-style ranking" of the brief, in bar form (a true filled map needs geographic coordinates; the bar ranking answers the same question without them).
4. **Slicers:** Month, Region, Category.

## What you will see when you build it

No screenshots or result figures are included in this kit (nothing here was rendered in Power BI). What you should expect: WH-03 (Vancouver) and WH-07 (Montreal) flagged in every month, the other locations mostly OK, and the ranking chart showing those two at 100% versus 4–12% for the rest. If every location shows 100%, check that the relationship runs Locations → Inventory (not the reverse) and that StockLevel and ReorderPoint are numbers, not text.

## How to build it

Follow `build-guide.md` step by step: import → Power Query type check → Model view relationship → DAX measures → visuals → formatting. Estimated time: 30–60 minutes.
