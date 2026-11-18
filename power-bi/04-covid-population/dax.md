# 04 — DAX Measures: COVID-19 / Population

Paste each measure into the `Covid` table. In Power BI Desktop: right-click the table in the Fields pane → **New measure** → paste → press Enter. Then set the number format shown.

```dax
// Total new cases in the selected period and countries.
// new_cases is a daily flow, so SUM is correct.
// Format: Whole number, thousands separator.
Total New Cases =
SUM ( Covid[new_cases] )
```

```dax
// Cumulative total cases at the latest date in context.
// total_cases is cumulative, so MAX at the latest date is the
// correct reading — never SUM this column across dates.
// In a visual grouped by country, this gives each country's
// latest total.
// Format: Whole number, thousands separator.
Latest Total Cases =
CALCULATE (
    MAX ( Covid[total_cases] ),
    LASTDATE ( Covid[date] )
)
```

```dax
// Sum of every country's latest total — the all-countries KPI.
// SUMX iterates each country and adds its own latest total.
// Format: Whole number, thousands separator.
All Countries Latest Total =
SUMX (
    VALUES ( Covid[location] ),
    CALCULATE (
        MAX ( Covid[total_cases] ),
        LASTDATE ( Covid[date] )
    )
)
```

```dax
// New cases per 100,000 people in the selected period.
// MAX(population) is correct because population is constant
// per country — SUM would multiply-count it across dates.
// In a visual grouped by country, MAX returns that country's
// population.
// Format: Decimal number, 1 decimal place.
Cases per 100k =
DIVIDE ( [Total New Cases], MAX ( Covid[population] ) ) * 100000
```

```dax
// Rolling 7-day average of daily new cases, ending at the
// latest date in context. DATESINPERIOD returns the 7 days
// ending at MAX(date) (-6 days back, inclusive = 7 days);
// AVERAGEX averages the daily totals across those days.
// Format: Decimal number, 1 decimal place.
7-Day Avg New Cases =
AVERAGEX (
    DATESINPERIOD ( Covid[date], MAX ( Covid[date] ), -6, DAY ),
    [Total New Cases]
)
```

## How the measures behave with the date slicer

- Dragging the date-range slicer changes the filter context, so `Total New Cases` re-sums only the selected days, `Cases per 100k` re-rates for that window, and the map re-shades. That is the whole interaction the client asked for.
- `Latest Total Cases` follows the slicer's *end* date (LASTDATE), so narrowing the range to 2020 shows early-pandemic totals — a good demo of what the measure actually does.
