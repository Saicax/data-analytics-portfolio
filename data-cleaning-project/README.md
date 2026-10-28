# Data Cleaning Project — Layoffs 2022

## Question

> "This dataset was exported from three different systems and merged badly. I need one clean table I can actually trust before we build anything on top of it."

So this project is not about charts or trends. It is about **trust**: can the next analyst build on this table without repeating my mistakes? The deliverable is a clean table plus a written record of every judgment call behind it.

## Data

- **Source:** Layoffs 2022 dataset (Kaggle), 2,361 rows × 9 columns
- **Columns:** company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions
- **Coverage:** layoff events from 2020-03-11 to 2023-03-06
- **Raw file:** `data/` in the original project folder (kept untouched); the clean export is `data/cleaned_layoffs.csv`

## Process

1. **Staged, never edited raw** — `sql/01_staging.sql` loads the CSV exactly as received into `layoffs_staging`. File facts verified first: UTF-8 encoding, CRLF line endings, and missing values written as the literal string `'NULL'` (not real NULLs), which the load converts with a nested `NULLIF` pattern.
2. **Cleaned in a working copy** — `sql/02_cleaning.sql` runs the pipeline in auditable steps: TRIM → standardize → dedupe → date conversion → industry self-join fill → delete unusable rows. Each step states its row impact in its comment.
3. **Built the final table** — `sql/03_clean_table.sql` creates `layoffs_clean` and proves it with verification queries (row counts, null counts, duplicate and variant checks).
4. **Documented every decision** — `docs/decision-log.md` is the centerpiece: one entry per issue type, each with a real before-example, what was done, why that option beat the alternatives, and rows affected.

## Findings

### Before / after

| Measure | Raw | Clean | Change |
|---|---|---|---|
| Rows | 2,361 | 1,995 | −366 (−15.5%) |
| Exact duplicates | 5 | 0 | −5 |
| Industry spellings of "crypto" | 3 | 1 | −2 variants |
| Countries ending in `.` | 1 variant (4 rows) | 0 | fixed |
| Missing industry | 4 rows | 1 row | 3 filled |
| Rows with no layoff data at all | 362 | 0 | −361 |
| Date column type | text, mixed padding | real `DATE` | converted |

### What the clean table can now say (computed from `layoffs_clean`)

- **383,659 people** were laid off across the events with known headcounts.
- **2022 was the worst year**: 160,661 people across 1,030 events, ahead of 2023 (125,677 / 397) and 2020 (80,998 / 532).
- **Consumer (45,182) and Retail (43,613)** lead layoffs by industry; **Amazon (18,150), Google (12,000), and Meta (11,000)** lead by company.
- **116 events** laid off 100% of staff — full shutdowns, not data errors (see decision log, entry 15).

### What cleaning changed about the answers

- Counting the raw file would have overstated layoff events by 366 and double-counted Yahoo's 1,600-person layoff.
- Industry breakdowns on the raw file would have split crypto across three labels and parked 4 rows under a phantom "NULL" industry.
- Any date analysis on the raw file would have needed string parsing per row; the clean table's `DATE` column supports real time-series queries.

### Known limits (accepted, not hidden)

- Oda's 3 conflicting rows were kept and flagged for source verification (decision log, entry 7).
- Netflix's $121.9B "funds raised" looks like a market-cap figure under the wrong definition — flagged, not altered.
- 1 row (Bally's Interactive) still has no industry; 1 row (Blackbaud) still has no date. Both are documented, and neither blocks analysis.

## Files

| File | What it is |
|---|---|
| `sql/01_staging.sql` | Staging table + `LOAD DATA INFILE` (MySQL 8, matched to the file's real encoding/line endings) |
| `sql/02_cleaning.sql` | The full cleaning pipeline, one commented step per decision |
| `sql/03_clean_table.sql` | Final `layoffs_clean` table + verification queries |
| `data/cleaned_layoffs.csv` | The final clean table export (1,995 rows, data only) |
| `docs/decision-log.md` | The centerpiece: every issue, the choice made, why, and rows affected |

## Tools

MySQL 8 (staging, cleaning pipeline, verification), Python (independent verification of every count in this README and the decision log).
