-- OLAP (Online Analytical Processing) query questions 

-- Generate this huge table in case needed
SELECT s.supplier_id,
       s.company_name supplier_name,
	   c.category_id,
	   c.category_name,
	   p.product_id,
	   p.product_name,
	   p.unit_price product_unit_price,
	   p.units_in_stock product_unit_stock,
	   p.units_on_order,
	   od.order_id,
	   o.order_date,
	   od.unit_price order_price,
	   od.quantity order_quantity,
	   od.unit_price*od.quantity order_sales,
	   od.discount order_discount,
	   c1.customer_id,
	   c1.country customer_country,
	   s1.shipper_id,
	   s1.company_name shipper_name,
	   o.shipped_date,
	   o.freight,
	   o.employee_id ,
	   e.last_name employee_last_name,
	   e.first_name employee_first_name
FROM suppliers s
INNER JOIN products p
ON p.supplier_id = s.supplier_id
INNER JOIN categories c 
ON c.category_id = p.category_id
INNER JOIN order_details od 
ON od.product_id = p.product_id
INNER JOIN orders o 
ON o.order_id = od.order_id
INNER JOIN customers c1
ON c1.customer_id = o.customer_id
INNER JOIN employees e
ON e.employee_id = o.employee_id
INNER JOIN shippers s1 
ON s1.shipper_id = o.ship_via

SELECT EXTRACT(YEAR FROM order_date), COUNT(*) FROM orders
GROUP BY 1

-- (1) List all customers:
SELECT * FROM customers

-- (2) Find all products' names with their corresponding category names:
SELECT products.product_name, categories.category_name
FROM products
INNER JOIN categories ON products.category_id = categories.category_id

-- (3) Retrieve the total number of orders:
SELECT COUNT(*) total_orders
FROM orders

-- (4) List all employees with their full name and job title:
SELECT CONCAT(first_name,' ',last_Name) full_name, title
FROM employees

OR

SELECT first_name || ' ' || last_name AS full_name, title 
FROM employees

-- (5) Find all orders shipped to the USA:
SELECT * FROM orders
WHERE ship_country = 'USA'

-- (6) Find the names of all suppliers:
SELECT company_name FROM suppliers

-- (7) List the names and contact titles of all customers:
SELECT company_name, contact_title 
FROM customers;

-- (8) Retrieve the distinct product categories:
SELECT DISTINCT category_name
FROM categories

-- (9) Get the first 10 products ordered by their names:
SELECT product_name
FROM products
ORDER BY 1
LIMIT 10

-- (10) Find all employees who are sales representatives:
SELECT first_name, last_name FROM employees
WHERE title = 'Sales Representative'

-- (11) Find the top 5 customers by the number of orders placed:
SELECT customer_id, COUNT(*) FROM orders
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5

-- (12) Calculate the total sales for each product:

-- clarify the question:
-- if sales mean the total quantity, then
SELECT p.product_id, 
       p.product_name,
       SUM(CASE WHEN o.quantity IS NOT NULL THEN o.quantity ELSE 0 END) sales
FROM products p
LEFT JOIN order_details o
ON p.product_id = o.product_id
GROUP BY 1, 2
ORDER BY 3 DESC

-- if sales mean total income, then
SELECT p.product_id, 
       p.product_name,
       ROUND(SUM(CASE WHEN o.quantity IS NOT NULL THEN o.quantity*o.unit_price ELSE 0 END)::numeric,2) sales
FROM products p
LEFT JOIN order_details o
ON p.product_id = o.product_id
GROUP BY 1, 2
ORDER BY 3 DESC

-- (13) List all suppliers and the number of products they supply:
SELECT s.company_name, COUNT(p.product_id) FROM suppliers s
INNER JOIN products p
ON s.supplier_id = p.supplier_id
GROUP BY s.supplier_id
ORDER BY 2 DESC

-- (14) Retrieve all orders along with the names of the employees who handled them:
SELECT o.order_id, CONCAT(e.first_name, ' ',e.last_name) name
FROM orders o INNER JOIN employees e ON o.employee_id = e.employee_id

-- (15) Find the average unit price of products in each category:
SELECT c.category_id, c.category_name, AVG(p.unit_price)
FROM categories c 
INNER JOIN products p ON c.category_id = p.category_id
GROUP BY 1
ORDER BY 2

-- (16) Identify the employees who have not handled any orders:
SELECT employee_id
FROM employees 
WHERE employee_id NOT IN (SELECT employee_id FROM orders)


-- (17) Find the total number of units ordered for each product:
SELECT p.product_id, p.product_name, SUM(o.quantity) units
FROM products p INNER JOIN order_details o
ON p.product_id = o.product_id
GROUP BY 1, 2
ORDER BY 3 DESC

-- (18) List the total number of orders for each customer in 2023:
SELECT c.customer_id, COUNT(o.order_id)
FROM customers c 
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE EXTRACT(YEAR FROM o.order_date) = 1998
GROUP BY 1
ORDER BY 2 DESC

-- (19) Find the total number of employees in each city:
SELECT city, COUNT(employee_id) employee_count
FROM employees
GROUP BY 1
ORDER BY 2 DESC

-- (20) Calculate the total freight charges for all orders:
SELECT SUM(freight) total_freight
FROM orders


-- (21) Calculate the monthly sales for the current year:
-- Assume sales is the total GMV.
SELECT EXTRACT(MONTH FROM orders.order_date), 
       SUM(order_details.unit_price*order_details.quantity) 
FROM orders
LEFT JOIN order_details
ON orders.order_id = order_details.order_id
WHERE EXTRACT(YEAR FROM order_date) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY 1

-- (22) Determine the customer with the highest total order value:
SELECT c.customer_id, c.company_name, SUM(od.unit_price * od.quantity) AS total_order_value 
FROM customers c 
JOIN orders o ON c.customer_id = o.customer_id 
JOIN order_details od ON o.order_id = od.order_id 
GROUP BY c.customer_id, c.company_name 
ORDER BY total_order_value DESC 
LIMIT 1;

-- (23) Identify the top 3 employees with the highest sales:
SELECT e.employee_id, e.first_name || ' ' || e.last_name AS employee_name, 
       SUM(od.unit_price * od.quantity) AS total_sales 
FROM employees e 
JOIN orders o ON e.employee_id = o.employee_id 
JOIN order_details od ON o.order_id = od.order_id 
GROUP BY e.employee_id, e.first_name, e.last_name 
ORDER BY total_sales DESC 
LIMIT 3

-- (24) Calculate the reorder rate of each product (units ordered / units in stock):
SELECT product_name, 
       (units_on_order::decimal / units_in_stock) AS reorder_rate 
FROM products 
WHERE units_in_stock > 0

-- (25) Find the average number of days between order date and shipped date for all orders:
SELECT AVG(shipped_date-order_date) avg_days_to_ship
FROM orders
WHERE shipped_date IS NOT NULL


-- (26) Calculate ratio of customers who made multiple orders:
SELECT COUNT(*)::numeric/(SELECT COUNT(*) FROM customers)
FROM
(
SELECT customers.customer_id FROM customers
LEFT JOIN orders ON customers.customer_id = orders.customer_id
GROUP BY 1
HAVING COUNT(orders.order_id) > 1
) a 

-- (27) Compute the percentage of orders shipped within 7 days):
SELECT ROUND(COUNT(*)::numeric/(SELECT COUNT(*) FROM orders),2) perc
FROM orders
WHERE shipped_date::date - order_date::date <= 7


-- (28) Using window functions, rank customers by their total order value:
SELECT c.customer_id, 
       SUM(o2.unit_price*o2.quantity), 
	   DENSE_RANK() OVER(ORDER BY SUM(o2.unit_price*o2.quantity) DESC)
FROM customers c
LEFT JOIN orders o1 ON o1.customer_id = c.customer_id
INNER JOIN order_details o2 ON o1.order_id = o2.order_id
GROUP BY 1


-- (29) Calculate the running total of sales per month in year 1998:
SELECT a.Months, 
       ROUND(SUM(a.sales) OVER(ORDER BY a.Months)::numeric,2) cum_sum
FROM
(
SELECT EXTRACT(MONTH FROM o.order_date) Months, 
       SUM(od.unit_price*od.quantity) sales
FROM orders o
INNER JOIN order_details od
ON o.order_id = od.order_id
WHERE (SELECT EXTRACT(YEAR FROM o.order_date)=1997)
GROUP BY 1
) a

