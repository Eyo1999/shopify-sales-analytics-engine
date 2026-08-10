-- Disable notice messages for clean execution
SET client_min_messages = warning;

-- Drop existing views in correct order
DROP VIEW IF EXISTS view_channel_performance CASCADE;
DROP VIEW IF EXISTS view_customer_lifetime_value CASCADE;
DROP VIEW IF EXISTS view_product_sales_performance CASCADE;
DROP VIEW IF EXISTS view_monthly_revenue_growth CASCADE;

-- 1. CHANNEL PERFORMANCE & ATTRIBUTION VIEW
-- Business Goal: Show revenue, order volume, and average order value (AOV) across sales channels.
CREATE VIEW view_channel_performance AS
SELECT 
    ch.channel_name,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.total_price), 2) AS total_revenue,
    ROUND(AVG(o.total_price), 2) AS average_order_value,
    ROUND(SUM(o.total_discount), 2) AS total_discounts_given
FROM channels ch
JOIN orders o ON ch.channel_id = o.channel_id
WHERE o.financial_status = 'paid'
GROUP BY ch.channel_name
ORDER BY total_revenue DESC;

-- 2. CUSTOMER LIFETIME VALUE (CLV) & DECILE RANKING
-- Business Goal: Segment buyers into revenue deciles (Top 10% vs typical buyers) using Window Functions.
CREATE VIEW view_customer_lifetime_value AS
WITH customer_aggregates AS (
    SELECT 
        c.customer_id,
        c.email,
        c.first_name || ' ' || c.last_name AS customer_name,
        COUNT(o.order_id) AS total_orders,
        ROUND(SUM(o.total_price), 2) AS total_spent,
        MIN(o.order_date) AS first_order_date,
        MAX(o.order_date) AS latest_order_date
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.financial_status = 'paid'
    GROUP BY c.customer_id, c.email, c.first_name, c.last_name
)
SELECT 
    customer_id,
    email,
    customer_name,
    total_orders,
    total_spent,
    first_order_date,
    latest_order_date,
    NTILE(10) OVER (ORDER BY total_spent DESC) AS clv_decile
FROM customer_aggregates;

-- 3. PRODUCT SALES PERFORMANCE & CONVERSION REPORT
-- Business Goal: Identify top-performing SKUs, total units sold, and net revenue generated.
CREATE VIEW view_product_sales_performance AS
SELECT 
    p.sku,
    p.title AS product_name,
    p.variant_title,
    SUM(oi.quantity) AS total_units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS gross_revenue,
    ROUND(SUM(oi.item_discount), 2) AS total_discounts,
    ROUND(SUM((oi.quantity * oi.unit_price) - oi.item_discount), 2) AS net_revenue
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.financial_status = 'paid'
GROUP BY p.sku, p.title, p.variant_title
ORDER BY net_revenue DESC;

-- 4. MONTHLY REVENUE TREND & MOM GROWTH VIEW
-- Business Goal: Tracks month-over-month (MoM) revenue growth using LAG() window functions.
CREATE VIEW view_monthly_revenue_growth AS
WITH monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS sales_month,
        COUNT(order_id) AS total_orders,
        ROUND(SUM(total_price), 2) AS monthly_revenue
    FROM orders
    WHERE financial_status = 'paid'
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT 
    TO_CHAR(sales_month, 'YYYY-MM') AS month,
    total_orders,
    monthly_revenue,
    LAG(monthly_revenue, 1) OVER (ORDER BY sales_month) AS previous_month_revenue,
    ROUND(
        ((monthly_revenue - LAG(monthly_revenue, 1) OVER (ORDER BY sales_month)) / 
        NULLIF(LAG(monthly_revenue, 1) OVER (ORDER BY sales_month), 0)) * 100, 2
    ) AS mom_growth_percentage
FROM monthly_sales
ORDER BY sales_month ASC;