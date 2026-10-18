# E-commerce Analytics

An end-to-end analysis of an e-commerce dataset (orders, customers, products, payments). I load the raw data into PostgreSQL, answer business questions with SQL, model the data as a star schema, and present the findings in interactive Tableau dashboards.

## Dataset
[Brazilian E-Commerce Public Dataset by Olist (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce): 99,441 orders placed from September 2016 to October 2018, in 9 CSV files.

## Tools
PostgreSQL, SQL, DBeaver, Tableau, Excel (pivot tables), Git

## Dashboards
[Olist E-commerce Analytics on Tableau Public](https://public.tableau.com/app/profile/aubakirutenov/viz/Olist_17923253755880/Orderspermonth): six charts covering orders, statuses, customers by state, payments, top sellers and price vs. freight.

## Business questions
1. How did monthly revenue and order volume change over time, and when did they peak?
2. Which product categories bring in the most revenue, and which earn the best review scores?
3. What share of customers order more than once, and does this differ by state?
4. What share of orders arrive after the estimated delivery date? How does that differ by customer state, and do late orders get lower review scores?
5. What share of revenue comes from the top 10% of sellers, and which states are those sellers in?

## Definitions
- Revenue: the sum of item prices (price in order_items), excluding shipping, for orders whose status is not canceled or unavailable.
- Order volume: the number of distinct orders, with the same status filter as revenue.
- Customer: one person, identified by customer_unique_id, because customer_id changes with every order.
- Repeat customer: a customer with more than one order.
- Late order: a delivered order whose actual delivery date is after its estimated delivery date. Orders with status delivered but no delivery date (8) are excluded.
- Review score: the 1-5 score in order_reviews. Category averages only include categories with at least 50 reviews.
- Top 10% of sellers: sellers ranked by total revenue (the top 310 of 3,095, rounded).
- Time range: orders from 2016-09-04 to 2018-10-17. The first and last months are partial and not compared with full months.

## Data notes
- Orders per year: 329 in 2016, 45,101 in 2017, 54,011 in 2018. The data starts in September 2016 and ends on 2018-10-17, so the years are not directly comparable.
- About 97% of orders are delivered (96,478). 625 are canceled and 609 are unavailable, and both statuses are excluded from revenue.
- 8 orders are marked delivered but have no delivery date.
- 768 orders (about 0.8%) have no review.
- 29 of 3,095 sellers sold more than 500 items.

## Status
In progress, started October 2026. Data loaded, questions defined, and first SQL exploration done. Monthly analysis and dashboards are next.

## Repo contents
- 00_setup.md: how the database was set up and the data loaded.
- 01_basics.sql: first queries (filtering, sorting, counts).
- 02_joins_and_aggregates.sql: joins, aggregates, GROUP BY, and HAVING, NULL handling.
- 03_dates_and_grouping.sql: monthly trends, top categories, repeat customers, late deliveries.
