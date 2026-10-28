-- ============================================================
-- Project: Movie / Streaming Database Analysis (TMDB 5000)
-- File: 01_data_setup.sql
-- Purpose: Create the movies table and load the TMDB dataset
-- Source: kaggle.com/datasets/tmdb/tmdb-movie-metadata
-- Rows loaded: 4,803
-- Notes:
--  - File is UTF-8 with \n line endings (NOT \r\n). If you use
--    '\r\n', the whole file reads as one line and IGNORE 1 ROWS
--    skips it, giving 0 records with no error.
--  - Empty numeric cells are loaded as NULL via @variables +
--    NULLIF. Without this, MySQL strict mode throws
--    Error 1366 (Incorrect integer value: '' for column 'runtime').
--  - genres/keywords/etc. are JSON text, parsed in later queries.
--  - release_date is loaded as text first; converted to a DATE
--    column in 02_cleaning.sql.
-- ============================================================

CREATE DATABASE IF NOT EXISTS movie_analysis;
USE movie_analysis;

CREATE TABLE movies (
    id INT PRIMARY KEY,
    title VARCHAR(255),
    original_title VARCHAR(255),
    original_language VARCHAR(10),
    overview TEXT,
    tagline TEXT,
    homepage TEXT,
    status VARCHAR(20),
    release_date VARCHAR(20),
    runtime INT,
    budget BIGINT,
    revenue BIGINT,
    popularity DECIMAL(10,3),
    vote_average DECIMAL(3,1),
    vote_count INT,
    genres TEXT,
    keywords TEXT,
    production_companies TEXT,
    production_countries TEXT,
    spoken_languages TEXT
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/tmdb_5000_movies.csv'
INTO TABLE movies
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@budget, genres, homepage, id, keywords, original_language, original_title, overview, @popularity, production_companies, production_countries, release_date, @revenue, @runtime, spoken_languages, status, tagline, title, @vote_average, @vote_count)
SET
    budget = NULLIF(@budget, ''),
    popularity = NULLIF(@popularity, ''),
    revenue = NULLIF(@revenue, ''),
    runtime = NULLIF(@runtime, ''),
    vote_average = NULLIF(@vote_average, ''),
    vote_count = NULLIF(@vote_count, '');

-- Verify: should return 4803
SELECT COUNT(*) FROM movies;
