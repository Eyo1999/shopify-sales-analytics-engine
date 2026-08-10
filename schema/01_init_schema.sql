-- Disable notice messages for clean execution
SET client_min_messages = warning;

-- Drop existing tables in correct dependency order
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS addresses CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS channels CASCADE;

-- 1. CHANNELS TABLE
CREATE TABLE channels (
    channel_id SERIAL PRIMARY KEY,
    channel_name VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. CUSTOMERS TABLE
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    shopify_customer_id VARCHAR(50) UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. ADDRESSES TABLE
CREATE TABLE addresses (
    address_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id) ON DELETE CASCADE,
    address1 VARCHAR(255) NOT NULL,
    address2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    province_code VARCHAR(10),
    country_code VARCHAR(10) NOT NULL,
    zip_code VARCHAR(20)
);

-- 4. PRODUCTS TABLE
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    sku VARCHAR(100) NOT NULL UNIQUE,
    title VARCHAR(255) NOT NULL,
    variant_title VARCHAR(100),
    unit_price NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. ORDERS TABLE
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    shopify_order_name VARCHAR(50) NOT NULL UNIQUE,
    customer_id INT REFERENCES customers(customer_id) ON DELETE RESTRICT,
    channel_id INT REFERENCES channels(channel_id) ON DELETE RESTRICT,
    order_date TIMESTAMP WITH TIME ZONE NOT NULL,
    financial_status VARCHAR(50) NOT NULL DEFAULT 'pending',
    fulfillment_status VARCHAR(50) NOT NULL DEFAULT 'unfulfilled',
    subtotal NUMERIC(10, 2) NOT NULL CHECK (subtotal >= 0),
    tax_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (tax_amount >= 0),
    shipping_fee NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (shipping_fee >= 0),
    total_discount NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (total_discount >= 0),
    total_price NUMERIC(10, 2) NOT NULL CHECK (total_price >= 0)
);

-- 6. ORDER ITEMS TABLE (Junction Table)
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INT REFERENCES products(product_id) ON DELETE RESTRICT,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
    item_discount NUMERIC(10, 2) DEFAULT 0.00 CHECK (item_discount >= 0)
);

-- PERFORMANCE INDEXES (FOR INSTANT REPORTING ON LARGE DATASETS)
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_orders_channel ON orders(channel_id);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);
CREATE INDEX idx_products_sku ON products(sku);