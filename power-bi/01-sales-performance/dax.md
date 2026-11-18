# 01 — DAX Measures: Sales Performance

Paste each measure into the table shown. In Power BI Desktop: right-click the table in the Fields pane → **New measure** → paste the formula → press Enter. Then set the number format shown (select the measure → Measure tools → Format).

> Naming note: table and column names with spaces are written with brackets, e.g. `Sales[Order Date]`. That is valid DAX — the brackets are what allow the space.

```dax
// Total actual sales across all order lines.
// Format: Currency, 0 decimal places.
Total Sales =
SUM ( Sales[Sales] )
```

```dax
// Total target sales from the SAMPLE targets table.
// Format: Currency, 0 decimal places.
Target Sales =
SUM ( Targets[Target] )
```

```dax
// Actual as a percentage of target. 100% = exactly on target.
// DIVIDE is used instead of / so a zero or blank target returns
// BLANK instead of an error.
// Format: Percentage, 1 decimal place.
Achievement % =
DIVIDE ( [Total Sales], [Target Sales] )
```

```dax
// Dollar gap: positive = ahead of target, negative = behind.
// Format: Currency, 0 decimal places.
Variance =
[Total Sales] - [Target Sales]
```

```dax
// Sales from the start of the current month up to the latest
// date in the current filter context. TOTALMTD takes the measure
// and the date column; it needs no separate calendar table.
// Format: Currency, 0 decimal places.
MTD Sales =
TOTALMTD ( [Total Sales], Sales[Order Date] )
```

```dax
// Target for the current month, for the MTD comparison card.
// Targets are stored monthly, so the month-to-date target is
// simply the month's target total.
// Format: Currency, 0 decimal places.
MTD Target =
[Target Sales]
```

## How the measures behave with slicers

- With a **Month** slicer on `Calendar[MonthName]`, `Total Sales` and `Target Sales` both filter to that month, so `Achievement %` is that month's achievement — this is why both facts link to the same Calendar dimension.
- With a **Region** slicer on `Region[Region]`, the same logic applies per region.
- The region bar chart uses `Region[Region]` on the axis with `Total Sales` and `Target Sales` as values; any region where `Achievement %` < 100% is the one that "needs attention" and gets the red conditional formatting (see build guide).
