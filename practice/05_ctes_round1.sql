-- 05_ctes_round1.sql
-- Business question 3: what share of customers order more than once, and does it differ by state?
-- A customer is one person (customer_unique_id), because customer_id changes with every order.

-- 1. How many customers ordered once, twice, three times, ...
-- Two levels of grouping: first orders per customer (CTE), then customers per order count.
WITH customer_orders AS (
    SELECT c.customer_unique_id,
           COUNT(o.order_id) AS order_count
    FROM olist.customers AS c
    JOIN olist.orders AS o
      ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT order_count,
       COUNT(*) AS customers
FROM customer_orders
GROUP BY order_count
ORDER BY order_count;
-- Result: 96,096 customers. 93,099 (96.9%) ordered only once; 2,997 (3.1%) came back.
-- The most loyal customer has 17 orders.

-- 2. Repeat customers by state (states with at least 1,000 customers).
WITH customer_orders AS (
    SELECT c.customer_unique_id,
           c.customer_state,
           COUNT(o.order_id) AS order_count
    FROM olist.customers AS c
    JOIN olist.orders AS o
      ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id, c.customer_state
)
SELECT customer_state,
       COUNT(*) AS customers,
       COUNT(*) FILTER (WHERE order_count > 1) AS repeat_customers,
       ROUND(100.0 * COUNT(*) FILTER (WHERE order_count > 1) / COUNT(*), 1) AS repeat_pct
FROM customer_orders
GROUP BY customer_state
HAVING COUNT(*) >= 1000
ORDER BY repeat_pct DESC;
-- Result: repeat rates range only from 1.7% (CE) to 3.4% (RJ). Low retention is
-- platform-wide, not a regional problem.
-- Limitation: a customer with orders from two states counts once in each, so the
-- state totals add up to slightly more than 96,096.

-- 3. Task 1 rewritten with a subquery in FROM instead of a CTE.
SELECT order_count,
       COUNT(*) AS customers
FROM (
    SELECT c.customer_unique_id,
           COUNT(o.order_id) AS order_count
    FROM olist.customers AS c
    JOIN olist.orders AS o
      ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
) AS customer_orders
GROUP BY order_count
ORDER BY order_count;
-- Same 9 rows as task 1. A subquery in FROM must have a name (AS customer_orders).
-- CTEs read top to bottom, step by step; nested subqueries read from the inside out,
-- which gets hard to follow with more than one step.