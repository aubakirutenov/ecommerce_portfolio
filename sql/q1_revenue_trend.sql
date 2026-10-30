--1. Number of customers and each state’s share of all customers in % per each state.
WITH customers_per_state AS (
SELECT
	c.customer_state,
	COUNT(DISTINCT c.customer_unique_id) AS customers
FROM
	olist.customers c
JOIN olist.orders o
ON
	c.customer_id = o.customer_id
WHERE
	o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY
	c.customer_state
)
SELECT
	customer_state,
	customers,
	SUM(customers) OVER () AS total_customers,
	ROUND(100.0 * customers / SUM(customers) OVER (), 1) AS share_in_pct
FROM
	customers_per_state
ORDER BY
	share_in_pct DESC;
-- Result: SP 41.8%, RJ 12.9% and MG 11.7% of customers: two thirds (66.4%) live in 3 of 27 states.
-- The total is 95,028, not 94,990: 38 customers ordered from two states and count once in each.
--2. Monthly revenue with month-over-month growth.
WITH monthly AS (
SELECT 
	LEFT(o.order_purchase_timestamp, 7) AS order_month,
	SUM(oi.price) AS revenue
FROM
	olist.order_items oi
JOIN olist.orders o 
ON
	oi.order_id = o.order_id
WHERE
	LEFT(o.order_purchase_timestamp, 7) BETWEEN '2017-01' AND '2018-08'
		AND o.order_status NOT IN ('canceled', 'unavailable')
	GROUP BY
		order_month
)
SELECT
	order_month,
	revenue,
	LAG(revenue) OVER (
	ORDER BY order_month) AS previous,
	ROUND((revenue - LAG(revenue) OVER (ORDER BY order_month)) / LAG(revenue) OVER (ORDER BY order_month) * 100.0, 1) AS growth_pct
FROM
	monthly
ORDER BY
	order_month;
-- Result: 20 full months (2017-01 to 2018-08). The biggest jump is Nov 2017 (+52.1%, Black Friday),
-- followed by Dec 2017 (-26.1%). Jan 2017 growth is NULL: LAG has no previous row in the result.
-- Partial months are excluded; otherwise the last one would show a fake collapse.
--3. Running revenue total.
WITH monthly AS (
SELECT 
	LEFT(o.order_purchase_timestamp, 7) AS order_month,
	SUM(oi.price) AS revenue
FROM
	olist.order_items oi
JOIN olist.orders o 
ON
	oi.order_id = o.order_id
WHERE
	LEFT(o.order_purchase_timestamp, 7) BETWEEN '2017-01' AND '2018-08'
		AND o.order_status NOT IN ('canceled', 'unavailable')
	GROUP BY
		order_month
)
SELECT
	order_month,
	revenue,
	LAG(revenue) OVER (
	ORDER BY order_month) AS previous,
	ROUND((revenue - LAG(revenue) OVER (ORDER BY order_month)) / LAG(revenue) OVER (ORDER BY order_month) * 100.0, 1) AS growth_pct,
	SUM(revenue) OVER (
	ORDER BY order_month) AS running_revenue
FROM
	monthly
ORDER BY
	order_month;
-- Result: cumulative revenue reaches 13,449,529.68 by 2018-08 (matches the sum of monthly revenue).
-- 2017 grows almost every month; 2018 is flat (monthly growth between -13.1% and +17.1%).
--4. Top seller in each state.
WITH revenue_per_seller AS (
SELECT
	s.seller_id,
	s.seller_state,
	SUM(oi.price) AS revenue
FROM
	olist.order_items oi
JOIN olist.sellers s 
ON
	oi.seller_id = s.seller_id
JOIN olist.orders o 
ON
	oi.order_id = o.order_id
WHERE
	o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY
	s.seller_id,
	s.seller_state
),
ranked AS (
SELECT
	seller_id,
	seller_state,
	revenue,
	RANK() OVER (PARTITION BY seller_state
ORDER BY
	revenue DESC) AS seller_rank,
	DENSE_RANK() OVER (PARTITION BY seller_state
ORDER BY
	revenue DESC) AS seller_dense_rank,
	ROW_NUMBER() OVER (PARTITION BY seller_state
ORDER BY
	revenue DESC) AS row_num
FROM
	revenue_per_seller
)
SELECT
	seller_id,
	seller_state,
	revenue,
	seller_rank
FROM
	ranked
WHERE
	seller_rank = 1
ORDER BY
	revenue DESC;
-- Result: one top seller in each of the 23 seller states (no ties at rank 1).
-- The size differs hugely: BA's top seller made 222,776.05, AC's only 267.
-- The rank filter is outside the CTE because window functions run after WHERE.
