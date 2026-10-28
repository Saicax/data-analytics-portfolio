-- ============================================================
-- Project: Data Cleaning — Layoffs 2022 (merged export)
-- File: 03_clean_table.sql
-- Purpose: Build the final, trusted table from the cleaned
--          staging data, then prove it with verification
--          queries. Run after 02_cleaning.sql.
-- ============================================================

USE layoffs_db;

DROP TABLE IF EXISTS layoffs_clean;

CREATE TABLE layoffs_clean (
    company               VARCHAR(255),
    location              VARCHAR(255),
    industry              VARCHAR(255),
    total_laid_off        INT,
    percentage_laid_off   DECIMAL(5, 4),
    date                  DATE,
    stage                 VARCHAR(50),
    country               VARCHAR(100),
    funds_raised_millions DECIMAL(12, 1)
);

INSERT INTO layoffs_clean
SELECT company, location, industry,
       total_laid_off, percentage_laid_off,
       date, stage, country, funds_raised_millions
FROM layoffs_staging2
ORDER BY date, company;

-- ============================================================
-- VERIFICATION — row counts before / after each stage
-- (expected values in comments; all verified on the real file)
-- ============================================================

-- Stage funnel (documented values; each stage's count was
-- verified against the real file during the build):
--   Raw load .............. 2,361
--   After dedupe .......... 2,356  (-5 exact duplicates)
--   After both-null delete  1,995  (-361 unusable rows)
-- Standardization, date conversion and the industry self-join
-- change values, not row counts, so they do not move the funnel.
SELECT COUNT(*) AS raw_rows FROM layoffs_staging;            -- expect 2,361
SELECT COUNT(*) AS final_clean_rows FROM layoffs_clean;      -- expect 1,995

-- ============================================================
-- VERIFICATION — null counts: raw vs clean
-- ============================================================
SELECT 'raw'   AS version,
       SUM(industry IS NULL)              AS industry_null,
       SUM(total_laid_off IS NULL)        AS total_null,
       SUM(percentage_laid_off IS NULL)   AS pct_null,
       SUM(date IS NULL)                  AS date_null,
       SUM(stage IS NULL)                 AS stage_null,
       SUM(funds_raised_millions IS NULL) AS funds_null
FROM layoffs_staging
UNION ALL
SELECT 'clean' AS version,
       SUM(industry IS NULL),
       SUM(total_laid_off IS NULL),
       SUM(percentage_laid_off IS NULL),
       SUM(date IS NULL),
       SUM(stage IS NULL),
       SUM(funds_raised_millions IS NULL)
FROM layoffs_clean;
-- Expected:
--   raw:   industry 4, total 740, pct 785, date 1, stage 6, funds 209
--   clean: industry 1, total 378, pct 423, date 1, stage 5, funds 165
-- Reading the drop: industry 4->1 (3 filled by self-join);
-- total 740->378 and pct 785->423 (361 both-null rows deleted
-- carried 361 nulls out of each column, plus 1 Casper dup);
-- funds 209->165 (44 nulls left with deleted rows).

-- ============================================================
-- VERIFICATION — no duplicates, no variants left
-- ============================================================
SELECT COUNT(*) AS duplicate_groups_left
FROM (
    SELECT company, location, industry, total_laid_off,
           percentage_laid_off, date, stage, country,
           funds_raised_millions, COUNT(*) AS c
    FROM layoffs_clean
    GROUP BY company, location, industry, total_laid_off,
             percentage_laid_off, date, stage, country,
             funds_raised_millions
    HAVING c > 1
) d;  -- expect 0

SELECT DISTINCT industry FROM layoffs_clean
WHERE industry LIKE '%Crypto%';  -- expect only 'Crypto'

SELECT DISTINCT country FROM layoffs_clean
WHERE country LIKE '%.';         -- expect 0 rows

-- ============================================================
-- VERIFICATION — date is a real DATE now, full range usable
-- ============================================================
SELECT MIN(date) AS earliest, MAX(date) AS latest,
       COUNT(*)  AS dated_rows
FROM layoffs_clean
WHERE date IS NOT NULL;
-- expect 2020-03-11 -> 2023-03-06, 1,994 dated rows
