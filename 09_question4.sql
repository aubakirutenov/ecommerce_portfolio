-- Question 4: What share of orders arrive after the estimated delivery date? How does that differ
-- by customer state, and do late orders get lower review scores?
-- Late = delivered order with a delivery date after the estimated date (mart.fact_orders.is_late);
-- a delivery on the estimated day counts as on time.

SELECT
	dc.customer_state,
	COUNT(fo.is_late) AS delivered_orders,
	SUM(fo.is_late) AS late_orders,
	ROUND(100.0 * SUM(fo.is_late) / COUNT(fo.is_late), 1) AS late_share_pct
FROM
	mart.fact_orders fo
JOIN mart.dim_customer dc 
ON
	fo.customer_id = dc.customer_id
GROUP BY
	dc.customer_state
HAVING
	COUNT(fo.is_late) >= 1000
ORDER BY 
	late_share_pct DESC;
-- Result: overall 6.77% of 96,470 delivered orders are late. Among the 12 states with at least
-- 1,000 delivered orders, the late share ranges from 4.0% (PR) to 13.8% (CE).
-- The northeast is worst (CE 13.8%, BA 12.2%, PE 9.6%); RJ stands out at 12.1% on 12,350 orders,
-- almost three times SP's 4.5%. Small states (e.g. AL, ~21% in the first pass) are excluded
-- because their shares rest on few orders.

SELECT
	fo.is_late,
	COUNT(fo.is_late) AS delivered_orders,
	COUNT(fo.review_score) AS reviewed_orders,
	ROUND(AVG(fo.review_score), 2) AS avg_review_score
FROM
	mart.fact_orders fo
WHERE
	fo.is_late IS NOT NULL
GROUP BY
	fo.is_late;
-- Result: late orders average 2.27 stars (6,381 reviewed of 6,534), on-time orders 4.29
-- (89,443 of 89,936): a late delivery costs about 2 stars.
-- Orders without an is_late value (not delivered or no delivery date) are excluded with WHERE.
-- Scores are averaged per order first (some orders have several reviews).

