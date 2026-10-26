ALTER TABLE olist.order_items ALTER COLUMN price TYPE NUMERIC(10, 2);

ALTER TABLE olist.order_items ALTER COLUMN freight_value TYPE NUMERIC(10, 2);

ALTER TABLE olist.order_payments ALTER COLUMN payment_value TYPE NUMERIC(10, 2);