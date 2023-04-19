Schema SQL Query SQL ResultsEdit on DB Fiddle
/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id, sum(m.price) AS total_paid
FROM dannys_diner..sales s
JOIN dannys_diner..menu m
ON s.product_id = m.product_id
GROUP BY customer_id
ORDER BY customer_id

-- 2. How many days has each customer visited the restaurant?
SELECT s.customer_id, count(distinct s.order_date) AS days_visited
FROM dannys_diner..sales s
GROUP BY s.customer_id

-- 3. What was the first item from the menu purchased by each customer?

WITH orders AS (
	SELECT customer_id, product_id, order_date, dense_rank() OVER (PARTITION BY customer_id ORDER BY order_date) AS rank
	FROM dannys_diner..sales s
)
SELECT o.customer_id, o.order_date, m.product_name
	FROM orders o
	JOIN dannys_diner..menu m
	ON o.product_id = m.product_id
WHERE o.rank = 1
GROUP BY o.customer_id, o.order_date, m.product_name

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT TOP 1 m.product_name, count(s.product_id) as purchase_count
	FROM dannys_diner..sales s
	JOIN dannys_diner..menu m
	ON s.product_id = m.product_id
	GROUP BY m.product_name
	ORDER BY purchase_count DESC

-- 5. Which item was the most popular for each customer?
WITH orders AS (
SELECT customer_id, product_id, count(*) AS num_of_orders, dense_rank() OVER (PARTITION BY customer_id ORDER BY count(product_id) DESC) AS rank
FROM dannys_diner..sales s
GROUP BY customer_id, product_id
)
SELECT o.customer_id, m.product_name, o.num_of_orders
FROM orders o
JOIN dannys_diner..menu m
ON o.product_id = m.product_id
WHERE o.rank = 1
GROUP BY o.customer_id, m.product_name, o.num_of_orders

-- 6. Which item was purchased first by the customer after they became a member?
WITH orders AS (
SELECT s.customer_id, s.product_id, m.product_name, s.order_date, mem.join_date
, dense_rank() OVER (PARTITION BY s.customer_id ORDER BY (s.order_date) DESC) AS rank
FROM dannys_diner..sales s
	JOIN dannys_diner..members mem
	ON s.customer_id = mem.customer_id
	JOIN dannys_diner..menu m
	ON s.product_id = m.product_id
WHERE s.order_date >= mem.join_date
)
SELECT customer_id, join_date, order_date, product_name
FROM orders
WHERE rank = 1 


-- 7. Which item was purchased just before the customer became a member?
WITH orders AS (
SELECT s.customer_id, s.product_id, m.product_name, s.order_date, mem.join_date
, dense_rank() OVER (PARTITION BY s.customer_id ORDER BY (s.order_date) DESC) AS rank
FROM dannys_diner..sales s
	JOIN dannys_diner..members mem
	ON s.customer_id = mem.customer_id
	JOIN dannys_diner..menu m
	ON s.product_id = m.product_id
WHERE s.order_date < mem.join_date
)
SELECT customer_id, join_date, order_date, product_name
FROM orders
WHERE rank = 1

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, count(s.product_id) AS total_items, sum(price) total_paid_before_member
FROM dannys_diner..sales s
	JOIN dannys_diner..members mem
	ON s.customer_id = mem.customer_id
	JOIN dannys_diner..menu m
	ON s.product_id = m.product_id
WHERE s.order_date < mem.join_date
GROUP BY s.customer_id

---- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- Note: Only customers who are members receive points when purchasing items
WITH sushi AS ( 
	SELECT s.customer_id,
	CASE
	WHEN s.customer_id IN (SELECT customer_id FROM dannys_diner..members) AND product_name = 'sushi' THEN price*2
	WHEN s.customer_id IN (SELECT customer_id FROM dannys_diner..members) AND product_name != 'sushi' THEN price*1
	ELSE price*0
	END AS sushi_points
FROM dannys_diner..sales s
JOIN dannys_diner..menu m
ON s.product_id = m.product_id)

SELECT customer_id, sum(sushi_points*10) AS total_points
FROM sushi
GROUP BY customer_id

