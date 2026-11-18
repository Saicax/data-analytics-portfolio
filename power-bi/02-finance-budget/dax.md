# 02 — DAX Measures: Finance / Budget

Paste each measure into the `Spending` table. In Power BI Desktop: right-click the table in the Fields pane → **New measure** → paste → press Enter. Then set the number format shown.

```dax
// Total spending in the current filter context.
// Format: Currency, 0 decimal places.
Total Spend =
SUM ( Spending[Amount] )
```

```dax
// The same total, but for the previous calendar month.
// DATEADD shifts the dates in the current filter context back
// by 1 month; CALCULATE then re-evaluates Total Spend there.
// The first month in the data (Jan 2024) has no previous month,
// so this correctly returns BLANK there.
// Format: Currency, 0 decimal places.
Previous Month Spend =
CALCULATE (
    [Total Spend],
    DATEADD ( Spending[Date], -1, MONTH )
)
```

```dax
// Month-over-month change as a percentage.
// DIVIDE avoids a divide-by-zero error when the previous month
// is blank (first month) or zero.
// Format: Percentage, 1 decimal place.
MoM % Change =
DIVIDE (
    [Total Spend] - [Previous Month Spend],
    [Previous Month Spend]
)
```

```dax
// The 20% rule, in exactly one place. Any category-month whose
// MoM increase exceeds 20% is flagged; everything else is OK.
// Change the 0.2 here and the whole dashboard's flagging changes.
// Format: Text (no number format needed).
MoM Flag =
IF (
    [MoM % Change] > 0.2,
    "FLAGGED",
    "OK"
)
```

## Alternative worth knowing: PREVIOUSMONTH

The same result can be written with `PREVIOUSMONTH` instead of `DATEADD`:

```dax
// Equivalent to Previous Month Spend above.
Previous Month Spend (PREVIOUSMONTH version) =
CALCULATE (
    [Total Spend],
    PREVIOUSMONTH ( Spending[Date] )
)
```

Both are valid. `DATEADD` is used as the main version because it generalizes (change `-1, MONTH` to `-1, QUARTER` or `-1, YEAR` and the logic follows). `PREVIOUSMONTH` is the more readable shortcut for exactly this case. Do not create both — pick one.

## How the flag table works

A table visual with `Category`, `Date`, `Total Spend`, `Previous Month Spend`, `MoM % Change`, `MoM Flag` — filtered (Filters pane, "Filter on this visual") to `MoM Flag` = "FLAGGED" — shows only the jumps. The `MoM Flag` measure is evaluated in each row's context (that category, that month), which is why the flag is correct per category rather than for total spending.
