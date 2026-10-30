--1. Number of orders per each order status, most common first.
SELECT
	order_status,
	COUNT(*) AS orders
FROM
	olist.orders
GROUP BY
	order_status
ORDER BY
	orders DESC;

--2. Number of customers and the number of different cities per customer state.
SELECT
	customer_state,
	COUNT(*) AS customer_ids,
	COUNT(DISTINCT customer_unique_id) AS customers,
	COUNT(DISTINCT customer_city) AS cities
FROM
	olist.customers
GROUP BY
	customer_state
ORDER BY
	customers DESC;

--3. Sellers with more than 100 items sold.
SELECT
	seller_id,
	COUNT(*) AS sold_items
FROM
	olist.order_items
GROUP BY
	seller_id
HAVING
	COUNT(*) > 100
ORDER BY
	sold_items DESC;
-- Result: 236 sellers (~7.6% of all sellers) sold more than 100 items.

--4. Delivered orders only: product categories with an average item price above 200 and at least 50 items.
SELECT
	p.product_category_name,
	COUNT(*) AS items,
	ROUND(AVG(oi.price), 2) AS average_item_price
FROM
	olist.order_items oi
JOIN olist.orders o 
ON
	oi.order_id = o.order_id
JOIN olist.products p 
ON
	oi.product_id = p.product_id
WHERE
	o.order_status = 'delivered'
GROUP BY
	p.product_category_name
HAVING
	AVG(oi.price) > 200
	AND COUNT(*) >= 50
ORDER BY
	average_item_price DESC;
-- Result: 8 categories; pcs has the highest average price (1,098.92).

--5. Total orders, delivered orders and canceled orders per each customer state.
SELECT
	c.customer_state,
	COUNT(o.order_id) AS total_orders,
	COUNT(o.order_id) FILTER(WHERE o.order_status = 'delivered') AS delivered_orders,
	COUNT(o.order_id) FILTER(WHERE o.order_status = 'canceled') AS canceled_orders
FROM
	olist.customers c
JOIN olist.orders o 
ON
	c.customer_id = o.customer_id
GROUP BY
	c.customer_state
ORDER BY
	total_orders DESC;
-- Result: 27 states; SP leads with 41,746 orders (40,501 delivered, 327 canceled).
-- Cancellations are rare everywhere (~0.6% overall); RN, AM, AC and AP have none.

--6. Number of payments, how many have payment_installments > 1, and that share in % with 1 decimal
-- per each payment type.
SELECT
	payment_type,
	COUNT(*) AS payments,
	COUNT(*) FILTER (
	WHERE payment_installments > 1) AS more_installments,
	ROUND(100.0 * COUNT(*) FILTER (WHERE payment_installments > 1) / COUNT(*), 1) AS installment_share_pct
FROM
	olist.order_payments
GROUP BY
	payment_type
ORDER BY
	payments DESC;
-- Result: credit cards are 76,795 of 103,886 payments (~74%); 66.9% of them are split into installments.
-- Boleto, voucher and debit card always have 1 installment: only credit cards allow
-- parcelamento (splitting a purchase into monthly payments) in Brazil.
-- 3 payments have payment_type 'not_defined' (data quality note).

--7. Number of products that have no English category name.
SELECT
	p.product_category_name,
	COUNT(*) AS products
FROM
	olist.products p
LEFT JOIN olist.product_category_translation pct 
ON
	p.product_category_name = pct.product_category_name
WHERE
	pct.product_category_name_english IS NULL
GROUP BY
	p.product_category_name
ORDER BY
	products DESC;
-- Result: 623 products have no English category name:
-- 610 have no category at all (NULL), 13 have a category missing from the
-- translation table (portateis_cozinha_e_preparadores_de_alimentos, pc_gamer).

--8. Orders that have no review.
SELECT
	COUNT(*) AS orders_without_review
FROM
	olist.orders o
LEFT JOIN olist.order_reviews r
ON
	o.order_id = r.order_id
WHERE
	r.review_id IS NULL;
  -- Result: 768 orders (~0.8% of 99,441) have no review.

--9. List of orders without items, grouped by order status.
SELECT o.order_status, COUNT(o.order_id) FILTER(WHERE oi.order_item_id IS NULL) AS orders
FROM olist.orders o 
LEFT JOIN olist.order_items oi 
ON o.order_id = oi.order_id 
GROUP BY o.order_status
ORDER BY orders DESC;
-- Result: unavailable: 603 of 609 have no items.The product wasn’t available, so nothing was added to the order.
-- Canceled: 164 of 625. Most canceled orders still have items, so they were canceled after items were added.
-- Shipped: 1 without items. A shipped order with nothing in it is a data quality oddity.

--10. Number of sellers, the total revenue, and the revenue from delivered orders only per seller state
--(only states with at least 10 sellers). Sorted by revenue.
SELECT
	s.seller_state,
	COUNT(DISTINCT s.seller_id) AS sellers,
	ROUND(SUM(oi.price), 2) AS total_revenue,
	ROUND(SUM(oi.price) FILTER(WHERE o.order_status = 'delivered'), 2) AS delivered_orders_revenue
FROM
	olist.order_items oi
LEFT JOIN olist.orders o 
ON
	oi.order_id = o.order_id
LEFT JOIN olist.sellers s 
ON
	oi.seller_id = s.seller_id
GROUP BY
	s.seller_state
HAVING
	COUNT(DISTINCT s.seller_id) >= 10
ORDER BY
	total_revenue DESC;
-- Result: 11 states have at least 10 sellers. SP dominates: 1,849 sellers and
-- 8.75M of revenue (~97% from delivered orders). PR is 2nd in revenue (1.26M)
-- with only 349 sellers.