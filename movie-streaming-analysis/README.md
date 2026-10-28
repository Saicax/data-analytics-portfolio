# Movie / Streaming Database Analysis

## Question

Client brief: **"Find out if higher budget movies actually get better ratings, and identify which genre has the best ratings-to-budget ratio."**

Sub-questions answered along the way:
1. Which movies earned the most money?
2. Do bigger budgets earn more revenue?
3. Which genres earn the most on average?
4. Do bigger budgets earn *better ratings*? (the core question)
5. Which genres are rated highest?
6. Which genre earns the most rating per dollar spent?
7. Which movies are the highest rated overall?

## Data

- **Source:** TMDB 5000 Movie Dataset (Kaggle: `tmdb/tmdb-movie-metadata`)
- **File:** `tmdb_5000_movies.csv` — 4,803 movies, 21 columns
- **Kept columns:** title, genre (JSON list), budget, revenue, rating (`vote_average`), vote count, release date
- **Ignored:** cast/crew tables (not needed for this brief), homepage, keywords, production companies/countries, spoken languages, overview, tagline

## Process

1. **Loaded** the CSV into MySQL 8 (`movie_analysis.movies`) — see `sql/01_data_setup.sql`.
   - Two load gotchas worth knowing: the file uses `\n` line endings (not `\r\n`), and empty numeric cells must be loaded as NULL via `@variables` + `NULLIF`, otherwise MySQL strict mode throws Error 1366.
2. **Cleaned** — see `sql/02_cleaning.sql`: converted the text `release_date` to a real DATE column (`release_dt`) via `STR_TO_DATE(..., '%Y-%m-%d')`.
3. **Analysed** — 7 numbered queries in `sql/03_analysis_queries.sql`, each with its question, export file, and Finding line.
4. **Exported** clean CSVs to `data/` (data only — no notes inside the files).
5. **Charted** in Excel (native charts in the workbook) and as PNGs in `images/`.
6. **Correlations** (MySQL 8 has no built-in `CORR()`): computed in Excel with `=CORREL` and verified in Python.

## Findings

### 1. Money buys box office — but not quality (the headline)

- **Budget vs revenue: r = 0.71, n = 3,229** movies with both values known. Strong positive correlation — bigger budgets tend to earn more.
- **Budget vs rating: r = -0.07, n = 2,902** movies (budget > 0, vote_count > 100). Essentially zero. Without the vote filter it is r = 0.02 (n = 3,766) — still zero.
- **Answer to the client: No — higher budget movies do NOT get better ratings.** Money buys box office, not audience love.

### 2. Top earners

- **Avatar #1 at $2,787,965,087**, more than $900M ahead of #2 (Titanic, $1,845,034,188).
- Top-10 cutoff: Captain America: Civil War at $1,153,304,495.

### 3. Revenue by genre

- **Animation #1 at $276,503,497 average revenue (n = 191)**, ahead of Adventure ($244,209,721, n = 675) and Fantasy ($233,567,521, n = 351). The Pixar/Disney effect: fewer animated films, but they are huge.
- Lowest: Documentary at $23,027,185 average (n = 47).

### 4. Ratings by genre

- **Documentary #1 at 7.03 (n = 22)**, then War 6.93 (n = 95) and History 6.88 (n = 120).
- Lowest among major genres: Horror at 5.88 (n = 381).

### 5. Ratings-to-budget ratio by genre

Defined as: **avg_rating per $10M of average budget** = avg_rating / (avg_budget / 10,000,000). Higher = more audience love per dollar.

- **Raw #1 is TV Movie (19.04) — but on only 2 movies, so it is statistically meaningless and should not be quoted.**
- Documentary is next at **6.33 (n = 16)** — highest honest ratio, but a small sample, so flag it.
- **Among genres with n >= 100, Horror leads at 2.83 (n = 340):** cheap to make, decently rated.
- At the other end, **Adventure (0.78, n = 631)** and **Animation (0.80, n = 180)** earn the least rating per dollar despite their huge revenues — blockbuster genres are expensive.

### 6. Top-rated movies

- **The Shawshank Redemption #1 at 8.5 (8,205 votes)**, followed by The Godfather at 8.4 (5,893 votes). The vote_count > 100 filter is what keeps this list honest.

## Caveats (read before quoting any number)

- **In TMDB, 0 means "unknown", not zero.** budget = 0 in 1,037 rows (21.6%) and revenue = 0 in 1,427 rows (29.7%). Every money query filters > 0.
- **Multi-genre movies count in each of their genres.** Genre counts therefore sum to more than 4,803. This is correct for "how does each genre perform", not a bug.
- **Small samples are flagged, not hidden.** TV Movie (n = 2 in Q6, n = 3 in Q5) and Documentary (n = 16 in Q6) must not be quoted without their sample sizes.
- **Correlation is not causation.** Budget and revenue move together, but franchise fame, marketing, and star power likely push both up at once.
- **Only 1 movie** has a missing release date.

## Files

| Path | Contents |
|---|---|
| `sql/01_data_setup.sql` | CREATE TABLE + LOAD DATA (utf8mb4, `\n`, NULLIF pattern) |
| `sql/02_cleaning.sql` | release_dt DATE conversion + data-quality findings |
| `sql/03_analysis_queries.sql` | Q1–Q7, each with question, export file, and Finding |
| `data/q1_top10_grossing.csv` | Top 10 movies by revenue |
| `data/q2_budget_vs_revenue.csv` | 3,229 rows: title, budget, revenue |
| `data/q3_avg_revenue_by_genre.csv` | 19 genres: movie count, avg revenue |
| `data/q4_budget_vs_rating.csv` | 2,902 rows: title, budget, rating, vote count |
| `data/q5_avg_rating_by_genre.csv` | 19 genres: movie count, avg rating |
| `data/q6_rating_to_budget_ratio.csv` | 19 genres: avg rating, avg budget, rating per $10M |
| `data/q7_top_rated.csv` | Top 10 movies by rating (vote_count > 100) |
| `images/budget_vs_rating_scatter.png` | Budget vs rating scatter (r = -0.07) |
| `images/genre_avg_rating_bar.png` | Average rating by genre bar chart |
| `movie-analysis.xlsx` | One sheet per result, with native scatter + bar charts |

## Tools

MySQL 8 · Excel · Python (verification) · matplotlib (chart PNGs)
