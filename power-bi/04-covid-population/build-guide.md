# 04 — Build Guide: COVID-19 / Population Dashboard

Follow in order. Estimated time: 30–60 minutes.

## Step 1 — Import the file

1. Open Power BI Desktop.
2. **Home tab → Get data → Text/CSV** → select `data/owid_covid_extract.csv` → **Open**. Delimiter: **Comma**. Click **Transform Data**.

## Step 2 — Handle the blank new_cases in Power Query (documented decision)

1. Click the `owid_covid_extract` query.
2. Check types: `date` → Date; `total_cases`, `new_cases`, `total_deaths`, `new_deaths`, `population` → Whole Number; `new_cases_smoothed` → Decimal Number; the rest Text. Fix any wrong type (select column → **Transform tab → Data Type**).
3. **Blank new_cases (843 rows):** these are days with no report. Decision: treat a missing daily report as 0 reported that day, so trend lines stay continuous. Implement it with a custom column:
   - **Add Column tab → Custom Column.** Name: `new_cases_filled`. Formula: `if [new_cases] = null then 0 else [new_cases]`.
   - Delete the original `new_cases` column (right-click its header → **Remove**), then rename `new_cases_filled` → `new_cases` (double-click its header, or right-click → Rename).
   - Write this decision in your portfolio README later — "missing daily reports treated as 0" is exactly the kind of documented assumption interviewers ask about.
4. Sanity check: row count should read **16,188**.
5. Rename the query: right-click `owid_covid_extract` → **Rename** → `Covid`.
6. **Home tab → Close & Apply.**

## Step 3 — Set the map field's Data Category

1. In the Fields pane, click the `Covid[location]` column (or select it in Data view).
2. **Column tools tab → Data Category → Country/Region.** This tells Power BI to geocode the values as countries on the map. Without this step, the map may fail to shade or may match place names incorrectly.
3. Optional but recommended: also set `Covid[date]` → Data Category: leave as default (dates are handled automatically).

## Step 4 — Create the DAX measures

1. Right-click the `Covid` table in the Fields pane → **New measure**. Paste from `dax.md`, one at a time: `Total New Cases`, `Latest Total Cases`, `All Countries Latest Total`, `Cases per 100k`, `7-Day Avg New Cases`.
2. Set formats: whole numbers with thousands separators for the case-count measures; 1 decimal place for `Cases per 100k` and `7-Day Avg New Cases`.
3. Sanity check: a Card with `All Countries Latest Total` (no slicer selected) should read a large 8-figure number (tens of millions of cumulative cases across the 10 countries). If it reads in the billions, you summed a cumulative column somewhere — re-check the measure formulas.

## Step 5 — Build the report page

Create one page named "COVID-19 by Country".

### Visual 1 — Filled map (the centerpiece)
- **Visualizations pane → Filled map.** (If you do not see it, it is under "Maps" — you may need an internet connection; Power BI geocodes via Bing Maps.)
- Location: `Covid[location]`. Tooltips: `Cases per 100k` and `Latest Total Cases`.
- **Color saturation:** drag `Cases per 100k` into the "Color saturation" well — darker shading = higher case rate. Format visual → Fill colors → pick a single-hue sequential scheme (light-to-dark red is the convention for case rates).
- If a country does not shade: check Step 3 (Data Category) and your internet connection. The bar chart below still answers the question, so a map gap is not a blocker.

### Visual 2 — Date-range slicer (top of page)
- **Visualizations pane → Slicer.** Field: `Covid[date]`.
- In the slicer header, change the style to **Between** (the slider). You should see a range slider from Mar 2020 to Aug 2024.
- Test: drag the slider to 2020 only — the map, trend line, and bar chart should all re-filter to 2020.

### Visual 3 — Trend line
- **Visualizations pane → Line chart.**
- X-axis: `Covid[date]`. Y-axis: `7-Day Avg New Cases`. Legend: `Covid[location]`.
- With all countries selected this is busy (10 lines) — that is fine, and it demonstrates the next interaction: click one country in the legend or bar chart to cross-filter the line to that country alone.

### Visual 4 — Country comparison bar chart
- **Visualizations pane → Clustered bar chart.**
- Y-axis: `Covid[location]`. X-axis: `Cases per 100k`. Sort descending.
- This is the ranking the map shows geographically; the two visuals should tell the same story in different forms.

### KPI cards (top row)
- **Card** with `All Countries Latest Total` ("Total cases, latest").
- **Card** with `Total New Cases` ("New cases in selected period" — this one moves with the date slicer, which is a nice demo).

## Step 6 — Final formatting pass

1. **Titles:** "COVID-19 Case Rate by Country", "7-Day Average New Cases", "Cases per 100k by Country".
2. **Map note:** add a Text box under the map: "Source: Our World in Data, COVID-19 dataset (downloaded Oct 2025, 10 countries, Mar 2020 – Aug 2024). Missing daily reports treated as 0." Source notes on the report itself are professional practice.
3. **Save:** File → Save As → `Covid_Population_Dashboard.pbix`. This `.pbix` is YOUR file, built by you — it is not part of this kit.

## Common mistakes and fixes

| Symptom | Cause | Fix |
|---|---|---|
| Map is blank or countries don't shade | No internet, or Data Category not set | Step 3; check connection; fall back to the bar chart |
| Case totals in the billions | Summed a cumulative column | Use Latest Total Cases, never SUM(total_cases) |
| Cases per 100k looks absurdly small | Summed population across dates | Use MAX(population), per dax.md |
| Trend line has gaps | Blank new_cases not filled | Step 2.3 custom column |
| Date slicer shows a list, not a slider | Slicer style defaulted to List | Change slicer style to Between |

## Stretch goal (for the portfolio write-up)

Build a **Countries dimension**: in Power Query, reference the Covid query, keep only `iso_code`, `location`, `continent`, `population`, remove duplicates → name it `Countries`, relate `Countries[iso_code]` → `Covid[iso_code]`. Population then lives in one row per country, the MAX-vs-SUM trap disappears, and the model matches the star-schema pattern from project 03.
