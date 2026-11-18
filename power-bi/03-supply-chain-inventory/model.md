# 03 — Data Model: Supply Chain / Inventory

## Tables

### Locations (dimension) — from `SAMPLE_Locations_Dimension.csv`, renamed from its file name

| Column | Type | Notes |
|---|---|---|
| LocationID | Text | **Primary key.** WH-01 … WH-08. Never null, never duplicated. |
| LocationName | Text | Warehouse 01 … Warehouse 08. |
| City | Text | Edmonton, Calgary, Vancouver, Winnipeg, Saskatoon, Toronto, Montreal, Halifax. |
| Region | Text | West / Prairies / East. |
| CapacityUnits | Whole number | Maximum units the warehouse can hold. Used for context, not for the understock flag. |

**All data in this table is SAMPLE / illustrative data.**

### Inventory (fact) — from `SAMPLE_Inventory_Fact.csv`, renamed from its file name

| Column | Type | Notes |
|---|---|---|
| Date | Date | First day of the month, Jan–Jun 2025. Monthly snapshot grain. |
| ItemID | Text | SKU-001 … SKU-020. |
| ItemName | Text | e.g. "Pallet Wrap Roll". |
| Category | Text | Packaging / Equipment / Safety / Storage / Consumables. |
| LocationID | Text | **Foreign key** to Locations[LocationID]. |
| StockLevel | Whole number | Units on hand at that location, that month. |
| ReorderPoint | Whole number | Units at/below which the item should be reordered at that location. |

**All data in this table is SAMPLE / illustrative data.**

## Relationships

| From (one side) | To (many side) | On | Cardinality | Direction |
|---|---|---|---|---|
| Locations[LocationID] | Inventory[LocationID] | LocationID | Many-to-one | Single (Locations → Inventory) |

One location row relates to 120 fact rows (20 items × 6 months). The relationship is **single-direction** so that filters on location (city, region) flow into the fact table, while fact filters do not leak back into the dimension and distort location counts.

## Star schema vs one flat table — the full argument

A flat version of this data would put City, Region, and CapacityUnits on every one of the 960 fact rows. That works until:

1. **An update is needed.** A warehouse expands from 12,000 to 15,000 capacity. Flat table: find and edit 120 rows. Star schema: edit 1 row.
2. **A location count is needed.** "How many warehouses are in the West?" Flat table: count distinct LocationIDs, remembering to deduplicate. Star schema: count rows in Locations where Region = "West".
3. **A second fact arrives.** Shipments, orders, or transfers by location all reuse the same Locations dimension. Flat table: every new extract repeats the location columns again, and they can drift out of sync.

The cost of the star schema is one relationship to create. The cost of the flat table is paid on every future change. That trade is the lesson of this project.

## Grain (what one row means)

- Locations: one row = one warehouse.
- Inventory: one row = one item's stock snapshot at one location in one month.
- Understocked, precisely defined: `StockLevel < ReorderPoint` on that row. (Equal to reorder point is not understocked — it is exactly at the trigger.)

## What is deliberately NOT in the model

- **No Items dimension.** ItemName and Category live in the fact table here to keep the beginner build to one relationship. The natural next step — an Items dimension on ItemID — is noted as a stretch goal in the build guide.
- **No daily grain.** Monthly snapshots answer "consistently understocked" without 30× the rows. Daily data would not change any conclusion in this kit.
