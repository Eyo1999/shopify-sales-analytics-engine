\timing on

BEGIN;

-- 1. UNLOGGED STAGING TABLE (Bypasses WAL logging for ultra-fast bulk execution)
CREATE UNLOGGED TABLE staging_bulk (
    order_name VARCHAR(50),
    email VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(50),
    address1 VARCHAR(255),
    address2 VARCHAR(255),
    city VARCHAR(100),
    province_code VARCHAR(10),
    country_code VARCHAR(10),
    zip VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE,
    financial_status VARCHAR(50),
    fulfillment_status VARCHAR(50),
    subtotal NUMERIC(10, 2),
    tax NUMERIC(10, 2),
    shipping NUMERIC(10, 2),
    discount NUMERIC(10, 2),
    total NUMERIC(10, 2),
    line_quantity INT,
    line_price NUMERIC(10, 2),
    line_discount NUMERIC(10, 2),
    line_sku VARCHAR(100),
    line_title VARCHAR(255),
    line_variant VARCHAR(100),
    sales_channel VARCHAR(50)
);

-- 2. COPY RAW CSV DATA INTO STAGING
\copy staging_bulk FROM 'data/shopify_bulk_50k.csv' WITH (FORMAT csv, HEADER true);

-- 3. BULK INGEST CHANNELS
INSERT INTO channels (channel_name)
SELECT DISTINCT sales_channel FROM staging_bulk
ON CONFLICT (channel_name) DO NOTHING;

-- 4. BULK INGEST CUSTOMERS
INSERT INTO customers (email, first_name, last_name, phone)
SELECT email, first_name, last_name, phone
FROM (
    SELECT DISTINCT ON (email) email, first_name, last_name, phone
    FROM staging_bulk
) sub
ON CONFLICT (email) DO UPDATE 
SET first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name;

-- 5. BULK INGEST ADDRESSES
INSERT INTO addresses (customer_id, address1, address2, city, province_code, country_code, zip_code)
SELECT DISTINCT 
    c.customer_id, s.address1, s.address2, s.city, s.province_code, s.country_code, s.zip
FROM staging_bulk s
JOIN customers c ON s.email = c.email
ON CONFLICT DO NOTHING;

-- 6. BULK INGEST PRODUCTS
INSERT INTO products (sku, title, variant_title, unit_price)
SELECT sku, title, variant_title, unit_price
FROM (
    SELECT DISTINCT ON (line_sku) line_sku as sku, line_title as title, line_variant as variant_title, line_price as unit_price
    FROM staging_bulk
) sub
ON CONFLICT (sku) DO UPDATE
SET unit_price = EXCLUDED.unit_price;

-- 7. BULK INGEST ORDERS
INSERT INTO orders (shopify_order_name, customer_id, channel_id, order_date, financial_status, fulfillment_status, subtotal, tax_amount, shipping_fee, total_discount, total_price)
SELECT DISTINCT ON (s.order_name)
    s.order_name,
    c.customer_id,
    ch.channel_id,
    s.created_at,
    s.financial_status,
    s.fulfillment_status,
    s.subtotal,
    s.tax,
    s.shipping,
    s.discount,
    s.total
FROM staging_bulk s
JOIN customers c ON s.email = c.email
JOIN channels ch ON s.sales_channel = ch.channel_name
ON CONFLICT (shopify_order_name) DO NOTHING;

-- 8. BULK INGEST ORDER ITEMS
INSERT INTO order_items (order_id, product_id, quantity, unit_price, item_discount)
SELECT 
    o.order_id,
    p.product_id,
    s.line_quantity,
    s.line_price,
    s.line_discount
FROM staging_bulk s
JOIN orders o ON s.order_name = o.shopify_order_name
JOIN products p ON s.line_sku = p.sku;

-- CLEANUP
DROP TABLE staging_bulk;

COMMIT;