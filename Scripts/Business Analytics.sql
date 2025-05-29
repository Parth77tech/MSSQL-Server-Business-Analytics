/*
===============================================================================
DATA ANALYTICS

===============================================================================
Business Quesitons:
 
1) Change-over-time
2) Cumulative analysis (Running total, Moving average)
3) Performance analysis 
4) Proportional analysis
5) Data segmentation 
6) Create comprehensive Customer report and create it as view for PowerBI Consumption
===============================================================================
*/

USE DataWarehouse;

SELECT * FROM gold.fact_sales;


-- ======================
-- 1) Change-Over-Time
-- ======================
-- a. Total Sales, Units & Customers over years
-- b. Total Sales, Units & Customers over Months in 2012
-- ---------------------------------------------------------------------

-- a. Total Sales, Units & Customers over years
SELECT 
YEAR(order_date) AS order_year,
SUM(sales_amount)/1000 AS total_sale_thousands,
COUNT(DISTINCT(customer_key)) AS total_customers,
SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date);
-- Sale drastically declined in 2013 w.r.t 2012


-- b. Total Sales, Units & Customers over Months in 2012
SELECT 
MONTH(order_date) AS order_month_2012,
SUM(sales_amount)/1000 AS total_sale_thousands,
COUNT(DISTINCT(customer_key)) AS total_customers,
SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL AND YEAR(order_date) = 2012
GROUP BY MONTH(order_date)
ORDER BY MONTH(order_date);



-- ======================
-- 2) Cumulative analysis
-- ======================
-- a. Calculate running total of sales over time- MONTH
-- b. Calculate moving average of Price over time-YEAR
-- ---------------------------------------------------------------------

SELECT *,
SUM(Total_sale) OVER (ORDER BY order_month) AS running_total
FROM (SELECT 
		DATETRUNC(month, order_date) AS order_month,
		SUM(sales_amount) AS Total_sale
		FROM gold.fact_sales
		GROUP BY DATETRUNC(month, order_date)) AS temp
WHERE order_month IS NOT NULL
ORDER BY order_month;



SELECT 
order_year, 
SUM(total_price) OVER (ORDER BY order_year) AS moving_avg
FROM (SELECT 
DATETRUNC(year,order_date) AS order_year,
SUM(price) AS total_price
FROM gold.fact_sales
GROUP BY DATETRUNC(year,order_date)) AS tempTab
WHERE order_year IS NOT NULL;



-- ======================
-- 3) Performance analysis
-- ======================
-- a. Compare year wise sale with 1-average annual sales and 2-previous year's sale
-- ---------------------------------------------------------------------


WITH CTE_per AS (
SELECT order_year,
total_sales,
AVG(total_sales) OVER () AS avg_sales,
LAG(total_sales) OVER (ORDER BY order_year) AS previous_year_sale
FROM (
	SELECT 
	DATETRUNC(year, order_date) AS order_year,
	SUM(sales_amount) AS total_sales
	FROM gold.fact_sales
	WHERE DATETRUNC(year, order_date) IS NOT NULL
	GROUP BY DATETRUNC(year, order_date)) AS TempTab)

SELECT
*,
total_sales - previous_year_sale AS diff_previous_year,
total_sales - avg_sales AS diff_avg
FROM CTE_per;



-- ======================
-- 4) Propotional analysis
-- ======================
-- a. Which Product category contribute the most to overall sales
-- ---------------------------------------------------------------------

SELECT TOP 5 * FROM gold.fact_sales;
SELECT TOP 5* FROM gold.dim_products;

WITH category_sales AS (
	SELECT
	p.category,
	SUM(s.sales_amount) AS total_sales
	FROM gold.fact_sales AS s
	LEFT JOIN gold.dim_products AS p
	ON p.product_key = s.product_key
	GROUP BY p.category)

SELECT 
category,
total_sales,
SUM(total_sales) OVER () AS grand_total_sale,
ROUND((CAST(total_sales AS FLOAT)/SUM(total_sales) OVER ())*100,2)   AS sales_contribution,
CONCAT(ROUND((CAST(total_sales AS FLOAT)/SUM(total_sales) OVER ())*100,2), ' %')    AS sales_contribution_percentage
FROM category_sales;



-- ======================
-- 5) Data Segmentation
-- ======================
-- a. Categories Products (Subcategories) based on the sales Very high, High, Medium and Low
-- b. Find out total number of Customers upto 18, 18-30, 31-45, 45+
-- ---------------------------------------------------------------------

SELECT TOP 5 * FROM gold.fact_sales;
SELECT TOP 5 * FROM gold.dim_products;
SELECT TOP 5 * FROM gold.dim_customers;

-- a. Categories Products (Subcategories) based on the sales Very high, High, Medium and Low
WITH subcategory_segments AS (
SELECT 
p.subcategory,
SUM(s.sales_amount)  AS total_sale
FROM gold.fact_sales AS s
LEFT JOIN gold.dim_products AS p
ON s.product_key = p.product_key
GROUP BY p.subcategory)

SELECT *,
CASE 
	WHEN total_sale> 4000001 THEN 'Very High'
	WHEN total_sale> 70001 THEN 'High'
	WHEN total_sale> 36001 THEN 'Medium'
	ELSE 'low'
	END AS sale_groups
FROM subcategory_segments
ORDER BY total_sale ;



-- b. Find out total number of Customers upto 18, 18-30, 31-45, 45+

WITH cte_age_groups AS (

SELECT *,
CASE 
	WHEN DATEDIFF(year, birthdate, GETDATE())>45 THEN '45+'
	WHEN DATEDIFF(year, birthdate, GETDATE())>30 THEN '31-45'
	WHEN DATEDIFF(year, birthdate, GETDATE())>17 THEN '18-30'
	ELSE '18'
	END AS age_groups
FROM gold.dim_customers)

SELECT 
age_groups,
COUNT(age_groups) AS total_customers
FROM cte_age_groups
GROUP BY age_groups
;




-- ======================
-- 6) Customer report
-- ======================
-- 1. Gather essential fields: names, ages, and trasactions etc.
-- 2. Aggregates customer-level metrics
--    - total orders
--    - total sales
--    - total quantity purchased
--    - total products
--    - lifespan (in months): duration between the first and last order
-- 3. Segments customers into (VIP, Regular, New) and Age groups AND Calculate following KPIs
--    - average order values
--    - average monthly spend
-- ---------------------------------------------------------------------

-- 1. Gather essential fields: names, ages, and trasactions

SELECT 
	s.order_number,
	s.product_key,
	s.order_date,
	s.sales_amount,
	s.quantity,
	c.customer_key,
	c.customer_number,
	CONCAT(c.first_name, c.last_name) AS customer_name,
	DATEDIFF(year, c.birthdate, GETDATE()) as age
FROM gold.fact_sales AS s
LEFT JOIN gold.dim_customers AS c
ON s.customer_key = c.customer_key
WHERE order_date IS NOT NULL;
-- use this as CTE



-- 2. Aggregates customer-level metrics
--    - total orders
--    - total sales
--    - total quantity purchased
--    - total products
--    - lifespan (in months)

WITH base_query AS (
SELECT 
	s.order_number,
	s.product_key,
	s.order_date,
	s.sales_amount,
	s.quantity,
	c.customer_key,
	c.customer_number,
	CONCAT(c.first_name, c.last_name) AS customer_name,
	DATEDIFF(year, c.birthdate, GETDATE()) as age
FROM gold.fact_sales AS s
LEFT JOIN gold.dim_customers AS c
ON s.customer_key = c.customer_key
WHERE order_date IS NOT NULL)

SELECT 
	customer_key,
	customer_number,
	customer_name,
	age,
	COUNT(DISTINCT(order_number))  AS total_orders,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	COUNT(DISTINCT(product_key)) AS total_products,
	DATEDIFF(month, MIN(order_date), MAX(order_date)) AS order_lifespan_months
FROM base_query
GROUP BY 
	customer_key,
	customer_number,
	customer_name,
	age)
	

-- 3. Segments customers into (VIP, Regular, New) and Age groups
-- AND Calculate following KPIs
--    - average order values
--    - average monthly spend

-- base query CTE
WITH base_query AS (
SELECT 
	s.order_number,
	s.product_key,
	s.order_date,
	s.sales_amount,
	s.quantity,
	c.customer_key,
	c.customer_number,
	CONCAT(c.first_name, c.last_name) AS customer_name,
	DATEDIFF(year, c.birthdate, GETDATE()) as age
FROM gold.fact_sales AS s
LEFT JOIN gold.dim_customers AS c
ON s.customer_key = c.customer_key
WHERE order_date IS NOT NULL) ,

-- Nested CTE for Aggregation
customer_aggregation AS (

SELECT 
	customer_key,
	customer_number,
	customer_name,
	age,
	COUNT(DISTINCT(order_number))  AS total_orders,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	COUNT(DISTINCT(product_key)) AS total_products,
	DATEDIFF(month, MIN(order_date), MAX(order_date)) AS order_lifespan_months
FROM base_query
GROUP BY 
	customer_key,
	customer_number,
	customer_name,
	age)
	

SELECT 
	customer_key,
	customer_number,
	customer_name,
	order_lifespan_months,
CASE 
	WHEN age < 20 THEN 'Under 20'
	WHEN age BETWEEN 20 AND 29 THEN '20-29'
	WHEN age BETWEEN 30 AND 39 THEN '30-39'
	WHEN age BETWEEN 40 AND 49 THEN '40-49'
	ELSE '50+'
END AS age_groups,
	total_orders,
	total_sales,
	total_products,
CASE 
	WHEN order_lifespan_months >= 12 AND total_sales > 5000 THEN 'VIP'
	WHEN order_lifespan_months >= 12 AND total_sales <= 5000 THEN 'Regular'
	ELSE 'New'
END AS customer_segment,

-- Average order value: total sales/total orders
CASE 
	WHEN total_sales = 0 THEN 0 
	ELSE total_sales/total_orders 
END AS avg_order_value,

-- Average monthly spend: total sales/life span in months
CASE 
	WHEN order_lifespan_months = 0 THEN total_sales
	ELSE ROUND(total_sales/CAST(order_lifespan_months AS FLOAT),2)
END AS avg_monthly_spend

FROM customer_aggregation;


	
-- ======================
-- CREATE A VIWE FOR POWERBI IMPORT
-- ======================

-- ---------------------------------------------------------------------



CREATE VIEW gold.reprot_customers AS
WITH base_query AS (
SELECT 
	s.order_number,
	s.product_key,
	s.order_date,
	s.sales_amount,
	s.quantity,
	c.customer_key,
	c.customer_number,
	CONCAT(c.first_name, c.last_name) AS customer_name,
	DATEDIFF(year, c.birthdate, GETDATE()) as age
FROM gold.fact_sales AS s
LEFT JOIN gold.dim_customers AS c
ON s.customer_key = c.customer_key
WHERE order_date IS NOT NULL) ,

-- Nested CTE for Aggregation
customer_aggregation AS (

SELECT 
	customer_key,
	customer_number,
	customer_name,
	age,
	COUNT(DISTINCT(order_number))  AS total_orders,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	COUNT(DISTINCT(product_key)) AS total_products,
	DATEDIFF(month, MIN(order_date), MAX(order_date)) AS order_lifespan_months
FROM base_query
GROUP BY 
	customer_key,
	customer_number,
	customer_name,
	age)
	

SELECT 
	customer_key,
	customer_number,
	customer_name,
	order_lifespan_months,
CASE 
	WHEN age < 20 THEN 'Under 20'
	WHEN age BETWEEN 20 AND 29 THEN '20-29'
	WHEN age BETWEEN 30 AND 39 THEN '30-39'
	WHEN age BETWEEN 40 AND 49 THEN '40-49'
	ELSE '50+'
END AS age_groups,
	total_orders,
	total_sales,
	total_products,
CASE 
	WHEN order_lifespan_months >= 12 AND total_sales > 5000 THEN 'VIP'
	WHEN order_lifespan_months >= 12 AND total_sales <= 5000 THEN 'Regular'
	ELSE 'New'
END AS customer_segment,

-- Average order value: total sales/total orders
CASE 
	WHEN total_sales = 0 THEN 0 
	ELSE total_sales/total_orders 
END AS avg_order_value,

-- Average monthly spend: total sales/life span in months
CASE 
	WHEN order_lifespan_months = 0 THEN total_sales
	ELSE ROUND(total_sales/CAST(order_lifespan_months AS FLOAT),2)
END AS avg_monthly_spend

FROM customer_aggregation;


-- Check view
SELECT * FROM gold.reprot_customers;