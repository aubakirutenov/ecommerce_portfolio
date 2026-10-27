CREATE SCHEMA IF NOT EXISTS mart;

DROP TABLE IF EXISTS mart.dim_seller;
CREATE TABLE mart.dim_seller AS 
SELECT seller_id, seller_city, seller_state
FROM olist.sellers;
SELECT COUNT(*) FROM mart.dim_seller;

DROP TABLE IF EXISTS mart.dim_customer;
CREATE TABLE mart.dim_customer AS 
SELECT customer_id, customer_unique_id, customer_city, customer_state
FROM olist.customers;
SELECT COUNT(*) FROM mart.dim_customer;

DROP TABLE IF EXISTS mart.dim_product;
CREATE TABLE mart.dim_product AS 
SELECT p.product_id, p.product_category_name, COALESCE(pct.product_category_name_english, 'unknown') AS product_category_name_english
FROM olist.products p
LEFT JOIN olist.product_category_translation pct
ON p.product_category_name = pct.product_category_name;
SELECT COUNT(*) FROM mart.dim_product;
SELECT COUNT(*) FROM mart.dim_product WHERE product_category_name_english = 'unknown';

DROP TABLE IF EXISTS mart.dim_date;
CREATE TABLE mart.dim_date AS
SELECT
    d::date AS date,
    EXTRACT(YEAR FROM d)::int AS year,
    EXTRACT(QUARTER FROM d)::int AS quarter,
    EXTRACT(MONTH FROM d)::int AS month,
    TO_CHAR(d, 'Mon') AS month_name,
    TO_CHAR(d, 'YYYY-MM') AS year_month,
    TO_CHAR(d, 'Dy') AS weekday_name
FROM generate_series('2016-09-01'::date, '2018-10-31'::date, interval '1 day') AS d;
SELECT COUNT(*) FROM mart.dim_date;
SELECT * FROM mart.dim_date WHERE date = '2017-11-24';
SELECT COUNT(DISTINCT year_month) FROM mart.dim_date;

DROP TABLE IF EXISTS mart.fact_order_items;
CREATE TABLE mart.fact_order_items AS
SELECT
	oi.order_id,
	oi.order_item_id,
	oi.product_id,
	oi.seller_id,
	o.customer_id,
	o.order_status,
	o.order_purchase_timestamp::date AS purchase_date,
	oi.price,
	oi.freight_value
FROM
	olist.order_items oi
JOIN olist.orders o
ON
	oi.order_id = o.order_id;
SELECT COUNT(*) FROM mart.fact_order_items;
SELECT pg_typeof(purchase_date) FROM mart.fact_order_items LIMIT 1;
SELECT SUM(price)
FROM mart.fact_order_items
WHERE order_status NOT IN ('canceled', 'unavailable');

-- Test 1: dimension keys are unique (rows_total must equal keys_unique).
SELECT COUNT(*) AS rows_total, COUNT(DISTINCT seller_id) AS keys_unique
FROM mart.dim_seller;

SELECT COUNT(*) AS rows_total, COUNT(DISTINCT customer_id) AS keys_unique
FROM mart.dim_customer;

SELECT COUNT(*) AS rows_total, COUNT(DISTINCT product_id) AS keys_unique
FROM mart.dim_product;

SELECT COUNT(*) AS rows_total, COUNT(DISTINCT date) AS keys_unique
FROM mart.dim_date;

-- Test 2: no orphans (every fact row finds its dimension row; each query must return 0).

SELECT COUNT(*) AS orphans
FROM mart.fact_order_items f
LEFT JOIN mart.dim_seller s ON f.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

SELECT COUNT(*) AS orphans
FROM mart.fact_order_items f
LEFT JOIN mart.dim_customer c ON f.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS orphans
FROM mart.fact_order_items f
LEFT JOIN mart.dim_product p ON f.product_id = p.product_id
WHERE p.product_id IS NULL;

SELECT COUNT(*) AS orphans
FROM mart.fact_order_items f
LEFT JOIN mart.dim_date d ON f.purchase_date = d.date
WHERE d.date IS NULL;

-- Final check: fact joined to all 4 dimensions keeps all 112,650 rows.

SELECT COUNT(*)
FROM mart.fact_order_items f
JOIN mart.dim_seller s   ON f.seller_id = s.seller_id
JOIN mart.dim_customer c ON f.customer_id = c.customer_id
JOIN mart.dim_product p  ON f.product_id = p.product_id
JOIN mart.dim_date d     ON f.purchase_date = d.date;
-- Validation: revenue (not canceled/unavailable) = 13,494,400.74, the same as 07_question5_v2.sql.
