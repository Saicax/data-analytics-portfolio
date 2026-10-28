-- ============================================================
-- Project: Data Cleaning — Layoffs 2022 (merged export)
-- File: 02_cleaning.sql
-- Purpose: The full cleaning pipeline. Each step is separate
--          and commented so the reasoning is auditable.
--          Raw counts are from the actual file; every step's
--          row impact is stated in its comment.
-- Order of operations (and why):
--  1. Working copy   — staging stays pristine; we never edit raw data.
--  2. TRIM           — whitespace must go before dedupe, or
--                      'WeWork ' and 'WeWork' look like two companies.
--  3. Standardize    — casing/variant fixes happen BEFORE dedupe,
--                      so rows that differ only by a variant
--                      collapse into true duplicates.
--  4. Dedupe         — ROW_NUMBER() over all 9 meaningful columns.
--  5. Date convert   — text -> DATE, format '%m/%d/%Y'.
--  6. Industry fill  — self-join, restricted to companies with
--                      exactly ONE known industry (see note).
--  7. Delete unusable rows — BOTH layoff fields NULL.
-- ============================================================

USE layoffs_db;

-- ------------------------------------------------------------
-- STEP 0 — Working copy (staging stays untouched)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS layoffs_staging2;
CREATE TABLE layoffs_staging2 LIKE layoffs_staging;

INSERT INTO layoffs_staging2
SELECT * FROM layoffs_staging;

-- Temporary row id: the dedupe DELETE in Step 4 needs a stable
-- key to point at. It is dropped again in Step 8.
ALTER TABLE layoffs_staging2 ADD COLUMN row_id INT AUTO_INCREMENT PRIMARY KEY FIRST;

-- ------------------------------------------------------------
-- STEP 1 — TRIM whitespace on every text field
-- Impact: 11 company cells had leading/trailing spaces, e.g.
-- 'WeWork ' (twice), ' Included Health', ' E Inc.'.
-- Without TRIM, GROUP BY company splits these into phantom
-- companies and the dedupe in Step 4 misses matches.
-- ------------------------------------------------------------
UPDATE layoffs_staging2
SET company  = TRIM(company),
    location = TRIM(location),
    industry = TRIM(industry),
    date     = TRIM(date),
    stage    = TRIM(stage),
    country  = TRIM(country);

-- ------------------------------------------------------------
-- STEP 2 — Standardize values (documented mappings)
-- 2a. Company casing: brand names arrived in two casings from
--     different source systems. 9 rows affected. Mapping:
--     Salesloft -> SalesLoft, Appgate -> AppGate,
--     Clearco -> ClearCo, Bytedance -> ByteDance,
--     Curefit -> CureFit (the established brand spellings).
--     Trade-off: if a brand spelling is wrong, the damage is
--     cosmetic only — company is a label here, not a join key.
-- 2b. Industry: three spellings of the same industry.
--     3 rows affected: 'Crypto Currency' (2) and
--     'CryptoCurrency' (1) -> 'Crypto' (99 rows already).
--     Without this, crypto layoffs split across three groups.
-- 2c. Country: a trailing period from one source system.
--     4 rows affected: 'United States.' -> 'United States'.
-- ------------------------------------------------------------
UPDATE layoffs_staging2
SET company = CASE company
    WHEN 'Salesloft' THEN 'SalesLoft'
    WHEN 'Appgate'   THEN 'AppGate'
    WHEN 'Clearco'   THEN 'ClearCo'
    WHEN 'Bytedance' THEN 'ByteDance'
    WHEN 'Curefit'   THEN 'CureFit'
    ELSE company
END;

UPDATE layoffs_staging2
SET industry = CASE industry
    WHEN 'Crypto Currency' THEN 'Crypto'
    WHEN 'CryptoCurrency'  THEN 'Crypto'
    ELSE industry
END;

UPDATE layoffs_staging2
SET country = CASE country
    WHEN 'United States.' THEN 'United States'
    ELSE country
END;

-- ------------------------------------------------------------
-- STEP 3 — Remove exact duplicates with ROW_NUMBER()
-- Impact: 5 rows removed (2,361 -> 2,356).
-- Removed pairs (each appeared twice):
--   Yahoo (SF Bay Area, 1600, 2/9/2023)
--   Wildlife Studios (Sao Paulo, 300, 11/28/2022)
--   Cazoo (London, 750, 6/7/2022)
--   Casper (New York City, NULL/NULL, 9/14/2021)
--   Hibob (Tel Aviv, 70, 3/30/2020)
-- PARTITION BY covers all 9 meaningful columns: two rows are
-- the same layoff event only if every field matches.
-- Note on near-duplicates that were deliberately KEPT:
-- Oda has 3 rows (Oslo, 70 people, 11/1/2022) that differ in
-- country (Sweden vs Norway) and funds raised (377 vs 477 vs
-- 479). They are NOT the same event on the evidence available,
-- and deleting two of them would mean guessing which source
-- system was right. They are flagged in docs/decision-log.md.
-- ------------------------------------------------------------
DELETE FROM layoffs_staging2
WHERE row_id IN (
    SELECT row_id FROM (
        SELECT row_id,
               ROW_NUMBER() OVER (
                   PARTITION BY company, location, industry,
                                total_laid_off, percentage_laid_off,
                                date, stage, country,
                                funds_raised_millions
               ) AS rn
        FROM layoffs_staging2
    ) ranked
    WHERE rn > 1
);

-- ------------------------------------------------------------
-- STEP 4 — Convert the date text column to a real DATE
-- File format (verified on all 2,360 dated rows): M/D/YYYY
-- with inconsistent zero-padding, e.g. '3/6/2023' and
-- '03/06/2023' both appear. STR_TO_DATE with '%m/%d/%Y'
-- handles both because %m and %d accept 1- or 2-digit values.
-- One row (Blackbaud, Charleston) has a NULL date; it is kept
-- with a NULL date — inventing a date would be fabrication,
-- and time-series queries must filter date IS NOT NULL.
-- ------------------------------------------------------------
ALTER TABLE layoffs_staging2 ADD COLUMN date_parsed DATE;

UPDATE layoffs_staging2
SET date_parsed = STR_TO_DATE(date, '%m/%d/%Y')
WHERE date IS NOT NULL;

ALTER TABLE layoffs_staging2 DROP COLUMN date;
ALTER TABLE layoffs_staging2 RENAME COLUMN date_parsed TO date;

-- ------------------------------------------------------------
-- STEP 5 — Fill missing industry via self-join on company
-- Impact: 3 of 4 NULL industries filled; 1 remains NULL.
--   Airbnb -> Travel, Juul -> Consumer, Carvana -> Transportation
--   Bally's Interactive -> still NULL (no other row for it).
-- Why the HAVING guard matters: 20 companies in this file have
-- MORE than one distinct industry across rows (e.g. Bolt is
-- both 'Finance' and 'Transportation'). A naive self-join would
-- pick one arbitrarily for those companies. Restricting the
-- lookup to companies with exactly one known industry makes
-- every fill unambiguous — the company can only be one thing.
-- Alternative rejected: deleting the 4 rows. Industry is one
-- descriptive field; the rows carry valid layoff numbers, and
-- deleting them would undercount real layoffs.
-- ------------------------------------------------------------
UPDATE layoffs_staging2 t1
JOIN (
    SELECT company, MAX(industry) AS known_industry
    FROM layoffs_staging2
    WHERE industry IS NOT NULL
    GROUP BY company
    HAVING COUNT(DISTINCT industry) = 1
) t2
  ON t1.company = t2.company
SET t1.industry = t2.known_industry
WHERE t1.industry IS NULL;

-- ------------------------------------------------------------
-- STEP 6 — Delete rows where BOTH layoff measures are NULL
-- Impact: 361 rows removed (2,356 -> 1,995).
-- A row with neither a headcount nor a percentage contributes
-- nothing to any layoff question — it cannot be summed, it
-- cannot be averaged, and it cannot be ranked. Keeping it
-- would only inflate event counts.
-- Rows with only ONE measure missing are KEPT (378 rows lack
-- total_laid_off, 423 lack percentage_laid_off in the final
-- table): the surviving field still answers real questions,
-- and the missing one is handled per-analysis (e.g. totals
-- sum only known values).
-- Note: raw both-null count was 362; one was the duplicate
-- Casper row already removed in Step 3, hence 361 here.
-- ------------------------------------------------------------
DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- ------------------------------------------------------------
-- STEP 7 — Drop the temporary row id
-- ------------------------------------------------------------
ALTER TABLE layoffs_staging2 DROP COLUMN row_id;

-- Verification (expected values in comments):
SELECT COUNT(*) AS rows_after_cleaning FROM layoffs_staging2;  -- expect 1,995
SELECT COUNT(*) AS industry_still_null FROM layoffs_staging2 WHERE industry IS NULL;  -- expect 1
SELECT COUNT(*) AS date_still_null FROM layoffs_staging2 WHERE date IS NULL;          -- expect 1
SELECT DISTINCT industry FROM layoffs_staging2 ORDER BY industry;  -- expect 30, all 'Crypto'
SELECT DISTINCT country FROM layoffs_staging2 WHERE country LIKE '%.';  -- expect 0 rows
