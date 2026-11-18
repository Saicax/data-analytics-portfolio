# 05 — DAX Measures: Capstone

Paste each measure into the `Sales` table. In Power BI Desktop: right-click the table in the Fields pane → **New measure** → paste → press Enter. Then set the number format shown.

```dax
// Total sales across all order lines.
// Format: Currency, 0 decimal places.
Total Sales =
SUM ( Sales[Sales] )
```

```dax
// Total profit across all order lines. Includes negative-profit
// rows — they are real and must stay in the total.
// Format: Currency, 0 decimal places.
Total Profit =
SUM ( Sales[Profit] )
```

```dax
// Overall profitability: profit as a share of sales.
// DIVIDE returns BLANK instead of an error if sales are ever 0.
// Format: Percentage, 1 decimal place.
Profit Margin =
DIVIDE ( [Total Profit], [Total Sales] )
```

```dax
// How many distinct products lose money in total (across the
// current filter context). VALUES gives the distinct product
// names; FILTER keeps only those whose total profit is negative.
// Format: Whole number.
Loss-Making Products =
COUNTROWS (
    FILTER (
        VALUES ( Sales[Product Name] ),
        [Total Profit] < 0
    )
)
```

```dax
// Total profit contributed by loss-making products only.
// SUMX iterates the loss-making products and adds each one's
// profit (all negative), so the result is a negative number:
// the size of the bleed.
// Format: Currency, 0 decimal places.
Loss Amount =
SUMX (
    FILTER (
        VALUES ( Sales[Product Name] ),
        [Total Profit] < 0
    ),
    [Total Profit]
)
```

## How the measures are used in the visuals

- **KPI cards:** `Total Sales`, `Total Profit`, `Profit Margin`, `Loss Amount`. With no slicer selected, these read ≈ $2,297,201 / $286,397 / 12.5% / −$77,068 (299 loss-making products — not 301: two products sum to exactly $0.00 and only float dust makes them look negative).
- **Sub-category bar chart:** `Sales[Sub-Category]` on the axis, `Total Profit` as values. Tables will extend below zero — that negative bar is the headline visual.
- **Region bar chart:** `Sales[Region]` on the axis, `Total Profit` as values, plus `Profit Margin` as a tooltip or second visual.
- **Worst products table:** `Sales[Product Name]`, `Total Sales`, `Total Profit`, filtered to `Total Profit` < 0 and sorted by `Total Profit` ascending (worst first).
