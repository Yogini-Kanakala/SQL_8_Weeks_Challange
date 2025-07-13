
-- Based off the 8 sample customers provided in the sample from the subscriptions table, 
-- write a brief description about each customer’s onboarding journey.
-- Try to keep it as short as possible - you may also want to run some sort of join to make your
--  explanations a bit easier!

SELECT s.customer_id, 
	string_agg(p.plan_name ,' - > ' ORDER BY s.start_date ) as customer_journey,
	COUNT(s.plan_id) AS plan_count,
 	SUM(p.price) AS total_spent

FROM foodie_fi.subscriptions as s left join foodie_fi.plans p 
on s.plan_id=p.plan_id
group by s.customer_id
order by total_spent desc 



-- B. Data Analysis Questions
-- How many customers has Foodie-Fi ever had?
select distinct count(customer_id) from foodie_fi.subscriptions

-- What is the monthly distribution of trial plan start_date values for our dataset 
-- - use the start of the month as the group by value

select count(*) as sub_count,
TO_CHAR( s.start_date, 'mm-yyyy') as sub_month
from foodie_fi.subscriptions s
inner join foodie_fi.plans p
on s.plan_id=p.plan_id and s.plan_id = 0
group by sub_month
order by sub_month



-- What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name


select count(*) as sub_count,
p.plan_name
from foodie_fi.subscriptions s
left join foodie_fi.plans p
on s.plan_id=p.plan_id 
where s.start_date > to_date('31-12-2020','dd-mm-yyyy')
group by p.plan_name
ORDER BY sub_count DESC;



-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT 
    SUM(CASE WHEN p.plan_id = 4 THEN 1 ELSE 0 END) AS churn_count,
    ROUND(
        (SUM(CASE WHEN p.plan_id = 4 THEN 1 ELSE 0 END)::numeric / COUNT(DISTINCT s.customer_id)::numeric) * 100,
        1
    ) AS churn_percentage,
    COUNT(DISTINCT s.customer_id) AS total_customers
FROM foodie_fi.subscriptions s
LEFT JOIN foodie_fi.plans p ON s.plan_id = p.plan_id;


-- How many customers have churned straight after their initial free trial 
-- - what percentage is this rounded to the nearest whole number?

with data as (
SELECT 
   s.customer_id,
	s.plan_id as s_plan,
	lead(s.plan_id) over(partition by s.customer_id order by s.start_date) as n_plan

FROM foodie_fi.subscriptions s
LEFT JOIN foodie_fi.plans p ON s.plan_id = p.plan_id 
 )

 select  round( sum(case when  s_plan=1 and n_plan =4 then 1 else 0 end )::float /count(distinct customer_id) ::float *100) as churned_percentage
 from data 



-- What is the number and percentage of customer plans after their initial free trial?

with data as(
SELECT  customer_id, plan_id,
rank() over(partition by customer_id order by start_date) as plan_rank


FROM foodie_fi.subscriptions where plan_id!=0
)
select 
COUNT(DISTINCT customer_id) AS customers_after_trial,
    (COUNT(DISTINCT customer_id) * 100.0 / (SELECT COUNT(DISTINCT customer_id) FROM foodie_fi.subscriptions)) AS percentage_after_trial
from data 
WHERE plan_rank > 1



-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?


with data as (
select p.plan_name, 
count(*) over(partition by p.plan_name),
rank() over(partition by customer_id order by start_date desc) as plan_rank,
 COUNT(*) OVER() AS total_count ,
customer_id
from foodie_fi.subscriptions s
left join foodie_fi.plans p
on s.plan_id=p.plan_id
where s. start_date <=to_date('2020-12-31','yyyy-mm-dd')
)

select count(distinct customer_id) ,plan_name,
  (COUNT(DISTINCT customer_id) * 100.0) / MAX(total_count) AS percentage
from data where plan_rank=1
group by plan_name



-- How many customers have upgraded to an annual plan in 2020?

SELECT COUNT(DISTINCT s.customer_id)
FROM foodie_fi.subscriptions s
JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
WHERE s.start_date BETWEEN '2020-01-01' AND '2020-12-31'
  AND p.plan_name = 'pro annual'
  AND s.customer_id IN (
    SELECT DISTINCT customer_id
    FROM foodie_fi.subscriptions
    WHERE start_date BETWEEN '2020-01-01' AND '2020-12-31'
      AND plan_id != 3
  );



-- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?


WITH join_dates AS (
  SELECT customer_id,
         MIN(start_date) AS join_date
  FROM subscriptions
  GROUP BY customer_id
),
annual_plan_dates AS (
  SELECT customer_id,
         MIN(start_date) AS annual_start_date
  FROM subscriptions
  WHERE plan_id = 3
  GROUP BY customer_id
)
SELECT AVG(annual_start_date - join_date) AS avg_days_to_annual
FROM join_dates
JOIN annual_plan_dates USING (customer_id);



