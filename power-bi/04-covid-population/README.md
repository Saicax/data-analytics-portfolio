# 04 — COVID-19 / Population Dashboard

> **Finished dashboard included:** `Covid_Population_Dashboard.pbix` — open it in Power BI Desktop. The kit below (prepared data, data model, written-out DAX measures, click-by-click build guide) shows how it was built.

## Business question

> "Build something that lets someone compare case rates or population trends across countries/regions on a map, filterable by date range."

This dashboard is deliberately simple everywhere except the two skills it exists to teach: **map visuals** and **date-range slicers**. Everything else — one table, a handful of measures — stays out of the way.

## Data — real public data

| File | Rows | What it is |
|---|---|---|
| `data/owid_covid_extract.csv` | 16,188 | **Real data** from Our World in Data (OWID), COVID-19 dataset. Downloaded 2026-10-25 from the OWID GitHub repository (`owid-covid-data.csv`, raw file) and filtered to 10 countries and to dates from 2020-03-01 onward. Countries: Australia, Brazil, Canada, Germany, India, Japan, Philippines, South Africa, United Kingdom, United States. Date range: 2020-03-01 to 2024-08-12 (OWID's series ends in August 2024 — later dates do not exist in this source). |

### Columns
- `iso_code` — ISO country code (AUS, BRA, CAN, DEU, IND, JPN, PHL, ZAF, GBR, USA).
- `continent` — continent name.
- `location` — country name. This is the map field.
- `date` — day (YYYY-MM-DD). This is the slicer field.
- `total_cases` — cumulative confirmed cases up to that date.
- `new_cases` — new confirmed cases that day.
- `new_cases_smoothed` — 7-day smoothed new cases (provided by OWID).
- `total_deaths`, `new_deaths` — cumulative and daily deaths.
- `population` — country population (constant per country, repeated on every row — see the model note about MAX vs SUM).

### Known data-quality notes (handled/documented in the build guide)
- **843 rows have blank `new_cases`** (days with no report). Decision documented in the build guide: treat blanks as 0 reported that day, via a Power Query step, so trend lines stay continuous. This is a documented assumption, not a hidden fix.
- **`population` repeats on every row** for a country. Never SUM it across dates (that would multiply-count the population). The DAX uses MAX for population — see `dax.md`.
- **`total_cases` is cumulative.** Never SUM it across dates either — the "latest total" measure uses MAX at the latest date.

## Data model

See `model.md`. One table, `Covid`, no relationships. The model note that matters: which columns are safe to sum (daily flows: new_cases, new_deaths) versus which must use MAX-at-latest-date (cumulative stocks: total_cases) or MAX (population).

## DAX

See `dax.md`. The measures you will create:

| Measure | Purpose |
|---|---|
| `Total New Cases` | Sum of daily new cases in the selected period |
| `Latest Total Cases` | Cumulative total at the latest date in context (per country) |
| `All Countries Latest Total` | Sum of each country's latest total |
| `Cases per 100k` | New cases per 100,000 people (period total ÷ population) |
| `7-Day Avg New Cases` | Rolling 7-day average of daily new cases |

## Visuals (what you will build)

1. **Filled map:** countries shaded by Cases per 100k (darker = higher rate). This is the centerpiece.
2. **Date-range slicer:** a Between slider on `date` — drag it and the map, trend line, and bar chart all re-filter.
3. **Trend line:** 7-Day Avg New Cases by date, one line per country (legend = location) — or a single line for the country selected in the slicer.
4. **Country comparison bar chart:** Cases per 100k by country, sorted descending.

## What you will see when you build it

No screenshots or result figures are included in this kit (nothing here was rendered in Power BI). What you should expect: with the full date range selected, the United States and Brazil show the largest absolute case counts, while cases *per 100k* reorder the ranking (small-population countries rank higher than their absolute counts suggest) — that contrast is the reason the per-100k measure exists. The map needs an internet connection (Power BI geocodes through Bing Maps); if a country does not shade, check the Data Category setting in the build guide. If the map is blank, the bar chart still answers the same question.

## How to build it

Follow `build-guide.md` step by step: import → Power Query null handling → Data Category setting → DAX measures → visuals → formatting. Estimated time: 30–60 minutes.
