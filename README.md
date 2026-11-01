# Retail Sales Analysis using SQL

An end-to-end SQL project that answers 15 real business questions on an online retail database: revenue trends, best-selling products, city performance, customer behaviour and order cancellations.

> **Note:** The dataset is synthetic (generated sample data for learning), not real company data.

## Tools
MySQL 8 / MariaDB 10.5+ | SQL (Joins, Aggregations, Subqueries, CTEs, Window Functions)

## Database design
4 related tables:

| Table | Rows | Description |
|---|---|---|
| `customers` | 60 | Name, email, city, state, signup date |
| `products` | 28 | Product name, category, unit price (INR) |
| `orders` | 450 | Customer, order date, status, payment method |
| `order_items` | 839 | Products in each order, quantity, discount % |

`customers 1—* orders 1—* order_items *—1 products`

Revenue = `quantity * unit_price * (1 - discount_pct/100)`, counting only **Delivered** and **Shipped** orders.

## SQL concepts used
- `INNER JOIN` / `LEFT JOIN` (up to 4 tables)
- `GROUP BY`, `HAVING`, `CASE WHEN`
- Subqueries and CTEs (`WITH`)
- Window functions: `RANK()`, `LAG()`, `SUM() OVER()`
- Constraints: Primary Key, Foreign Key, UNIQUE, CHECK

## Business questions answered
| # | Question |
|---|---|
| 1 | Business snapshot: customers, orders, total revenue |
| 2 | Order split by status |
| 3 | Preferred payment methods |
| 4 | Revenue by category |
| 5 | Top 5 products |
| 6 | Revenue and average order value by city |
| 7 | Monthly revenue trend |
| 8 | Customers who never ordered (LEFT JOIN) |
| 9 | Cancellation rate by payment method |
| 10 | Cities with 20+ orders (HAVING) |
| 11 | Customers spending above average (subquery) |
| 12 | Top 3 products per category (CTE + RANK) |
| 13 | Month-over-month growth % (LAG) |
| 14 | Cumulative revenue (running total) |
| 15 | Repeat vs one-time customers (CTE + CASE) |

## Key insights
- Total revenue is about **₹18.8 lakh** from 450 orders; **83%** of orders were delivered and **7%** cancelled.
- **Electronics** is the top category (₹6.3 lakh), followed by Home & Kitchen (₹5.0 lakh).
- **Air Fryer** is the best-selling product by revenue (₹2.48 lakh), then Smart Watch (₹2.10 lakh).
- **Ahmedabad** earns the most revenue (₹4.26 lakh), while Navi Mumbai and Ahmedabad have the highest average order values.
- **NetBanking** orders have the highest cancellation rate (9.8%); **COD** has the lowest (3.8%).
- **10 customers** signed up but never placed an order, a clear target for a re-engagement campaign.

## How to run
1. Open MySQL Workbench (or the MySQL command line).
2. Run `01_schema_and_data.sql` to create `retail_db` and load the data.
3. Run `02_analysis_queries.sql` and check each result.
4. `03_sample_output.txt` shows the expected output of every query.

## Author
Rakesh Yadav | [LinkedIn](https://www.linkedin.com/in/rakesh-yadav-34b656284)
