/* 8 Week SQL Challenge - Case Study #2 (Pizza Runner) - https://8weeksqlchallenge.com/case-study-2/
*/

--/* --------------------
--   Case Study Questions
--   --------------------*/

/* DATA CLEANING
Need to remove NULL values in customer_orders and runner_orders with temp table.
Removed inconsistent units.
*/

SELECT order_id, customer_id, pizza_id,
	(CASE
	WHEN exclusions IS NULL OR exclusions LIKE 'null' THEN ''
	ELSE exclusions
	END) AS exclusions,
	(CASE
	WHEN extras IS NULL OR extras LIKE 'null' THEN ''
	ELSE extras
	END) AS extras,
	order_time
INTO #customer_orders --TEMP TABLE
FROM pizza_runner..customer_orders;


SELECT order_id, runner_id,
	(CASE
		WHEN pickup_time IS NULL THEN ''
		ELSE pickup_time
		END) AS pickup_time,
	(CASE
		WHEN distance IS NULL THEN ''
		WHEN distance LIKE ('%km') THEN TRIM ('km' from distance)
		ELSE distance
		END) AS distance,
	(CASE
		WHEN duration IS NULL THEN ''
		WHEN duration LIKE ('%mins') THEN TRIM ('mins' from duration)
		WHEN duration LIKE ('%minute') THEN TRIM ('minute' from duration)
		WHEN duration LIKE ('%minutes') THEN TRIM ('minutes' from duration)
		ELSE duration
		END) AS duration,
	(CASE
		WHEN cancellation IS NULL or cancellation LIKE 'null' THEN ''
		ELSE cancellation
		END) AS cancellation
INTO #runner_orders --TEMP TABLE
FROM pizza_runner..runner_orders;

ALTER TABLE #runner_orders
ALTER COLUMN distance FLOAT;
ALTER TABLE #runner_orders
ALTER COLUMN duration INT;

--A. PIZZA METRICS

--1. How many pizzas were ordered?
SELECT COUNT(*) AS pizzas_ordered
FROM #customer_orders;

--2. How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) as unique_orders
FROM #customer_orders;

--3. How many successful orders were delivered by each runner?
SELECT runner_id, count(order_id) AS successful_orders
FROM #runner_orders
WHERE cancellation = ''
GROUP BY runner_id;

--4. How many of each type of pizza was delivered?
SELECT pizza_name, count(pizza_name) AS delivered_pizza_type
FROM pizza_runner..pizza_names pn
JOIN #customer_orders co
ON pn.pizza_id = co.pizza_id
JOIN #runner_orders ro
ON co.order_id = ro.order_id
WHERE cancellation = ''
GROUP BY pizza_name;

--5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT customer_id, pizza_name, count(pizza_name) as pizzas_ordered
FROM #customer_orders co
JOIN pizza_runner..pizza_names pn
ON co.pizza_id = pn.pizza_id
GROUP BY customer_id, pizza_name
ORDER BY customer_id, pizza_name;

--6. What was the maximum number of pizzas delivered in a single order?
SELECT TOP 1 co.customer_id, co.order_id, count(pizza_id) as pizzas_delivered
FROM #customer_orders co
JOIN #runner_orders ro
ON co.order_id = ro.order_id
WHERE cancellation = ''
GROUP BY co.customer_id, co.order_id
ORDER BY pizzas_delivered DESC;

--7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
WITH order_changes AS (
	SELECT co.customer_id, order_id, 	
		CASE
			WHEN exclusions != '' OR extras != '' THEN 1
			ELSE 0
			END AS at_least_1_change,
		CASE
			WHEN exclusions = '' OR extras = '' THEN 1
			ELSE 0
			END AS no_changes
	FROM #customer_orders co
	--GROUP BY co.customer_id, exclusions, extras
	)
SELECT customer_id, sum(at_least_1_change) AS at_least_1_change, sum(no_changes) AS no_changes
FROM order_changes oc
JOIN #runner_orders ro
ON oc.order_id = ro.order_id
WHERE cancellation = ''
GROUP BY customer_id;

--8. How many pizzas were delivered that had both exclusions and extras?
SELECT count(pizza_id) AS exclusions_and_extras
FROM #customer_orders co
JOIN #runner_orders ro
ON co.order_id = ro.order_id
WHERE cancellation = '' AND exclusions != '' AND extras != '';

--9. What was the total volume of pizzas ordered for each hour of the day?
SELECT DATEPART(hour,order_time) as hour_of_day, count(*) AS total_pizzas_ordered
FROM #customer_orders
GROUP BY DATEPART(hour,order_time)

--10. What was the volume of orders for each day of the week?
SELECT DATENAME(dw,order_time) as day_of_week, count(*) as total_pizzas_ordered
FROM #customer_orders
GROUP BY DATENAME(dw,order_time), DATEPART(dw,order_time)
ORDER BY DATEPART(dw,order_time)