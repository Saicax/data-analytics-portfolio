# Decision Log — Layoffs 2022 Data Cleaning

> **Why this document exists.** The client brief was: *"This dataset was exported from three different systems and merged badly. I need one clean table I can actually trust before we build anything on top of it."*
> Cleaning is mostly judgment calls. Every call below states **what I found** (with a real example from the file), **what I did**, **why I chose that over the alternatives**, and **how many rows it affected**. All counts were computed from the actual CSV, not estimated.

## Before / after summary

| Stage | Rows | Change |
|---|---|---|
| Raw load (`layoffs_staging`) | 2,361 | — |
| After removing exact duplicates | 2,356 | −5 |
| After deleting both-null layoff rows | **1,995** | −361 |
| Final clean table (`layoffs_clean`) | **1,995** | **−366 total (−15.5%)** |

Value fixes (no row removed): 11 whitespace trims, 9 company-casing fixes, 3 industry-variant fixes, 4 country-variant fixes, 3 industries filled, 2,360 dates converted to real `DATE`.

---

## 1. Missing values written as the literal string `NULL`

**Found:** The file does not use empty cells for missing data. It writes the four characters `NULL`, e.g. `Casper,New York City,Retail,NULL,NULL,9/14/2021,Post-IPO,United States,339`. A few cells are genuinely blank instead (e.g. Airbnb's industry is an empty string, not `NULL`).

**Did:** At load time, every numeric column passes through a nested `NULLIF` — first `''` → `NULL`, then `'NULL'` → `NULL` (`sql/01_staging.sql`). Text columns are normalized the same way in the cleaning step.

**Why this over the alternatives:**
- *Leaving the string in place* would have been the worst option: `GROUP BY industry` would create a phantom industry called "NULL", and MySQL strict mode throws Error 1366 when the string hits an `INT` column.
- *Replacing with 0* would be fabrication: a company with unknown layoffs is not a company with zero layoffs, and 0s would corrupt every average and total downstream.
- Real SQL `NULL` means "unknown", which is exactly what the source systems meant.

**Affected:** 740 `total_laid_off`, 785 `percentage_laid_off`, 209 `funds_raised_millions`, 4 `industry`, 6 `stage`, 1 `date` cells at load.

## 2. Leading / trailing whitespace in company names

**Found:** 11 company cells carry stray spaces, e.g. `'WeWork '` (twice), `' Included Health'`, `' E Inc.'`, `'Science 37 '`, `'Captain Fresh '`.

**Did:** `TRIM()` on every text column before anything else (`02_cleaning.sql`, Step 1).

**Why first:** Dedupe and `GROUP BY company` both depend on exact string equality. Trimming after dedupe would have left `'WeWork '` and `'WeWork'` as two different companies and missed duplicate matches. Whitespace is never meaningful data in a company name, so there is no trade-off here — it is always safe to strip.

**Affected:** 11 cells.

## 3. Company names in two casings

**Found:** Five companies appear in two casings, a classic two-systems symptom:

| Lower-cased form | Rows as written |
|---|---|
| SalesLoft | `Salesloft` ×1, `SalesLoft` ×1 |
| AppGate | `Appgate` ×1, `AppGate` ×1 |
| ClearCo | `Clearco` ×3, `ClearCo` ×1 |
| ByteDance | `Bytedance` ×3, `ByteDance` ×1 |
| CureFit | `Curefit` ×1, `CureFit` ×1 |

**Did:** Standardized to the established brand spelling (the camelCase form) with an explicit `CASE` mapping.

**Why this over the alternatives:**
- *Lowercasing everything* would have "worked" mechanically but destroyed real brand spellings (`ByteDance` is a name, not a typo).
- *Leaving both forms* would split each company's history across two groups in any company-level analysis.
- Trade-off acknowledged: I am assuming the camelCase form is the correct brand spelling. If one is wrong, the damage is cosmetic only — company is a label in this dataset, not a join key.

**Affected:** 9 rows re-spelled.

## 4. Industry spelled three ways: Crypto / Crypto Currency / CryptoCurrency

**Found:** `Crypto` (99 rows), `Crypto Currency` (2 rows), `CryptoCurrency` (1 row) — three labels for one industry.

**Did:** Mapped both variants to `Crypto`.

**Why:** There is no meaningful distinction between these labels in this dataset (no definition distinguishes "Crypto Currency" companies from "Crypto" companies), and splitting them would undercount crypto layoffs by 3 events in industry breakdowns. `Crypto` was chosen because it is the dominant form (99 of 102 rows), not because it is "more correct".

**Affected:** 3 rows.

## 5. Country with a trailing period: `United States.`

**Found:** 4 rows say `United States.` (with a period); 1,541 rows say `United States`.

**Did:** Mapped `United States.` → `United States`.

**Why:** This is a punctuation artifact from one source system, not a different country. Left alone, the US would appear as two countries in any country breakdown, and the 4-row group would look like a data error to anyone reading a dashboard. The fix is unambiguous — no judgment call involved.

**Affected:** 4 rows.

## 6. Exact duplicate rows — removed

**Found:** 5 rows are byte-for-byte duplicates of another row (all 9 fields identical):

| Company | Location | Total | Date | Stage |
|---|---|---|---|---|
| Yahoo | SF Bay Area | 1600 | 2/9/2023 | Acquired |
| Wildlife Studios | Sao Paulo | 300 | 11/28/2022 | Unknown |
| Cazoo | London | 750 | 6/7/2022 | Post-IPO |
| Casper | New York City | NULL | 9/14/2021 | Post-IPO |
| Hibob | Tel Aviv | 70 | 3/30/2020 | Series A |

**Did:** Removed with `ROW_NUMBER() OVER (PARTITION BY all 9 columns)`, keeping `row_number = 1` (`02_cleaning.sql`, Step 3).

**Why this over the alternatives:**
- *Keeping them* double-counts real layoffs (Yahoo's 1,600 people would count as 3,200).
- *Deduping on fewer columns* (e.g. company + date only) would have been dangerous — see entry 7, where same-company/same-date rows are genuinely different events. All 9 columns is the conservative partition: only rows that agree on everything are treated as the same event.

**Affected:** 5 rows removed (2,361 → 2,356).

## 7. Near-duplicates that were deliberately KEPT

**Found:** Oda (Oslo) has 3 rows for the same date, 11/1/2022, same headcount (70):

| Industry | Pct | Country | Funds |
|---|---|---|---|
| Food | 0.18 | Sweden | 377 |
| Food | 0.18 | Norway | 477 |
| Food | 0.06 | Norway | 479 |

**Did:** Kept all three, and flagged them here.

**Why:** They differ in substantive fields — country, percentage, and funds raised. Deleting two of them would require guessing which source system was right, and Oda is a Norwegian company (Oslo), which suggests the Sweden row is the error — but "suggests" is not proof, and a cleaning step must not silently rewrite facts it cannot verify. The correct action is to surface this to the data owner for source verification, not to delete. A related pair, Terminus (Atlanta, 5/27/2022), differs in stage and funds but both rows have NULL layoff numbers, so both were removed later by the both-null rule (entry 9) — not by dedupe.

**Affected:** 0 rows removed; 3 rows flagged for owner review.

## 8. Dates: one format, inconsistent padding, one missing

**Found:** All 2,360 dated rows use `M/D/YYYY`, but padding is inconsistent: `3/6/2023`, `03/06/2023`, `3/06/2023` all appear. One row has no date at all: `Blackbaud, Charleston, Other, 500, 0.14, NULL, Post-IPO, United States, NULL`.

**Did:** Converted with `STR_TO_DATE(date, '%m/%d/%Y')` into a real `DATE` column. `%m` and `%d` accept 1- or 2-digit values, so one format string handles every padding variant. Blackbaud's date stays `NULL`.

**Why this over the alternatives:**
- *Converting in place on the text column* would have destroyed the audit trail; the conversion happens in the staging copy, and the raw table still holds the original strings.
- *Dropping the Blackbaud row* would discard a real layoff event (500 people, 14%) over one missing field. Time-series analysis simply filters `date IS NOT NULL` (1,994 of 1,995 rows have dates).
- *Inventing a date* (e.g. from another Blackbaud row) would be fabrication.

**Affected:** 2,360 dates converted; 1 left NULL.

## 9. Null industry — filled by self-join where unambiguous

**Found:** 4 rows have no industry:

| Company | Other rows for the same company say |
|---|---|
| Airbnb (SF Bay Area) | Travel |
| Juul (SF Bay Area) | Consumer |
| Carvana (Phoenix) | Transportation |
| Bally's Interactive (Providence) | *(no other row exists)* |

**Did:** Filled the first three with a self-join; Bally's Interactive stays `NULL`.

**Why this over the alternatives:**
- *Deleting the 4 rows* would undercount real layoffs (Airbnb's row alone is 1,900 people).
- *Filling with "Unknown"* would be worse than `NULL`: it creates a fake category that looks like a real industry in charts.
- *A naive self-join* (join any row with the same company) was rejected for a subtle reason: 20 companies in this file carry **more than one** distinct industry across rows (e.g. Bolt is both `Finance` and `Transportation`; Clearco is both `Finance` and `Fin-Tech`). For those companies a join would pick an industry arbitrarily. The fill is therefore restricted to companies with exactly **one** distinct known industry (`HAVING COUNT(DISTINCT industry) = 1`), which makes every fill provably unambiguous. All three filled companies meet that test; Bally's has no source row at all, so it correctly remains `NULL`.

**Affected:** 3 filled, 1 remains `NULL`.

## 10. Rows where BOTH layoff measures are missing — deleted

**Found:** 362 rows have `total_laid_off IS NULL AND percentage_laid_off IS NULL` (361 after the Casper duplicate is removed in Step 3).

**Did:** Deleted all 361 (`02_cleaning.sql`, Step 6).

**Why:** A row with neither a headcount nor a percentage cannot answer any layoff question — it cannot be summed, averaged, or ranked. Keeping these rows would inflate event counts (a dashboard would report 2,356 "layoff events" when only 1,995 carry any layoff information) while adding zero analytical value. This is the single largest row reduction in the project and the most defensible one: no information is lost, because there was no information in those rows.

**Affected:** 361 rows removed (2,356 → 1,995).

## 11. Rows where only ONE layoff measure is missing — kept

**Found:** In the final table, 378 rows lack `total_laid_off` and 423 lack `percentage_laid_off` — but each of those rows still has the other measure.

**Did:** Kept them, with `NULL` in the missing field.

**Why:** Deleting them would throw away real information (e.g. a row that says "15% of staff laid off" still answers percentage questions even without a headcount). The correct handling is per-analysis: sums use known values only, and any average is reported with its sample size. Deletion is reserved for rows with *nothing* (entry 10).

**Affected:** 0 rows removed; 801 cells remain `NULL` by design.

## 12. Funds raised: decimals, zeros, and one suspicious outlier

**Found:**
- 45 rows carry decimals (e.g. `214.5`, `3.8`) — the column is `DECIMAL(12,1)`, not `INT`, so these survive exactly.
- 209 rows have `NULL` (unknown funding) — kept as `NULL`.
- 7 rows have `0` (e.g. Chessable, Drip) — kept as `0`. A bootstrapped company genuinely raising $0 is plausible, and unlike layoff counts, `0` here is a meaningful value, not a missing marker (missing funding was written as `NULL`, not `0`).
- Netflix's 4 rows all show `121900` ($121.9B) — far above any plausible "funds raised" and suspiciously close to a market-cap figure. It is **consistent across all 4 Netflix rows**, so it is not a merge artifact; it looks like a source-system definition difference (market cap recorded as funds raised).

**Did:** Kept all of the above as-is, with this note.

**Why:** "Suspicious" is not "wrong", and changing Netflix's funding to an invented number would be fabrication. The right action is to flag it for the data owner and exclude `funds_raised_millions` from any average that would be dominated by it (or use a median). A cleaner who silently "fixes" values they merely distrust is creating new errors.

**Affected:** 0 rows changed; 1 value flagged.

## 13. Null stage — kept as NULL

**Found:** 6 rows have `stage = 'NULL'` (Verily, Relevel, Advata, Spreetail, Gatherly, Zapp). After the both-null delete removes Spreetail, 5 remain in the final table.

**Did:** Converted to real `NULL`, rows kept.

**Why:** Stage is descriptive context, not a required field. A row without a stage still answers every layoff question. Deleting 5 real events over a missing label would be indefensible.

**Affected:** 5 rows carry `NULL` stage in the final table.

## 14. No columns were dropped — deliberately

**Found:** All 9 columns carry information used by the brief: company, location, industry, total laid off, percentage laid off, date, stage, country, funds raised.

**Did:** Dropped nothing.

**Why:** Dropping a column is irreversible information loss, and every column here is either a grouping dimension (industry, country, stage) or a measure (headcount, percentage, funds). If a future analysis needs only a subset, it can `SELECT` that subset — the clean table should stay complete. (The only column removed anywhere in this pipeline is the temporary `row_id` used for dedupe, which was never source data.)

**Affected:** 0 columns dropped.

## 15. Percentage = 1.0 (100% of staff laid off) — kept

**Found:** 116 rows in the final table have `percentage_laid_off = 1.0`.

**Did:** Kept as-is.

**Why:** A full-workforce layoff (company shutdown) is a real, common event in this dataset's era (2020–2023 startup shutdowns), and 1.0 is within the valid 0–1 range. These rows are not errors. They are, however, the reason percentage averages should always be reported alongside headcount totals — a 5-person startup at 100% and a 10,000-person layoff at 20% are not comparable events.

**Affected:** 0 rows changed; noted for analysts.

---

## Residual issues (known, accepted, flagged for the data owner)

1. **Oda's 3 conflicting rows** (entry 7) — needs source verification.
2. **Netflix's $121.9B "funds raised"** (entry 12) — likely a market-cap figure recorded under the wrong definition.
3. **Bally's Interactive has no industry** (entry 9) — 1 row; fill it only from an external source, not by guessing.
4. **Blackbaud has no date** (entry 8) — 1 row; excluded from time-series analysis only.
5. **20 companies carry multiple industries** (entry 9) — legitimate in some cases (conglomerates), a data problem in others; the self-join guard prevents this from corrupting fills, but industry-level totals for those companies should be read with care.
