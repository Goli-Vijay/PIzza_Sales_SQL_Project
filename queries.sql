create database pizzahut;

use pizzahut;

select * from pizzas;


CREATE TABLE orders (
    order_id INT NOT NULL,
    order_date DATE NOT NULL,
    order_time TIME NOT NULL,
    PRIMARY KEY (order_id)
);

CREATE TABLE order_detail (
    order_details_id INT NOT NULL,
    order_id INT NOT NULL,
    pizza_id TEXT NOT NULL,
    quantity INT NOT NULL,
    PRIMARY KEY (order_details_id)
);

-- Retrieve the total number of orders placed.

SELECT 
    COUNT(*) AS total_orders
FROM
    orders;


-- Calculate the total revenue generated from pizza sales.

SELECT 
    ROUND(SUM(od.quantity * p.price), 2) AS total_revenue
FROM
    order_detail od
        JOIN
    pizzas p ON od.pizza_id = p.pizza_id;


-- Identify the highest-priced pizza.

SELECT 
    pt.name, p.price
FROM
    pizzas p
        JOIN
    pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
ORDER BY p.price DESC
LIMIT 1;

-- Identify the most common pizza size ordered.

SELECT 
    p.size, COUNT(order_details_id) AS no_of_orders
FROM
    pizzas p
        JOIN
    order_detail od ON p.pizza_id = od.pizza_id
GROUP BY p.size
ORDER BY no_of_orders DESC
LIMIT 1;


-- List the top 5 most ordered pizza types along with their quantities.

SELECT 
    pt.name, pt.pizza_type_id, SUM(od.quantity) AS quantity
FROM
    order_detail od
        JOIN
    pizzas p ON od.pizza_id = p.pizza_id
        JOIN
    pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY pt.name , pt.pizza_type_id
ORDER BY quantity DESC
LIMIT 5;


-- Join the necessary tables to find the total quantity of each pizza category ordered.

SELECT 
    pt.category, SUM(od.quantity) AS total_quantity
FROM
    order_detail od
        JOIN
    pizzas p ON od.pizza_id = p.pizza_id
        JOIN
    pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY category;

-- Determine the distribution of orders by hour of the day.

SELECT 
    HOUR(order_time) AS hour_of_day,
    COUNT(order_id) AS no_of_orders
FROM
    orders
GROUP BY HOUR(order_time);

-- Join relevant tables to find the category-wise distribution of pizzas.

SELECT 
    category, COUNT(category)
FROM
    pizza_types
GROUP BY category;

-- Group the orders by date and calculate the average number of pizzas ordered per day.

SELECT 
    ROUND(AVG(no_of_orders), 0) AS avg_pizzas_per_day
FROM
    (SELECT 
        o.order_date, SUM(od.quantity) AS no_of_orders
    FROM
        orders o
    JOIN order_detail od ON o.order_id = od.order_id
    GROUP BY o.order_date) AS quantity_count;

-- Determine the top 3 most ordered pizza types based on revenue.

SELECT 
    pt.name, SUM(od.quantity * p.price) AS revenue
FROM
    pizza_types pt
        JOIN
    pizzas p ON pt.pizza_type_id = p.pizza_type_id
        JOIN
    order_detail od ON p.pizza_id = od.pizza_id
GROUP BY pt.name
ORDER BY revenue DESC
LIMIT 3;

-- Calculate the percentage contribution of each pizza type to total revenue.

WITH category_revenue AS (
    SELECT 
        pt.category,
        SUM(p.price * od.quantity) AS revenue
    FROM 
        pizza_types pt
    JOIN 
        pizzas p ON pt.pizza_type_id = p.pizza_type_id
    JOIN 
        order_detail od ON od.pizza_id = p.pizza_id
    GROUP BY 
        pt.category
),
total_revenue AS (
    SELECT SUM(revenue) AS total_revenue FROM category_revenue
)
SELECT
    cr.category,
    ROUND(cr.revenue * 100 / tr.total_revenue, 2) AS percentage_contribution
FROM 
    category_revenue cr, total_revenue tr
ORDER BY 
    percentage_contribution DESC;


-- Analyze the cumulative revenue generated over time.

select 
order_date,sum(revenue) over(order by order_date) as cum_revenue
from(
	select 
    o.order_date,sum(p.price * od.quantity) as revenue
	from 
		order_detail od
        join pizzas p on od.pizza_id = p.pizza_id
		join orders o on o.order_id = od.order_id 
    group by o.order_date) as sales;


-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.

SELECT category, name, revenue
FROM (
    SELECT category,name,revenue,
        RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS ran
    FROM (
        SELECT pt.category, pt.name, 
            SUM(od.quantity * p.price) AS revenue
        FROM 
            pizza_types pt
        JOIN 
            pizzas p ON pt.pizza_type_id = p.pizza_type_id
        JOIN 
            order_detail od ON od.pizza_id = p.pizza_id
        GROUP BY 
            pt.category, pt.name
    ) AS a
) AS b
WHERE ran <= 3;
