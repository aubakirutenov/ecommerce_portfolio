-- 1. Show the 10 earliest orders, sorted by purchase time.
SELECT order_id, order_purchase_timestamp 
FROM olist.orders
order by order_purchase_timestamp ASC
limit 10;

-- 2. List the distinct order statuses.
SELECT distinct order_status FROM olist.orders;

-- 3. Show the orders that were canceled and placed in 2017.
SELECT order_id, order_purchase_timestamp FROM olist.orders
where order_purchase_timestamp like '2017%'
and order_status = 'canceled';

-- 4. Show 20 customers from the state SP, sorted by city.
select customer_unique_id, customer_state, customer_city
from olist.customers
where customer_state = 'SP'
order by customer_city
limit 20;

-- 5. Find the 10 most expensive items in order_items, by price.
select product_id, price
from olist.order_items
order by price desc
limit 10;