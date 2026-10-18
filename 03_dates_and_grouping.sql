-- 1. Orders per month.
SELECT LEFT(order_purchase_timestamp, 7) AS order_month,
       COUNT(order_id) AS orders
FROM olist.orders
GROUP BY order_month
ORDER BY order_month;
-- Result: orders peak in 2017-11 (7,544), likely Black Friday. 2018 stays at about 6,200-7,300 per month.
-- Edge months are incomplete (2016-12: 1, 2018-09: 16, 2018-10: 4) and should be excluded from trends.

-- 2. Revenue per month (excluding canceled and unavailable orders).
SELECT LEFT(o.order_purchase_timestamp, 7) AS order_month,
       ROUND(SUM(oi.price)::numeric, 2) AS revenue
FROM olist.orders AS o
JOIN olist.order_items AS oi
  ON o.order_id = oi.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY order_month
ORDER BY order_month;
-- Result: revenue also peaks in 2017-11 (about 1.0 million). Several 2018 months come close
-- with fewer orders, which suggests higher order values. 2018-10 has no revenue.

-- 3. Top 10 product categories by revenue (items without an English category kept as 'unknown').
SELECT COALESCE(t.product_category_name_english, 'unknown') AS category,
       ROUND(SUM(oi.price)::numeric, 2) AS total_revenue
FROM olist.order_items AS oi
LEFT JOIN olist.products AS p
       ON oi.product_id = p.product_id
LEFT JOIN olist.product_category_translation AS t
       ON p.product_category_name = t.product_category_name
GROUP BY category
ORDER BY total_revenue DESC
LIMIT 10;
-- Result: health_beauty (about 1.26 million), watches_gifts (1.20 million) and bed_bath_table
-- (1.04 million) lead. 'unknown' is not in the top 10.

-- 3b. Item rows without an English category name.
SELECT COUNT(*) AS all_items,
       COUNT(*) FILTER (WHERE p.product_category_name IS NULL) AS no_category,
       COUNT(*) FILTER (WHERE p.product_category_name IS NOT NULL
                          AND t.product_category_name_english IS NULL) AS no_translation
FROM olist.order_items AS oi
LEFT JOIN olist.products AS p
       ON oi.product_id = p.product_id
LEFT JOIN olist.product_category_translation AS t
       ON p.product_category_name = t.product_category_name;
-- Result: 1,627 of 112,650 items (1.4%) have no English category: 1,603 have no category,
-- 24 have an untranslated one. An inner join would drop them silently.

-- 4. Ten customers with the most orders (one person = customer_unique_id).
SELECT c.customer_unique_id,
       COUNT(o.order_id) AS order_count
FROM olist.customers AS c
JOIN olist.orders AS o
  ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
ORDER BY order_count DESC
LIMIT 10;
-- Result: the top customer has 17 orders; the rest of the top 10 have 6-7. Repeat buying is rare.

-- 5. Share of delivered orders that arrived after the estimated date (compared by day).
SELECT ROUND(
         100.0 * COUNT(*) FILTER (WHERE LEFT(order_delivered_customer_date, 10)
                                      > LEFT(order_estimated_delivery_date, 10))
         / COUNT(*), 2) AS late_pct
FROM olist.orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;
-- Result: 6.77% of delivered orders arrived after the estimated day.
-- Comparing full timestamps gives 8.11%, because same-day deliveries would count as late.