-- ============================================================
-- E-commerce Sales Analysis — 02: Analysis queries
-- Table: ecommerce_sales.orders (see 01_data_setup.sql)
-- ============================================================

-- Q1. Top 10 products by revenue
SELECT product_name,
       ROUND(SUM(sales), 2) AS revenue
FROM orders
GROUP BY product_name
ORDER BY revenue DESC
LIMIT 10;

-- Q2a. Monthly revenue trend (full history — for the line chart)
SELECT DATE_FORMAT(order_date, '%Y-%m') AS month,
       ROUND(SUM(sales), 2) AS revenue
FROM orders
GROUP BY month
ORDER BY month;

-- Q2b. Slowest month (single answer for the write-up)
SELECT DATE_FORMAT(order_date, '%Y-%m') AS month,
       ROUND(SUM(sales), 2) AS revenue
FROM orders
GROUP BY month
ORDER BY revenue ASC
LIMIT 1;

-- Q3. Do repeat customers spend more than one-time customers?
-- Step 1 (CTE): one row per customer — order count + lifetime spend.
--   COUNT(DISTINCT order_id): one order with 5 products is 5 rows
--   but a single order, so DISTINCT is required.
-- Step 2: label each customer with CASE WHEN, then compare averages.
WITH cust AS (
  SELECT customer_id,
         COUNT(DISTINCT order_id) AS n_orders,
         SUM(sales) AS total_spent
  FROM orders
  GROUP BY customer_id
)
SELECT CASE WHEN n_orders = 1 THEN 'One-time' ELSE 'Repeat' END AS customer_type,
       COUNT(*) AS customers,
       ROUND(AVG(total_spent), 2) AS avg_spent
FROM cust
GROUP BY customer_type;
