--1. What are the standard ingredients for each pizza?

with data as (
select 
trim (unnest(string_to_array(toppings,',')))::int as ing,
--regexp_split_to_table (toppings,'\s*,\s*')::int, can also be used instead of the top line 
pizza_id
from pizza_recipes
) 
select 
data.pizza_id,
string_agg(pt.topping_name,',') as standard_ingredients
from data inner join pizza_toppings as pt on data.ing=pt.topping_id
group by data.pizza_id
order by data.pizza_id;


--What was the most commonly added extra?

with extras_data as (
select 
trim(unnest(string_to_array(extras,',')))::int as extras
from customer_orders
) 
select pt.topping_name,
count(pt.topping_name) as freq 
from extras_data inner join pizza_toppings as pt 
on pt. topping_id= extras_data.extras
group by pt.topping_name
order by freq desc limit 1;



--What was the most common exclusion?

with data as(
select 
trim(unnest(string_to_array(exclusions,',')))::int as freq
from customer_orders
) 
select pt.topping_name, count(*)as count
from data inner join  pizza_toppings as pt on data.freq=  pt.topping_id
group by pt.topping_name
order by 2 desc limit 1




-- Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

with data as (
SELECT  co.*, 
CASE 
  WHEN pizza_name ~* 'lovers$' THEN INITCAP(regexp_replace(pizza_name, 'lovers$', ' lovers'))
  ELSE INITCAP(pizza_name)
END AS formatted_name,
e.extras_name, ex.exclusions_name
FROM public.customer_orders co 
left join pizza_names  pn 
on co.pizza_id=pn.pizza_id
left join lateral(
select trim(extras)::int as extras, pt.topping_name as extras_name from unnest(string_to_array(co.extras,',')) as extras
	left join 
	pizza_toppings as pt on pt.topping_id= trim(extras)::int
) as e on true
left join lateral(
select  trim(exclusions)::int as exclusions ,pt.topping_name as exclusions_name from regexp_split_to_table (co.exclusions,'\s*,\s*') as exclusions
left join 
pizza_toppings as pt on  pt.topping_id=trim(exclusions)::int
) as ex on true
order by order_id
)

select order_id, customer_id, pizza_id, exclusions, extras, order_time ,
concat(
formatted_name,
	case when max(exclusions_name) is not null then concat( (' - Exclude '), string_agg(exclusions_name,', '))  else '' end,
	case when max(extras_name) is not null then concat( (' - Extra '), string_agg(extras_name,', '))  else '' end
)
from data 
group by order_id, customer_id, pizza_id, exclusions, extras, order_time, formatted_name



-- If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes -
-- how much money has Pizza Runner made so far if there are no delivery fees?

select sum( case when co.pizza_id = 1 then 12 else 10 end)
from customer_orders co
inner join runner_orders ro 
on co. order_id= ro.order_id and ro.cancellation is null 


-- What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra

SELECT SUM(
          CASE 
            WHEN co.pizza_id = 1 THEN 12  -- Meat Lovers pizza price
            WHEN co.pizza_id = 2 THEN 10  -- Vegetarian pizza price
          END
       ) +sum ( case  when co.extras like '%4%' then 1 end) AS total_revenue
FROM customer_orders co
LEFT JOIN runner_orders ro
  ON co.order_id = ro.order_id
  AND ro.cancellation IS NULL;


The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
how would you design an additional table for this new dataset - 
generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.



drop table if exists runner_ratings;
create table runner_ratings (
	"rating_id"  serial primary key,
	"runner_id" integer,
	"order_id" integer ,
	"customer_id" integer ,
	"order_rating" integer check(order_rating between 1 and 5),
	"rating_date" timestamp
);

	
INSERT INTO runner_ratings ("runner_id", "order_id", "customer_id", "order_rating", "rating_date")
VALUES
  (1, 1, 101, 5, '2020-01-01 18:20:00'),
  (1, 2, 101, 4, '2020-01-04 13:30:00'),
  (2, 4, 103, 3, '2020-01-08 21:15:00'),
  (3, 5, 104, 4, '2020-01-11 18:40:00');


-- Using your newly generated table - can you join all of the information together to form a table 
-- which has the following information for successful deliveries?
-- customer_id     order_id  runner_id   rating   order_time
-- pickup_time    Time between order and pickup    Delivery duration   Average speed  Total number of pizzas

select co.customer_id, co.order_id, ro.runner_id,  rr.order_rating as rating, co.order_time,
ro.pickup_time , extract( epoch from  ( ro.pickup_time :: timestamp - co.order_time::timestamp) )/60, ro.duration , ro.distance/ro.duration ,
count(co.pizza_id) over(partition by co.order_id, co.customer_id)
from customer_orders co left join runner_orders ro 
on co.order_id= ro.order_id and ro.cancellation is null or ro.cancellation = ' '
left join runner_ratings rr on ro.runner_id=rr.runner_id 



-- If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and 
-- each runner is paid $0.30 per kilometre traveled - 
-- how much money does Pizza Runner have left over after these deliveries?


select SUM(
          CASE 
            WHEN co.pizza_id = 1 THEN 12  -- Meat Lovers pizza price
            WHEN co.pizza_id = 2 THEN 10  -- Vegetarian pizza price
          END
		  )- 
		  count(co.pizza_id) *0.30
from customer_orders co inner join runner_orders ro 
on co.order_id= ro.order_id and  ro.cancellation is null



