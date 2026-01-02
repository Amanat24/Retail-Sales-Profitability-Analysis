CREATE DATABASE retail_analytics;
USE retail_analytics;

CREATE TABLE customers AS
SELECT DISTINCT
`Customer ID` AS customer_id,
`Customer Name` AS customer_name,
`Last Name` AS last_name,
`Date of Birth` AS date_of_birth,
Segment AS segment,
`City Type` AS city_type,
State  AS state,
Country AS country,
Region AS region
FROM store_sales_data;

CREATE TABLE orders AS
SELECT
`Order ID` AS order_id,
`Order Date` AS order_date,
`Ship Date` AS ship_date,
`Ship Mode`AS ship_mode,
`Customer ID`AS customer_id,
`Product ID` AS product_id,
Year AS order_year,
`Outlet Type` AS outlet_type,
Region AS region,
Quantity AS quantity,
Sales AS sales,
Discount AS discount,
Profit AS profit
FROM store_sales_data;

CREATE TABLE products AS
SELECT DISTINCT
    `Product ID`          AS product_id,
    `Product Name`        AS product_name,
    `Category of Goods`   AS category,
    `Sub-Category`        AS sub_category
FROM store_sales_data;

CREATE OR REPLACE VIEW vw_customers_clean AS
SELECT
customer_id,
customer_name,
last_name,
date_of_birth,
UPPER(TRIM(segment)) AS segment,
UPPER(TRIM(city_type)) AS city_type,
UPPER(TRIM(state)) AS state,
UPPER(TRIM(country)) AS country,
UPPER(TRIM(region)) AS region
FROM customers;

CREATE OR REPLACE VIEW vw_products_clean AS
SELECT
product_id,
product_name,
UPPER(TRIM(category))     AS category,
UPPER(TRIM(sub_category)) AS sub_category
FROM product;

CREATE OR REPLACE VIEW vw_products_clean AS
SELECT
product_id,
product_name,
UPPER(TRIM(category)) AS category,
UPPER(TRIM(sub_category)) AS sub_category
FROM products;

CREATE OR REPLACE VIEW vw_orders_clean AS
SELECT
order_id,
order_date,
ship_date,
ship_mode,
customer_id,
product_id,
order_year,
outlet_type,
UPPER(TRIM(region)) AS region,
quantity,
sales,
discount,
profit,
CASE
WHEN profit < 0 THEN 'LOSS'
WHEN profit = 0 THEN 'BREAK-EVEN'
ELSE 'PROFIT'
END AS profit_status,

CASE
WHEN discount = 0 THEN 'NO DISCOUNT'
WHEN discount <= 0.10 THEN 'LOW'
WHEN discount <= 0.25 THEN 'MEDIUM'
ELSE 'HIGH'
END AS discount_level,
DATEDIFF(ship_date, order_date) AS shipping_days
FROM orders;

SELECT profit_status, COUNT(*) 
FROM vw_orders_clean
GROUP BY profit_status;

SELECT discount_level, AVG(profit)
FROM vw_orders_clean
GROUP BY discount_level;

-- Overall business health
SELECT
SUM(sales) AS total_sales,
SUM(profit) AS total_profit,
ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_pct
FROM vw_orders_clean;

-- Regional performance
SELECT
region,
SUM(sales) AS total_sales,
SUM(profit) AS total_profit,
ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_pct
FROM vw_orders_clean
GROUP BY region
ORDER BY profit_margin_pct ASC;

-- Discount impact analysis
SELECT
discount_level,
COUNT(*) AS order_count,
ROUND(AVG(sales),2) AS avg_sales,
ROUND(AVG(profit),2) AS avg_profit
FROM vw_orders_clean
GROUP BY discount_level
ORDER BY discount_level;

-- High-risk customers
SELECT
o.customer_id,
c.customer_name,
SUM(o.sales)  AS total_sales,
SUM(o.profit) AS total_profit,
CASE
WHEN SUM(o.profit) < 0 AND SUM(o.sales) > 50000 THEN 'HIGH RISK'
WHEN SUM(o.profit) < 0 THEN 'MEDIUM RISK'
ELSE 'SAFE'
END AS risk_level
FROM vw_orders_clean o
JOIN vw_customers_clean c
ON o.customer_id = c.customer_id
GROUP BY o.customer_id, c.customer_name
ORDER BY total_profit;

-- Product underperformance
SELECT
p.product_name,
p.category,
SUM(o.sales) AS total_sales,
SUM(o.profit) AS total_profit
FROM vw_orders_clean o
JOIN vw_products_clean p
ON o.product_id = p.product_id
GROUP BY p.product_name, p.category
HAVING SUM(o.profit) < 0
ORDER BY total_profit;

-- Shipping delay vs profit
SELECT
CASE
WHEN shipping_days <= 2 THEN 'FAST'
WHEN shipping_days <= 5 THEN 'MEDIUM'
ELSE 'SLOW'
END AS shipping_speed,
COUNT(*) AS order_count,
ROUND(AVG(profit),2) AS avg_profit
FROM vw_orders_clean
GROUP BY shipping_speed;

