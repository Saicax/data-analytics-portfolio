# 04 — Data Model: COVID-19 / Population

## Tables

### Covid (fact) — from `owid_covid_extract.csv`, renamed from its file name

| Column | Type | Notes |
|---|---|---|
| iso_code | Text | ISO country code. |
| continent | Text | |
| location | Text | Country name. **Map field — set Data Category to "Country/Region"** (see build guide). |
| date | Date | Day, 2020-03-01 to 2024-08-12. **Slicer field.** |
| total_cases | Whole number | **Cumulative.** Do NOT sum across dates. |
| new_cases | Whole number | Daily flow. Safe to sum. Blanks replaced with 0 in Power Query (documented decision). |
| new_cases_smoothed | Decimal number | OWID's 7-day smoothed daily cases. Provided by the source; useful for cross-checking the DAX 7-day average. |
| total_deaths | Whole number | **Cumulative.** Do NOT sum across dates. |
| new_deaths | Whole number | Daily flow. Safe to sum. |
| population | Whole number | **Constant per country, repeated on every row.** Do NOT sum across dates — use MAX. |

**Source: Our World in Data, COVID-19 dataset, downloaded 2026-10-25, filtered to 10 countries and dates from 2020-03-01.**

## Relationships

None. One table, no dimensions. A Countries dimension (one row per country, with population) is the natural next improvement — it would remove the repeated population column entirely — and is noted as a stretch goal in the build guide.

## The three aggregation rules (the model lesson of this project)

| Column kind | Example | Correct aggregation | Why |
|---|---|---|---|
| Daily flow | new_cases, new_deaths | SUM | Each row is one day's new amount; totals add up. |
| Cumulative stock | total_cases, total_deaths | MAX at the latest date | Each row already includes all previous days; summing would count every case hundreds of times. |
| Constant attribute | population | MAX | The same number repeats on every row; summing would multiply the population by the number of days. |

Getting these three rules right is most of the analytical work in any time-series dashboard. The DAX in `dax.md` implements exactly these rules.

## Grain (what one row means)

One row = one country's COVID numbers on one day. 16,188 rows = 10 countries × ~1,619 days each.
