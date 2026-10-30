--BQ 3: what share of customers are repeat customers, by state?

--3.1 How many items cost more than the average item price?
SELECT COUNT(*) AS items
FROM olist.order_items
WHERE price > (
    SELECT AVG(price)
    FROM olist.order_items
);

--3.2 How many customers placed 1 order, 2 orders, 3 orders…?
SELECT order_count, COUNT(*) AS customer_orders
FROM (
	SELECT customer_unique_id, COUNT(o.order_id) AS order_count
	FROM olist.customers c
	JOIN olist.orders o 
	ON c.customer_id = o.customer_id 
	WHERE o.order_status NOT IN('canceled', 'unavailable')
	GROUP BY c.customer_unique_id
) AS customer_orders
GROUP BY order_count
ORDER BY order_count ASC;

--3.3 The same query as a CTE.
WITH customers_orders AS (
SELECT
	customer_unique_id,
	COUNT(o.order_id) AS order_count
FROM
	olist.customers c
JOIN olist.orders o 
	ON
	c.customer_id = o.customer_id
WHERE
	o.order_status NOT IN('canceled', 'unavailable')
GROUP BY
	c.customer_unique_id
)
SELECT
	order_count,
	COUNT(*) AS customers
FROM
	customers_orders
GROUP BY
	order_count
ORDER BY
	order_count ASC;

--4. Overall share of repeat customers.
WITH customers_orders AS (
SELECT
	customer_unique_id,
	COUNT(o.order_id) AS order_count
FROM
	olist.customers c
JOIN olist.orders o 
	ON
	c.customer_id = o.customer_id
WHERE
	o.order_status NOT IN('canceled', 'unavailable')
GROUP BY
	c.customer_unique_id
)
SELECT
	COUNT(*) AS customers,
	COUNT(*) FILTER (WHERE order_count > 1) AS repeat_customers,
	ROUND(100.0 * COUNT(*) FILTER (WHERE order_count > 1) / COUNT(*), 1) AS repeat_share_pct
FROM
	customers_orders;

--5. Share of repeat customers by state.
WITH customers_orders AS (
SELECT
	c.customer_state,
	c.customer_unique_id,
	COUNT(o.order_id) AS order_count
FROM
	olist.customers c
JOIN olist.orders o 
	ON
	c.customer_id = o.customer_id
WHERE
	o.order_status NOT IN('canceled', 'unavailable')
GROUP BY
	c.customer_state,
	customer_unique_id
),
state_summary AS (
SELECT
	customer_state,
	COUNT(*) AS customers,
	COUNT(*) FILTER (
	WHERE order_count > 1) AS repeat_customers
FROM
	customers_orders
GROUP BY
	customer_state
)
SELECT
	customer_state,
	customers,
	repeat_customers,
	ROUND(100.0 * repeat_customers / customers, 1) AS repeat_share_pct
FROM
	state_summary
WHERE
	customers >= 1000
ORDER BY
	repeat_share_pct DESC;

-- Result: among the 12 states with >= 1,000 customers, the repeat share ranges
-- from 1.6% (CE) to 3.3% (RJ). Repeat buying is low everywhere (overall ~3.0%),
-- so retention is a platform-wide pattern, not a regional one.
-- Assumptions: a customer who ordered from two states counts once in each (option A);
-- states with < 1,000 customers are excluded because their shares are unstable.