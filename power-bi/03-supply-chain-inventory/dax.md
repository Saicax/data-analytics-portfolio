# 03 — DAX Measures: Supply Chain / Inventory

Paste each measure into the table shown. In Power BI Desktop: right-click the table in the Fields pane → **New measure** → paste → press Enter. Then set the number format shown.

```dax
// Total units on hand in the current filter context.
// Format: Whole number, thousands separator.
Total Stock =
SUM ( Inventory[StockLevel] )
```

```dax
// Total reorder-point units in the current filter context.
// Format: Whole number, thousands separator.
Total Reorder Point =
SUM ( Inventory[ReorderPoint] )
```

```dax
// Row-context flag for table visuals: in a visual grouped by
// location (or location + month), this compares that group's
// stock against its reorder point.
// Format: Text.
Understocked Flag =
IF (
    [Total Stock] < [Total Reorder Point],
    "Understocked",
    "OK"
)
```

```dax
// Count of fact rows (item-location-months) below reorder point.
// FILTER iterates the fact table row by row; the comparison is
// per row, which is the correct grain for "how many rows are
// understocked". Use it for totals, not for per-location flags.
// Format: Whole number.
Understocked Item-Locations =
COUNTROWS (
    FILTER (
        Inventory,
        Inventory[StockLevel] < Inventory[ReorderPoint]
    )
)
```

```dax
// Share of locations that are understocked in the current
// context. VALUES gives the distinct locations; FILTER keeps
// only those where stock < reorder point (CALCULATE performs
// the context transition so the sums are per location).
// Format: Percentage, 1 decimal place.
% Locations Understocked =
DIVIDE (
    COUNTROWS (
        FILTER (
            VALUES ( Locations[LocationID] ),
            CALCULATE ( SUM ( Inventory[StockLevel] ) )
                < CALCULATE ( SUM ( Inventory[ReorderPoint] ) )
        )
    ),
    COUNTROWS ( VALUES ( Locations[LocationID] ) )
)
```

```dax
// THE CONSISTENCY MEASURE. For each location, how many distinct
// months was it understocked? A location at 6/6 months is a
// structural problem; a location at 1/6 had a bad month.
// Use it in a visual grouped by location.
// Format: Whole number.
Months Understocked =
COUNTROWS (
    FILTER (
        VALUES ( Inventory[Date] ),
        CALCULATE ( SUM ( Inventory[StockLevel] ) )
            < CALCULATE ( SUM ( Inventory[ReorderPoint] ) )
    )
)
```

## How to read the measures together

- A location table with `Months Understocked` sorted descending is the rebalancing shortlist: WH-03 and WH-07 will read **6**, the rest **0–1**.
- `% Locations Understocked` as a KPI card reads **25%** (2 of 8 locations) when no month is selected — the headline number for the dashboard.
- `Understocked Item-Locations` (300 in this data: 120 + 120 for WH-03 and WH-07, plus 60 scattered rows elsewhere) is the detailed count behind the headline; use it in the table footer or a tooltip, not as the headline, because it counts item-months, not locations.
