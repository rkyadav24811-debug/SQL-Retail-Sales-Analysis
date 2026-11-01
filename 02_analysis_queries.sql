-- =====================================================================
-- Retail Sales Analysis | 15 business questions answered with SQL
-- Run 01_schema_and_data.sql first.   Works on MySQL 8+ / MariaDB 10.5+
-- Revenue = quantity * unit_price * (1 - discount_pct/100)
-- Only orders with status 'Delivered' or 'Shipped' count as revenue.
-- =====================================================================
USE retail_db;

-- ---------------------------- LEVEL 1: BASICS ------------------------

-- Q1. Business snapshot: how big is the data and what is total revenue?
SELECT
    (SELECT COUNT(*) FROM customers) AS total_customers,
    (SELECT COUNT(*) FROM orders)    AS total_orders,
    ROUND(SUM(oi.quantity * p.unit_price * (1 - oi.discount_pct/100)), 2) AS total_revenue
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN orders o   ON o.order_id   = oi.order_id
WHERE o.status IN ('Delivered', 'Shipped');

-- Q2. How are orders split by status (with % share)?
SELECT status,
       COUNT(*) AS orders,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 1) AS pct_of_orders
FROM orders
GROUP BY status
ORDER BY orders DESC;

-- Q3. Which payment method do customers prefer?
SELECT payment_method,
       COUNT(*) AS orders,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_share
FROM orders
GROUP BY payment_method
ORDER BY orders DESC;

-- ---------------------------- LEVEL 2: JOINS + AGGREGATION -----------

-- Q4. Revenue and units sold by product category.
SELECT p.category,
       SUM(oi.quantity) AS units_sold,
       ROUND(SUM(oi.quantity * p.unit_price * (1 - oi.discount_pct/100)), 2) AS revenue
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN orders o   ON o.order_id   = oi.order_id
WHERE o.status IN ('Delivered', 'Shipped')
GROUP BY p.category
ORDER BY revenue DESC;

-- Q5. Top 5 products by revenue.
SELECT p.product_name, p.category,
       SUM(oi.quantity) AS units_sold,
       ROUND(SUM(oi.quantity * p.unit_price * (1 - oi.discount_pct/100)), 2) AS revenue
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN orders o   ON o.order_id   = oi.order_id
WHERE o.status IN ('Delivered', 'Shipped')
GROUP BY p.product_id, p.product_name, p.category
ORDER BY revenue DESC
LIMIT 5;

-- Q6. Which cities bring the most revenue, and what is their average order value?
SELECT c.city,
       COUNT(DISTINCT o.order_id) AS orders,
       ROUND(SUM(oi.quantity * p.unit_price * (1 - oi.discount_pct/100)), 2) AS revenue,
       ROUND(SUM(oi.quantity * p.unit_price * (1 - oi.discount_pct/100))
             / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM customers c
JOIN orders o       ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id   = o.order_id
JOIN products p     ON p.product_id  = oi.product_id
WHERE o.status IN ('Delivered', 'Shipped')
GROUP BY c.city
ORDER BY revenue DESC;

-- Q7. Monthly revenue trend.
SELECT DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
       COUNT(DISTINCT o.order_id) AS orders,
       ROUND(SUM(oi.quantity * p.unit_price * (1 - oi.discount_pct/100)), 2) AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id  = o.order_id
JOIN products p     ON p.product_id = oi.product_id
WHERE o.status IN ('Delivered', 'Shipped')
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY order_month;

-- Q8. Customers who signed up but never placed an order (LEFT JOIN + IS NULL).
SELECT c.customer_id, c.customer_name, c.city, c.signup_date
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL
ORDER BY c.signup_date;

-- Q9. Cancellation rate by payment method (CASE WHEN inside aggregation).
SELECT payment_method,
       COUNT(*) AS total_orders,
       SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled,
       ROUND(SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS cancel_rate_pct
FROM orders
GROUP BY payment_method
ORDER BY cancel_rate_pct DESC;

-- Q10. Cities with at least 20 orders (HAVING).
SELECT c.city, COUNT(*) AS orders
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY c.city
HAVING COUNT(*) >= 20
ORDER BY orders DESC;

-- ---------------------------- LEVEL 3: SUBQUERIES, CTEs, WINDOWS -----

-- Q11. Customers who spent MORE than the average customer (subquery).
SELECT customer_name, total_spent
FROM (
    SELECT c.customer_name,
           ROUND(SUM(oi.quantity * p.unit_price * (1 - oi.discount_pct/100)), 2) AS total_spent
    FROM customers c
    JOIN orders o       ON o.customer_id = c.customer_id
    JOIN order_items oi ON oi.order_id   = o.order_id
    JOIN products p     ON p.product_id  = oi.product_id
    WHERE o.status IN ('Delivered', 'Shipped')
    GROUP BY c.customer_id, c.customer_name
) t
WHERE total_spent > (
    SELECT AVG(total_spent) FROM (
        SELECT SUM(oi.quantity * p.unit_price * (1 - oi.discount_pct/100)) AS total_spent
        FROM orders o
        JOIN order_items oi ON oi.order_id  = o.order_id
        JOIN products p     ON p.product_id = oi.product_id
        WHERE o.status IN ('Delivered', 'Shipped')
        GROUP BY o.customer_id
    ) x
)
ORDER BY total_spent DESC;

-- Q12. Top 3 products inside each category (CTE + RANK window function).
WITH product_rev AS (
    SELECT p.category, p.product_name,
           SUM(oi.quantity * p.unit_price * (1 - oi.discount_pct/100)) AS revenue
    FROM order_items oi
    JOIN products p ON p.product_id = oi.product_id
    JOIN orders o   ON o.order_id   = oi.order_id
    WHERE o.status IN ('Delivered', 'Shipped')
    GROUP BY p.product_id, p.category, p.product_name
),
ranked AS (
    SELECT *, RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rnk
    FROM product_rev
)
SELECT category, product_name, ROUND(revenue, 2) AS revenue, rnk
FROM ranked
WHERE rnk <= 3
ORDER BY category, rnk;

-- Q13. Month-over-month revenue growth % (CTE + LAG).
WITH monthly AS (
    SELECT DATE_FORMAT(o.order_date, '%Y-%m') AS ym,
           SUM(oi.quantity * p.unit_price * (1 - oi.discount_pct/100)) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id  = o.order_id
    JOIN products p     ON p.product_id = oi.product_id
    WHERE o.status IN ('Delivered', 'Shipped')
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT ym,
       ROUND(revenue, 2) AS revenue,
       ROUND(LAG(revenue) OVER (ORDER BY ym), 2) AS prev_month,
       ROUND((revenue - LAG(revenue) OVER (ORDER BY ym))
             * 100.0 / LAG(revenue) OVER (ORDER BY ym), 1) AS growth_pct
FROM monthly
ORDER BY ym;

-- Q14. Running (cumulative) revenue over time (window SUM).
WITH monthly AS (
    SELECT DATE_FORMAT(o.order_date, '%Y-%m') AS ym,
           SUM(oi.quantity * p.unit_price * (1 - oi.discount_pct/100)) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id  = o.order_id
    JOIN products p     ON p.product_id = oi.product_id
    WHERE o.status IN ('Delivered', 'Shipped')
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT ym,
       ROUND(revenue, 2) AS revenue,
       ROUND(SUM(revenue) OVER (ORDER BY ym), 2) AS cumulative_revenue
FROM monthly
ORDER BY ym;

-- Q15. Repeat vs one-time customers (CTE + CASE).
WITH cust_orders AS (
    SELECT customer_id, COUNT(*) AS order_count
    FROM orders
    WHERE status IN ('Delivered', 'Shipped')
    GROUP BY customer_id
)
SELECT CASE WHEN order_count = 1 THEN 'One-time'
            WHEN order_count BETWEEN 2 AND 4 THEN 'Occasional (2-4)'
            ELSE 'Loyal (5+)' END AS customer_type,
       COUNT(*) AS customers,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_customers
FROM cust_orders
GROUP BY customer_type
ORDER BY customers DESC;
