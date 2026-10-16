# E-commerce Analytics

An end-to-end analysis of an e-commerce dataset (orders, customers, products, payments). I load the raw data into PostgreSQL, answer business questions with SQL, model the data as a star schema, and present the findings in interactive Tableau dashboards.

## Dataset
Brazilian E-Commerce Public Dataset by Olist (Kaggle): 99,441 orders placed from September 2016 to October 2018, in 9 CSV files.
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

## Tools
PostgreSQL, SQL, DBeaver, Tableau, Excel, Git

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
- Late order: a delivered order whose actual delivery date is after its estimated delivery date.
- Review score: the 1-5 score in order_reviews. Category averages only include categories with at least 50 reviews.
- Top 10% of sellers: sellers ranked by total revenue (the top 310 of 3,095, rounded).
- Time range: orders from 2016-09-04 to 2018-10-17. The first and last months are partial and not compared with full months.

## Status
In progress, started October 2026. Data loaded and questions defined. SQL analysis and dashboards are next.

## Repo contents
- 00_setup.md: how the database was set up and the data loaded.
