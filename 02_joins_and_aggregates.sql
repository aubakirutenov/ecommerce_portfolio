-- 1. List 20 orders with their customer's location, earliest first.
SELECT o.order_id,
       o.order_status,
       o.order_purchase_timestamp,
       c.customer_city,
       c.customer_state
FROM olist.orders AS o
JOIN olist.customers AS c
  ON o.customer_id = c.customer_id
ORDER BY o.order_purchase_timestamp ASC
LIMIT 20;
-- Result: the earliest order was placed on 2016-09-04.

-- 2. Summarize all order items: count, average, lowest, highest, and total price.
SELECT COUNT(*) AS number_of_items,
       ROUND(AVG(price)::numeric, 2) AS average_price,
       MIN(price) AS lowest_price,
       MAX(price) AS highest_price,
       ROUND(SUM(price)::numeric, 2) AS total_price
FROM olist.order_items;
-- Result: 112,650 items, average price 120.65, range 0.85 to 6,735, total about 13.6 million.

-- 3. Find sellers that sold more than 500 items, with their revenue.
SELECT seller_id,
       COUNT(*) AS items_sold,
       ROUND(SUM(price)::numeric, 2) AS total_revenue
FROM olist.order_items
GROUP BY seller_id
HAVING COUNT(*) > 500
ORDER BY total_revenue DESC;
-- Result: 29 sellers sold more than 500 items. The top seller by revenue sold 1,156 items.

-- 4. Count orders with no delivery date, by order status.
SELECT order_status,
       COUNT(*) AS orders_without_delivery_date
FROM olist.orders
WHERE order_delivered_customer_date IS NULL
GROUP BY order_status
ORDER BY orders_without_delivery_date DESC;
-- Result: 2,965 orders have no delivery date; 8 of them are marked delivered.

-- 5. Count orders that have no review at all (LEFT JOIN, keep unmatched rows).
SELECT COUNT(*) AS orders_without_reviews
FROM olist.orders AS o
LEFT JOIN olist.order_reviews AS r
       ON o.order_id = r.order_id
WHERE r.order_id IS NULL;
-- Result: 768 orders have no review (about 0.8% of all orders).