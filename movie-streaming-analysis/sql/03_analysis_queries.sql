-- ============================================================
-- Project: Movie / Streaming Database Analysis (TMDB 5000)
-- File: 03_analysis_queries.sql
-- Purpose: Answer the client brief:
--   "Find out if higher budget movies actually get better
--    ratings, and identify which genre has the best
--    ratings-to-budget ratio."
-- Depends on: 01_data_setup.sql, 02_cleaning.sql
-- Standing rule: budget/revenue of 0 = "unknown" in TMDB,
--   so money queries filter > 0.
-- Note on correlation: MySQL 8 has no built-in CORR()
--   aggregate, so Q2/Q4 correlations were computed in Excel
--   (=CORREL) and verified in Python. The r values in the
--   Finding lines are the computed results.
-- ============================================================

USE movie_analysis;

-- ------------------------------------------------------------
-- Q1: Top 10 highest-grossing movies
-- Finding: Avatar #1 at $2,787,965,087, more than $900M ahead
--   of #2 (Titanic, $1,845,034,188). Top 10 cutoff:
--   Captain America: Civil War at $1,153,304,495.
-- ------------------------------------------------------------
SELECT title, release_dt, budget, revenue
FROM movies
WHERE revenue > 0
ORDER BY revenue DESC
LIMIT 10;

-- ------------------------------------------------------------
-- Q2: Budget vs revenue (scatter-plot data)
-- Export: data/q2_budget_vs_revenue.csv
-- Finding: Budget and revenue are strongly positively
--   correlated (r = 0.71, n = 3,229 movies with both known).
--   Bigger budgets tend to earn more — but the scatter shows
--   wide spread, so budget alone doesn't guarantee a hit.
-- ------------------------------------------------------------
SELECT title, budget, revenue
FROM movies
WHERE budget > 0 AND revenue > 0;

-- ------------------------------------------------------------
-- Q3: Average revenue by genre (JSON parsing)
-- Export: data/q3_avg_revenue_by_genre.csv
-- How: JSON_TABLE unpacks the genres JSON list into one row
--   per genre, so a 3-genre movie counts in all 3 genres.
--   Genre counts therefore sum to more than 4,803 — correct
--   behaviour for "how does each genre perform".
-- Finding: Animation #1 at $276,503,497 average revenue
--   (n = 191), ahead of Adventure ($244,209,721, n = 675)
--   and Fantasy ($233,567,521, n = 351). The Pixar/Disney
--   effect: fewer animated films, but they are huge.
-- ------------------------------------------------------------
SELECT
    g.genre,
    COUNT(*) AS movie_count,
    ROUND(AVG(m.revenue)) AS avg_revenue
FROM movies m,
     JSON_TABLE(m.genres, '$[*]' COLUMNS (genre VARCHAR(50) PATH '$.name')) AS g
WHERE m.revenue > 0
GROUP BY g.genre
ORDER BY avg_revenue DESC;

-- ------------------------------------------------------------
-- Q4: Budget vs RATING (the client question)
-- Export: data/q4_budget_vs_rating.csv
-- Filter (explicit): budget > 0 AND vote_count > 100.
--   The vote_count filter removes tiny-sample noise — a film
--   rated 10/10 by 3 voters would otherwise distort the plot.
-- Finding: NO meaningful relationship. Correlation r = -0.07
--   (n = 2,902). Without the vote filter it is r = 0.02
--   (n = 3,766) — still essentially zero. Higher budgets do
--   NOT buy better ratings. This is the headline answer to
--   the client brief, and it contrasts sharply with Q2
--   (budget vs revenue, r = 0.71): money buys box office,
--   not quality.
-- ------------------------------------------------------------
SELECT title, budget, vote_average, vote_count
FROM movies
WHERE budget > 0 AND vote_count > 100
ORDER BY budget DESC;

-- ------------------------------------------------------------
-- Q5: Average rating by genre
-- Export: data/q5_avg_rating_by_genre.csv
-- Filter: vote_count > 100 (same tiny-sample protection as Q4).
-- Finding: Documentary #1 at 7.03 (n = 22), then War 6.93
--   (n = 95) and History 6.88 (n = 120). Horror is lowest
--   among major genres at 5.88 (n = 381). Caveat: TV Movie
--   (5.80) rests on only 3 movies — ignore it.
-- ------------------------------------------------------------
SELECT
    g.genre,
    COUNT(*) AS movie_count,
    ROUND(AVG(m.vote_average), 2) AS avg_rating
FROM movies m,
     JSON_TABLE(m.genres, '$[*]' COLUMNS (genre VARCHAR(50) PATH '$.name')) AS g
WHERE m.vote_count > 100
GROUP BY g.genre
ORDER BY avg_rating DESC;

-- ------------------------------------------------------------
-- Q6: Ratings-to-budget ratio by genre
-- Export: data/q6_rating_to_budget_ratio.csv
-- Definition: rating_per_10m_budget =
--   avg_rating / (avg_budget / 10,000,000)
--   = "how many rating points a genre earns per $10M spent".
--   A higher number means more audience love per dollar.
-- Filter: budget > 0 AND vote_count > 100.
-- Finding: TV Movie tops the raw ranking (19.04) but on only
--   2 movies — statistically meaningless, do not quote it.
--   Documentary is next at 6.33 (n = 16, small sample — flag
--   it). Among genres with n >= 100, Horror leads at 2.83
--   (n = 340): cheap to make, decently rated. At the other
--   end, Adventure (0.78, n = 631) and Animation (0.80,
--   n = 180) earn the least rating per dollar despite their
--   huge revenues — blockbuster genres are expensive.
-- ------------------------------------------------------------
SELECT
    g.genre,
    COUNT(*) AS movie_count,
    ROUND(AVG(m.vote_average), 2) AS avg_rating,
    ROUND(AVG(m.budget)) AS avg_budget,
    ROUND(AVG(m.vote_average) / (AVG(m.budget) / 10000000), 3) AS rating_per_10m_budget
FROM movies m,
     JSON_TABLE(m.genres, '$[*]' COLUMNS (genre VARCHAR(50) PATH '$.name')) AS g
WHERE m.budget > 0 AND m.vote_count > 100
GROUP BY g.genre
ORDER BY rating_per_10m_budget DESC;

-- ------------------------------------------------------------
-- Q7: Top-rated movies (vote_count > 100 only)
-- Finding: The Shawshank Redemption #1 at 8.5 (8,205 votes),
--   followed by The Godfather at 8.4 (5,893 votes). The
--   vote_count filter is what keeps this list honest — it
--   excludes obscure films rated 10/10 by a handful of voters.
-- ------------------------------------------------------------
SELECT title, release_dt, vote_average, vote_count
FROM movies
WHERE vote_count > 100
ORDER BY vote_average DESC, vote_count DESC
LIMIT 10;
