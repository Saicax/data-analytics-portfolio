-- ============================================================
-- File: 02_cleaning.sql
-- Purpose: Convert release_date (text) to a real DATE column,
--          and record the data-quality findings that shape
--          every later query.
--
-- Data quality findings (verified on the loaded table):
--  - budget = 0 in 1,037 of 4,803 rows (21.6%)
--  - revenue = 0 in 1,427 of 4,803 rows (29.7%)
--  - In TMDB, 0 does NOT mean "free" — it means "not recorded".
--    No movie cost $0 to make. Every money query in
--    03_analysis_queries.sql therefore filters > 0, or its
--    averages are dragged down by fake zeros.
--  - release_date missing in exactly 1 row.
--  - Empty numeric cells were already stored as NULL by the
--    NULLIF pattern in 01_data_setup.sql.
-- ============================================================

USE movie_analysis;

ALTER TABLE movies ADD COLUMN release_dt DATE;

SET SQL_SAFE_UPDATES = 0;

UPDATE movies
SET release_dt = STR_TO_DATE(release_date, '%Y-%m-%d')
WHERE release_date <> '' AND release_date IS NOT NULL;

SET SQL_SAFE_UPDATES = 1;

-- Verify: should return 1 (the one movie with no release date)
SELECT COUNT(*) FROM movies WHERE release_dt IS NULL;
