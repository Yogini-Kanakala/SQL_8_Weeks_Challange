------ Runner and Customer Experience

--How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT
  FLOOR((registration_date - DATE '2021-01-01') / 7) + 1 AS week_number,
  COUNT(*) AS runners_signed_up
FROM runners
GROUP BY week_number
ORDER BY week_number;


--What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT avg (EXTRACT(EPOCH FROM ( pickup_time::timestamp-order_time::timestamp))/60),  ro.runner_id
FROM customer_orders co inner join runner_orders ro 
on co.order_id=ro.order_id and ro.cancellation is null 
group by 2


--Is there any relationship between the number of pizzas and how long the order takes to prepare?

SELECT count( DISTINCT  co.pizza_id), co.order_id, avg(extract(epoch from ( ro.pickup_time::timestamp-co.order_time::timestamp))/60)
FROM customer_orders co inner join runner_orders ro 
on co.order_id=ro.order_id and ro.cancellation is null 
group by co.order_id


--What was the average distance travelled for each customer?

SELECT co.customer_id, avg(distance),count(distinct co.order_id)
FROM customer_orders co inner join runner_orders ro 
on co.order_id=ro.order_id and ro.cancellation is null 
group by co.customer_id

--What was the difference between the longest and shortest delivery times for all orders?


select min(duration), max(duration), max(duration)-min(duration) as diff  from runner_orders


--What is the successful delivery percentage for each runner?


select runner_id, sum( case when pickup_time is not null and cancellation is null then 1 else 0 end), count(distinct order_id) ,(sum( case when pickup_time is not null and cancellation is null then 1 else 0 end)*100/ count(distinct order_id))
from runner_orders
group by runner_id



