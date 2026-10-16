# Project setup

## Dataset
Brazilian E-Commerce Public Dataset by Olist (Kaggle): https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

## Database
- PostgreSQL (Postgres.app) on macOS, with DBeaver as the SQL client
- Database: ecommerce_portfolio
- Schema: olist

## Loading the data
1. Created the schema with CREATE SCHEMA olist;
2. Loaded the 9 CSV files into tables in that schema.
3. The reviews file has multi-line comments that broke DBeaver's CSV importer, so I created that table with text columns and loaded it with psql's \copy instead.

## Row counts after loading
- orders: 99,441
- customers: 99,441
- order_items: 112,650
- order_payments: 103,886
- order_reviews: 99,224
- products: 32,951
- sellers: 3,095
- product_category_translation: 71
- geolocation: 1,000,163
