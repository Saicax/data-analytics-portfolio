-- ============================================================
-- Project: Data Cleaning — Layoffs 2022 (merged export)
-- File: 01_staging.sql
-- Purpose: Create the staging table (exact copy of the raw
--          structure) and load the raw CSV into it, untouched.
-- Source: layoffs.csv — Layoffs 2022 dataset, exported from
--         three different systems and merged badly.
-- File facts (verified before writing this script):
--  - Encoding: UTF-8  -> CHARACTER SET utf8mb4
--  - Line endings: CRLF (\r\n) -> LINES TERMINATED BY '\r\n'
--  - Rows: 2,361 data rows + 1 header row
--  - Missing values are written as the literal string 'NULL'
--    (and occasionally as an empty string), NOT as real SQL
--    NULLs. The @variable + NULLIF pattern below converts
--    both forms to real NULLs at load time. If you skip it,
--    MySQL strict mode throws Error 1366 on the numeric
--    columns, and the text columns keep the fake 'NULL'
--    string forever.
-- ============================================================

CREATE DATABASE IF NOT EXISTS layoffs_db;
USE layoffs_db;

DROP TABLE IF EXISTS layoffs_staging;

CREATE TABLE layoffs_staging (
    company               VARCHAR(255),
    location              VARCHAR(255),
    industry              VARCHAR(255),
    total_laid_off        INT,
    percentage_laid_off   DECIMAL(5, 4),
    date                  VARCHAR(20),   -- text for now; converted to DATE in 02_cleaning.sql
    stage                 VARCHAR(50),
    country               VARCHAR(100),
    funds_raised_millions DECIMAL(12, 1) -- 45 rows carry decimals (e.g. 214.5); INT would truncate them
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/layoffs.csv'
INTO TABLE layoffs_staging
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(company, location, industry,
 @total_laid_off, @percentage_laid_off,
 date, stage, country, @funds_raised_millions)
SET
    -- Nested NULLIF: '' -> NULL, then 'NULL' -> NULL.
    -- Anything else passes through and is cast to the column type.
    total_laid_off        = NULLIF(NULLIF(@total_laid_off, ''), 'NULL'),
    percentage_laid_off   = NULLIF(NULLIF(@percentage_laid_off, ''), 'NULL'),
    funds_raised_millions = NULLIF(NULLIF(@funds_raised_millions, ''), 'NULL');

-- Verification: expect 2,361
SELECT COUNT(*) AS raw_rows FROM layoffs_staging;
