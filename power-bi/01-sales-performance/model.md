# 01 — Data Model: Sales Performance

## Tables

### Sales (fact) — from `superstore.csv`, renamed from "superstore" in Power Query

| Column | Type | Notes |
|---|---|---|
| Row ID | Whole number | Row identifier from the export. Not used in visuals. |
| Order ID | Text | Order identifier. One order can have many lines — do NOT deduplicate on this. |
| Order Date | Date | Converted from text (M/D/YYYY) in Power Query. |
| Ship Date | Date | Converted from text (M/D/YYYY) in Power Query. |
| Ship Mode | Text | e.g. Standard Class, Second Class. |
| Customer ID / Customer Name | Text | |
| Segment | Text | Consumer / Corporate / Home Office. |
| Country / City / State | Text | Country is United States throughout. |
| Postal Code | Text | Keep as text (leading zeros matter). 11 blanks — leave blank. |
| Region | Text | Central / East / South / West. Key to DimRegion. |
| Product ID / Product Name | Text | |
| Category / Sub-Category | Text | |
| Sales | Decimal number | Converted from text in Power Query. |
| Quantity | Whole number | |
| Discount | Decimal number | 0–0.8. |
| Profit | Decimal number | Converted from text in Power Query. Can be negative. |
| **MonthStart (calculated in Power Query)** | **Date** | `Date.StartOfMonth([Order Date])`. Key to DimCalendar. This is what lets monthly targets join to daily orders. |

### Targets (fact) — from `SAMPLE_Targets_by_Region_Month.csv`, renamed from its file name

| Column | Type | Notes |
|---|---|---|
| Region | Text | Key to DimRegion. |
| Year | Whole number | |
| Month | Whole number | 1–12. |
| MonthStart | Date | First day of the month. Key to DimCalendar. |
| Target | Decimal number | **SAMPLE data — hypothetical monthly target.** |

### Calendar (dimension) — from `DimCalendar.csv`

| Column | Type | Notes |
|---|---|---|
| MonthStart | Date | **Primary key.** One row per month, 2015-01-01 to 2018-12-01. |
| Year | Whole number | |
| Month | Whole number | |
| MonthName | Text | e.g. "January 2015". Use on chart axes. |

### Region (dimension) — from `DimRegion.csv`

| Column | Type | Notes |
|---|---|---|
| Region | Text | **Primary key.** Central, East, South, West. |

## Relationships

All relationships are **single-direction** (filter flows from dimension to fact) and **many-to-one** (one dimension row → many fact rows):

| From (one side) | To (many side) | On | Why |
|---|---|---|---|
| Calendar[MonthStart] | Sales[MonthStart] | MonthStart | Monthly slicing of daily orders |
| Calendar[MonthStart] | Targets[MonthStart] | MonthStart | Monthly slicing of targets |
| Region[Region] | Sales[Region] | Region | Regional slicing of orders |
| Region[Region] | Targets[Region] | Region | Regional slicing of targets |

## Why this shape (star schema) and not one flat table

- **One pair of slicers drives everything.** A Year/Month/Region slicer built on the dimensions filters both Sales and Targets at once, so "actual vs target" always compares the same period and region.
- **No duplication.** Region names and month labels live in one place each. If a region were renamed, you would edit one row, not 10,000.
- **No fan-out errors.** Joining Sales directly to Targets on Region alone would be many-to-many (many order lines per region × 48 target rows per region) and would inflate totals. The shared dimensions avoid that entirely.

## Grain (what one row means)

- Sales: one row = one product line on one order.
- Targets: one row = one region's target for one month.
- Calendar: one row = one month.
- Region: one row = one region.
