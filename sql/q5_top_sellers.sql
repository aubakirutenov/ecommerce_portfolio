-- Question 5: What share of revenue comes from the top 10% of sellers, and which states are those sellers in?
-- Revenue = item prices of orders that are not canceled or unavailable (all months).

--1. Revenue per seller, plus each seller’s decile, with a check of the group sizes.
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
deciled AS (
SELECT
	NTILE(10) OVER (
	ORDER BY revenue DESC) AS decile,
	seller_id,
	seller_state,
	revenue
FROM
	revenue_per_seller 
)
SELECT
	decile,
	COUNT(*) AS sellers
FROM
	deciled
GROUP BY
	decile
ORDER BY
	decile ASC;
-- Result: 3,053 sellers with revenue, split into 10 deciles with NTILE(10).
-- 3,053 / 10 = 305.3, so deciles 1-3 hold 306 sellers and deciles 4-10 hold 305.
-- Check: without the status filter all 3,095 sellers appear; 42 sellers had only
-- canceled/unavailable orders, so they have no revenue and are not ranked.

--2. Number of sellers, the revenue, and the share of total revenue per each decile.
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
deciled AS (
SELECT
	NTILE(10) OVER (
ORDER BY
	revenue DESC) AS decile,
	seller_id,
	seller_state,
	revenue
FROM
	revenue_per_seller 
)
SELECT
	decile,
	COUNT(*) AS sellers,
	SUM(revenue) AS revenue,
	ROUND(100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1) AS share_in_pct
FROM
	deciled
GROUP BY
	decile
ORDER BY
	decile ASC;
-- Result: the top 10% of sellers (decile 1, 306 sellers) bring 67.5% of revenue (9.11M of 13.49M).
-- The top 20% bring 82.6%; the bottom half (deciles 6-10, about 1,525 sellers) only 3.3%.
-- Total is 13.49M, not 13.45M as in q1_revenue_trend.sql, because all months are included here.
-- SUM(SUM(revenue)) OVER (): the inner SUM is the GROUP BY aggregate, the outer one the window total.

--3. Where the top-decile sellers are: their states, compared with all sellers
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
deciled AS (
SELECT
	NTILE(10) OVER (
ORDER BY
	revenue DESC) AS decile,
	seller_id,
	seller_state,
	revenue
FROM
	revenue_per_seller 
)
SELECT
	seller_state,
	COUNT(*) AS all_sellers,
	COUNT(*) FILTER (
	WHERE decile = 1) AS top_sellers,
	ROUND(100.0 * COUNT(*) FILTER (WHERE decile = 1) / SUM(COUNT(*) FILTER (WHERE decile = 1)) OVER (), 1) AS top_share_pct,
	ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS all_share_pct
FROM
	deciled
GROUP BY
	seller_state
ORDER BY
	top_sellers DESC;
-- Result: 61.1% of top sellers are in SP, close to SP's 59.7% share of all sellers.
-- MG is over-represented (10.1% of top sellers vs. 7.9% of all sellers: 12.9% of MG sellers
-- are top sellers, against 10% overall); RJ (8.8%) and SC (8.6%) are slightly under.
-- States with only a few sellers (e.g. MA with 1 seller, who is a top seller) are not compared.