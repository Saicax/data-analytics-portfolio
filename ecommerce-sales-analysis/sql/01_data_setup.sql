-- ============================================================
-- E-commerce Sales Analysis — 01: Data setup
-- MySQL 8.0. Run section by section.
-- ============================================================

-- 1. Create the database and table
CREATE DATABASE IF NOT EXISTS ecommerce_sales;
USE ecommerce_sales;

CREATE TABLE orders (
  `Row ID` INT,
  `Order ID` TEXT,
  `Order Date` TEXT,
  `Ship Date` TEXT,
  `Ship Mode` TEXT,
  `Customer ID` TEXT,
  `Customer Name` TEXT,
  Segment TEXT,
  Country TEXT,
  City TEXT,
  State TEXT,
  `Postal Code` TEXT,
  Region TEXT,
  `Product ID` TEXT,
  Category TEXT,
  `Sub-Category` TEXT,
  `Product Name` TEXT,
  Sales DECIMAL(12,2),
  Quantity INT,
  Discount DECIMAL(6,4),
  Profit DECIMAL(12,2)
);

-- 2. Load the CSV directly (fast + reliable).
--    Copy the CSV into MySQL's secure folder first:
--      SHOW VARIABLES LIKE 'secure_file_priv';
--    Adjust the path below to match. The file is latin1-encoded,
--    so declare the character set or the import fails on row ~1,366.
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Sample - Superstore.csv'
INTO TABLE orders
CHARACTER SET latin1
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- 3. Verify the load (expect 9,994)
SELECT COUNT(*) AS total_rows FROM orders;

-- 4. Standardize column names to snake_case (no more backticks)
ALTER TABLE orders
  RENAME COLUMN `Row ID` TO row_id,
  RENAME COLUMN `Order ID` TO order_id,
  RENAME COLUMN `Order Date` TO order_date_raw,
  RENAME COLUMN `Ship Date` TO ship_date,
  RENAME COLUMN `Ship Mode` TO ship_mode,
  RENAME COLUMN `Customer ID` TO customer_id,
  RENAME COLUMN `Customer Name` TO customer_name,
  RENAME COLUMN Segment TO segment,
  RENAME COLUMN Country TO country,
  RENAME COLUMN City TO city,
  RENAME COLUMN State TO state,
  RENAME COLUMN `Postal Code` TO postal_code,
  RENAME COLUMN Region TO region,
  RENAME COLUMN `Product ID` TO product_id,
  RENAME COLUMN Category TO category,
  RENAME COLUMN `Sub-Category` TO sub_category,
  RENAME COLUMN `Product Name` TO product_name,
  RENAME COLUMN Sales TO sales,
  RENAME COLUMN Quantity TO quantity,
  RENAME COLUMN Discount TO discount,
  RENAME COLUMN Profit TO profit;

-- 5. Build a real DATE column from the text dates.
--    (DATE_FORMAT on text returns NULL — this is the fix.)
ALTER TABLE orders ADD COLUMN order_date DATE;
SET SQL_SAFE_UPDATES = 0;  -- allow the full-table update, then re-enable
UPDATE orders SET order_date = STR_TO_DATE(order_date_raw, '%c/%e/%Y');
SET SQL_SAFE_UPDATES = 1;

-- 6. Verify the conversion (expect 0 failed rows, dates 2014-01 to 2017-12)
SELECT COUNT(*) AS failed_conversions
FROM orders
WHERE order_date IS NULL AND order_date_raw IS NOT NULL;

SELECT MIN(order_date) AS earliest, MAX(order_date) AS latest FROM orders;
