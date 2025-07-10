
--Before you start writing your SQL queries however - you might want to investigate the data, you may want to do something with some of those null values and data types in the customer_orders and runner_orders tables!

UPDATE customer_orders SET exclusions = NULL WHERE exclusions IN ('null', '');
UPDATE customer_orders SET extras = NULL WHERE extras IN ('null', '');
UPDATE runner_orders SET cancellation = NULL WHERE cancellation IN ('null', '');


UPDATE runner_orders
SET duration = CAST(TRIM(REGEXP_REPLACE(duration, '[[:alpha:]]', '', 'g')) AS INTEGER)
WHERE duration IS NOT NULL 
  AND TRIM(REGEXP_REPLACE(duration, '[[:alpha:]]', '', 'g')) <> '';

UPDATE runner_orders
SET distance = CAST(TRIM(REGEXP_REPLACE(distance, '[[:alpha:]]', '', 'g')) AS DOUBLE PRECISION)
WHERE distance IS NOT NULL 
  AND TRIM(REGEXP_REPLACE(distance, '[[:alpha:]]', '', 'g')) <> '';


--- You need to replace those literal 'null' strings with proper SQL NULL values before you cast the column.

UPDATE runner_orders
SET distance = NULL
WHERE LOWER(distance) = 'null';

 UPDATE runner_orders
SET duration = NULL
WHERE LOWER(duration) = 'null';



--f you want to make these changes permanent and prevent mixed data types, consider changing the columns’ types afterward:

ALTER TABLE runner_orders
ALTER COLUMN duration TYPE INTEGER USING duration::INTEGER;

ALTER TABLE runner_orders
ALTER COLUMN distance TYPE DOUBLE PRECISION USING distance::DOUBLE PRECISION;


--How many pizzas were ordered?
SELECT count(*) FROM public.customer_orders
--How many unique customer orders were made?
select count(distinct customer_id) from customer_orders;

--How many successful orders were delivered by each runner?
select count(*) from runner_orders where cancellation is null;


--How many of each type of pizza was delivered?
SELECT pn.pizza_name, COUNT(co.pizza_id) AS delivered_count
FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
WHERE ro.cancellation IS NULL
GROUP BY pn.pizza_name;


--How many Vegetarian and Meatlovers were ordered by each customer?

select co.customer_id,  pn.pizza_name, count(co.pizza_id)
from customer_orders co left join  pizza_names pn
on co.pizza_id= pn.pizza_id
group by  co.customer_id, pn.pizza_name
order by co.customer_id;


SELECT
  customer_id,
  COUNT(CASE WHEN pn.pizza_name = 'Meatlovers' THEN 1 END) AS meatlovers_count,
  COUNT(CASE WHEN pn.pizza_name = 'Vegetarian' THEN 1 END) AS vegetarian_count
FROM customer_orders co
JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
GROUP BY customer_id
ORDER BY customer_id;

--What was the maximum number of pizzas delivered in a single order?

SELECT co.order_id, COUNT(co.pizza_id) AS pizza_count
FROM customer_orders co
INNER JOIN runner_orders ro ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY co.order_id
ORDER BY COUNT(co.pizza_id) DESC
LIMIT 1;


--🧠 Optional: If you just want the number (not the order_id)

SELECT MAX(pizza_count) AS max_pizzas_in_order
FROM (
  SELECT COUNT(*) AS pizza_count
  FROM customer_orders co
  JOIN runner_orders ro ON co.order_id = ro.order_id
  WHERE ro.cancellation IS NULL
  GROUP BY co.order_id
) sub;


--For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

SELECT co.customer_id, 
COUNT(case when co.exclusions is not null or co.extras is not null then 1 end) AS pizza_changes_count,
COUNT(case when co.exclusions is  null and co.extras is  null then 1 end) AS pizza_nochanges_count
FROM customer_orders co
INNER JOIN runner_orders ro ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY co.customer_id


SELECT 
  co.customer_id, 
  COUNT(*) FILTER (WHERE co.exclusions IS NOT NULL OR co.extras IS NOT NULL) AS pizza_changes_count,
  COUNT(*) FILTER (WHERE co.exclusions IS NULL AND co.extras IS NULL) AS pizza_nochanges_count
FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY co.customer_id;




--How many pizzas were delivered that had both exclusions and extras?

SELECT  COUNT(case when co.exclusions is not null and co.extras is not null then 1 end) AS pizza_changes_count
FROM customer_orders co
INNER JOIN runner_orders ro ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL



SELECT  COUNT(*)filter(where co.exclusions is not null and co.extras is not null) AS pizza_changes_count
FROM customer_orders co
INNER JOIN runner_orders ro ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL


--What was the total volume of pizzas ordered for each hour of the day?

select count(pizza_id), date_part('hour',order_time) as hour_of_the_day 
from customer_orders 
group by  hour_of_the_day
order by hour_of_the_day;

--What was the volume of orders for each day of the week?

select  count( distinct order_id), date_part('dow',order_time) as day_of_the_week
from customer_orders 
group by  day_of_the_week
order by day_of_the_week
