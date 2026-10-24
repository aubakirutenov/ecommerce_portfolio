-- 04_drills.sql
-- SQL drills on four concepts: the GROUP BY rule, WHERE vs. HAVING, FILTER,
-- and LEFT JOIN direction (anti-joins). Data: Olist e-commerce dataset.

-- 1. Find the bug: SELECT seller_id, product_id, COUNT(*) ... GROUP BY seller_id.
-- product_id is neither in GROUP BY nor inside an aggregate, so one seller row
-- could hold many products. Two fixes, answering two different questions:

-- 1a. Add the column to GROUP BY.
SELECT seller_id,
       product_id,
       COUNT(*) AS times_sold
FROM olist.order_items
GROUP BY seller_id, product_id;
-- One row per seller and product: how many times each seller sold each product.

-- 1b. Remove the column from SELECT.
SELECT seller_id,
       COUNT(*) AS items_sold
FROM olist.order_items
GROUP BY seller_id;
-- One row per seller: how many items each seller sold in total (3,095 rows).

-- 2. Orders per state and status, for SP, RJ and MG.
SELECT c.customer_state,
       o.order_status,
       COUNT(o.order_id) AS orders
FROM olist.orders AS o
JOIN olist.customers AS c
  ON o.customer_id = c.customer_id
WHERE c.customer_state IN ('SP', 'RJ', 'MG')
GROUP BY c.customer_state, o.order_status
ORDER BY c.customer_state, orders DESC;
-- One row per state and status. 22 rows, not 3 x 8 = 24: approved + RJ and created + MG
-- have no orders, and GROUP BY only creates rows for combinations that exist.

-- 3. Categories with an average item price above 500.
SELECT p.product_category_name,
       COUNT(*) AS items,
       ROUND(AVG(oi.price)::numeric, 2) AS average_price
FROM olist.order_items AS oi
JOIN olist.products AS p
  ON oi.product_id = p.product_id
GROUP BY p.product_category_name
HAVING AVG(oi.price) > 500
ORDER BY average_price DESC;
-- The condition is on an average of a group, so it goes in HAVING (WHERE runs before
-- groups exist). HAVING repeats AVG(...) because aliases are created later, in SELECT.
-- Result: pcs (1,098.34 over 203 items) and portateis_casa_forno_e_cafe (624.29 over
-- 76 items). Both averages rest on more than 50 items, so they are reliable.

-- 4. Among items priced above 500, categories with more than 50 such items.
SELECT p.product_category_name,
       COUNT(*) AS items_over_500,
       ROUND(AVG(oi.price)::numeric, 2) AS average_price
FROM olist.order_items AS oi
JOIN olist.products AS p
  ON oi.product_id = p.product_id
WHERE oi.price > 500
GROUP BY p.product_category_name
HAVING COUNT(*) > 50
ORDER BY items_over_500 DESC;
-- price > 500 is about one item, so WHERE; the count is about a category, so HAVING.
-- Result: 16 categories. relogios_presentes has the most expensive items (569) but was not
-- in drill 3, because many cheap items pull its average below 500. 202 of 203 pcs items
-- cost more than 500.

-- 5. Find the bug: WHERE COUNT(*) > 1000 fails, because aggregates are not allowed in WHERE.
SELECT order_status,
       COUNT(*) AS orders
FROM olist.orders
GROUP BY order_status
HAVING COUNT(*) > 1000
ORDER BY orders DESC;
-- Result: only delivered (96,478) and shipped (1,107) have more than 1,000 orders.

-- 6. Payments per type, and the share paid in more than one installment.
SELECT payment_type,
       COUNT(*) AS number_of_payments,
       COUNT(*) FILTER (WHERE payment_installments > 1) AS payments_with_more_installments,
       ROUND(100.0 * COUNT(*) FILTER (WHERE payment_installments > 1) / COUNT(*), 1) AS share_pct
FROM olist.order_payments
GROUP BY payment_type
ORDER BY number_of_payments DESC;
-- FILTER goes right after the aggregate it limits. Aliases cannot be reused in the same
-- SELECT, so the share repeats the expressions; 100.0 avoids integer division.
-- Result: only credit cards are paid in installments (66.9% of 76,795 card payments);
-- boleto, voucher and debit card are always paid at once.

-- 7. Orders per year by status group.
SELECT LEFT(order_purchase_timestamp, 4) AS order_year,
       COUNT(*) FILTER (WHERE order_status = 'delivered') AS delivered,
       COUNT(*) FILTER (WHERE order_status = 'canceled') AS canceled,
       COUNT(*) FILTER (WHERE order_status NOT IN ('delivered', 'canceled')) AS other_statuses,
       COUNT(*) AS total_orders
FROM olist.orders
GROUP BY order_year
ORDER BY order_year;
-- FILTER turns statuses into columns, so only the year is in GROUP BY.
-- Check: each row adds up to its total (329 / 45,101 / 54,011), and canceled sums to 625.
-- Finding: about 8% of 2016 orders were canceled (26 of 329), under 1% in 2017 and 2018.

-- 8. Expected: some orders have no items (e.g. canceled or unavailable before items
-- were added), but every item belongs to an order.

-- 8a. Orders without items.
SELECT COUNT(*) AS orders_without_items
FROM olist.orders AS o
LEFT JOIN olist.order_items AS oi
       ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL;
-- Result: 775 orders have no items.

-- 8b. Items without an order (direction reversed).
SELECT COUNT(*) AS items_without_order
FROM olist.order_items AS oi
LEFT JOIN olist.orders AS o
       ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;
-- Result: 0. order_items is a child table: an item cannot exist without its order,
-- but an order can exist without items. The left table is the one checked for gaps.

-- 9. Customers whose zip code prefix is missing from geolocation.
SELECT COUNT(*) AS customers_without_geo
FROM olist.customers AS c
LEFT JOIN olist.geolocation AS g
       ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix
WHERE g.geolocation_zip_code_prefix IS NULL;
-- The IS NULL check must be on the right table: the left table's columns are never NULL.
-- Result: 278 customers (about 0.3%) cannot be placed on a map.
-- Fan-out warning: geolocation has many rows per zip prefix. A normal JOIN would repeat
-- each customer once per matching row, so COUNT(*) would be far above 99,441.
-- Use COUNT(DISTINCT c.customer_id), or reduce geolocation to one row per prefix first.

-- 10. States with at least 1,000 delivered orders, and how many have no review.
SELECT c.customer_state,
       COUNT(DISTINCT o.order_id) AS orders,
       COUNT(DISTINCT o.order_id) FILTER (WHERE r.review_id IS NULL) AS orders_without_reviews
FROM olist.orders AS o
JOIN olist.customers AS c
  ON o.customer_id = c.customer_id
LEFT JOIN olist.order_reviews AS r
       ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY orders_without_reviews DESC;
-- Uses all four concepts. Some orders have several reviews, so the LEFT JOIN repeats them;
-- COUNT(DISTINCT o.order_id) prevents that fan-out.
-- Check: SP has 40,501 delivered orders, the same as drill 2.
-- Result: 598 delivered orders have no review. RJ's rate (139 of 12,350, 1.1%) is about
-- twice SP's (228 of 40,501, 0.6%), which a count-only sort hides.