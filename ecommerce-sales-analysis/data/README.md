# Data

These CSVs are **query-result exports** (from `sql/02_analysis_queries.sql`), not the raw dataset.

- `top10_products.csv` — Q1 result: top 10 products by revenue
- `monthly_revenue.csv` — Q2a result: revenue per month, Jan 2014 – Dec 2017 (48 rows, for the trend chart)
- `repeat_vs_onetime.csv` — Q3 result: customer counts and average spend by type

**Raw data:** download `Sample - Superstore.csv` from the [Superstore Sales dataset on Kaggle](https://www.kaggle.com/datasets/vivek468/superstore-dataset-final) (9,994 rows) and load it with `sql/01_data_setup.sql`.
