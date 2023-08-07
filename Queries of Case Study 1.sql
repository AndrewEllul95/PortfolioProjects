USE [8 Week Challenge: Case Study #1]; -- Replace "YourDatabaseName" with the actual name of your database


-- Q1. What is the total amount each customer spent at the restaurant?

SELECT 
	 s.customer_id
	,SUM(price) AS total_amount
FROM 
	dbo.sales AS s
INNER JOIN 
	dbo.menu AS m ON s.product_id = m.product_id
GROUP BY
	s.customer_id;


-- Q2. How many days has each customer visited the restaurant?

SELECT 
	 customer_id
	,COUNT(DISTINCT order_date) AS customer_visits
FROM
	dbo.sales
GROUP BY 
	customer_id;


-- Q3. What was the first item from the menu purchased by each customer?
-- Option 1: Use a Subquery

SELECT
    sub.customer_id,
    sub.order_date,
    sub.product_name
FROM (
    SELECT 
         s.customer_id
        ,s.order_date
        ,m.product_name
        ,ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date ASC) AS first_order_item
    FROM
        dbo.sales AS s
    INNER JOIN
        dbo.menu AS m ON s.product_id = m.product_id
) AS sub
WHERE 
	sub.first_order_item = 1;


-- Option 2: Use a common Table Expression

WITH RankedOrders AS 
(
    SELECT 
         s.customer_id
        ,s.order_date
        ,m.product_name
        ,ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date ASC) AS first_order_item
    FROM
        dbo.sales AS s
    INNER JOIN
        dbo.menu AS m ON s.product_id = m.product_id
)
SELECT
     customer_id
    ,order_date
    ,product_name
FROM 
	RankedOrders
WHERE 
	first_order_item = 1;

-- Q4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- Option 1: Simple Count & Order By Query

SELECT TOP 1
	 m.product_name
    ,COUNT(product_name) AS orders
FROM 
    dbo.sales AS s
INNER JOIN
    dbo.menu AS m ON s.product_id = m.product_id
GROUP BY
    m.product_name
ORDER BY
	orders DESC;


-- Option 2: Subquery
SELECT TOP 1
     most_purchased.product_name
    ,SUM(most_purchased.order_number) AS total_purchases
FROM
    (
        SELECT
            m.product_name,
            s.customer_id,
            COUNT(product_name) AS order_number
        FROM 
            dbo.sales AS s
        INNER JOIN
            dbo.menu AS m ON s.product_id = m.product_id
        GROUP BY
            m.product_name,
            s.customer_id
    ) AS most_purchased
GROUP BY
    most_purchased.product_name
ORDER BY
    total_purchases DESC;


-- Q5. Which item was the most popular for each customer?

WITH popular_order AS
(
SELECT  
	 m.product_name
	,s.customer_id
    --,COUNT(product_name) AS orders
	,RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(order_date) DESC) AS most_popular_item
FROM 
    dbo.sales AS s
INNER JOIN
    dbo.menu AS m ON s.product_id = m.product_id
GROUP BY
     s.customer_id
	,m.product_name
)

SELECT
	 customer_id
	,product_name
FROM
	popular_order
WHERE
	most_popular_item = 1;

-- Q6. Which item was purchased first by the customer after they became a member?
WITH cte AS
(
SELECT 
	 s.customer_id
	,m1.join_date
	,s.order_date
	,m2.product_name
	,RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date ASC) AS rnk
FROM
	members AS m1
INNER JOIN
	sales AS s ON m1.customer_id = s.customer_id
INNER JOIN
	menu AS m2 ON m2.product_id = s.product_id
WHERE
	s.order_date >= m1.join_date
)

SELECT 
	 customer_id
	,product_name
FROM
	cte
WHERE
	rnk = 1;


-- Q7. Which item was purchased just before the customer became a member?

WITH cte AS
(
SELECT 
	 s.customer_id
	 ,s.order_date
	,m1.join_date
	,m2.product_name
	,RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date DESC) AS rnk
FROM
	members AS m1
INNER JOIN
	sales AS s ON m1.customer_id = s.customer_id
INNER JOIN
	menu AS m2 ON m2.product_id = s.product_id
WHERE
	s.order_date < m1.join_date
)

SELECT 
	 customer_id
	,product_name
FROM
	cte
WHERE
	rnk = 1;


-- Q8. What is the total items and amount spent for each member before they became a member?

SELECT 
	 s.customer_id
	,COUNT(m2.product_name) AS total_items
	,SUM(m2.price) AS amount_spent
FROM
	members AS m1
INNER JOIN
	sales AS s ON m1.customer_id = s.customer_id
INNER JOIN
	menu AS m2 ON m2.product_id = s.product_id
WHERE
	s.order_date < m1.join_date
GROUP BY
	 s.customer_id;

-- Q9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?


WITH cte AS
(
SELECT 
	 s.customer_id
	,product_name
	,SUM(m.price) AS amount_spent
	,CASE WHEN product_name = 'sushi' THEN SUM(m.price * 10 * 2)
	 ELSE SUM(m.price * 10)
	 END AS points
FROM
	sales AS s
INNER JOIN
	menu AS m ON m.product_id = s.product_id
GROUP BY
	s.customer_id
	,product_name
)

SELECT 
	 customer_id
	,SUM(points) AS total_points
FROM 
	cte
GROUP BY
	 customer_id;


-- Q10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
-- how many points do customer A and B have at the end of January?

SELECT 
  S.customer_id, 
  SUM(
    CASE 
      WHEN S.order_date BETWEEN MEM.join_date AND DATEADD(day, 6, MEM.join_date) THEN price * 10 * 2 
      WHEN product_name = 'sushi' THEN price * 10 * 2 
      ELSE price * 10 
    END
  ) as points 
FROM 
  MENU as M 
  INNER JOIN SALES as S ON S.product_id = M.product_id
  INNER JOIN MEMBERS AS MEM ON MEM.customer_id = S.customer_id 
WHERE 
  S.order_date BETWEEN '2021-01-01' AND '2021-01-31'
GROUP BY 
  S.customer_id;
