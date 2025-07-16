-- How many unique nodes are there on the Data Bank system?

SELECT COUNT( DISTINCT(region_id, node_id)) AS total_region_node_combinations
FROM customer_nodes;


-- What is the number of nodes per region?

select region_id, count(node_id)
from customer_nodes 
group by region_id
order by region_id


-- How many customers are allocated to each region?
select region_id, count(distinct customer_id)
from customer_nodes 
group by region_id
order by region_id


-- How many days on average are customers reallocated to a different node?
select  avg(end_date-start_date) 
from customer_nodes
where  end_date !='9999-12-31'


-- What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

SELECT
    region_id,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY (end_date - start_date)) AS median_days,
    PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY (end_date - start_date)) AS p80_days,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY (end_date - start_date)) AS p95_days
FROM customer_nodes where  end_date !='9999-12-31'
GROUP BY region_id
ORDER BY region_id;


--     section B

-- What is the unique count and total amount for each transaction type?

select count(*),txn_type
from customer_transactions
group by txn_type

-- What is the average total historical deposit counts and amounts for all customers?
WITH data AS (
  SELECT
    customer_id,
    COUNT(*) FILTER (WHERE txn_type = 'deposit')    AS dep_count,
    SUM(txn_amount) FILTER (WHERE txn_type = 'deposit') AS dep_sum_amount
  FROM customer_transactions
  GROUP BY customer_id   
)
SELECT
  AVG(dep_count)      AS avg_deposit_count_per_customer,
  AVG(dep_sum_amount) AS avg_deposit_amount_per_customer
FROM data;


-- For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
with  data as (
select to_char(txn_date, 'YYYY-MM')as txn_month ,customer_id, 
count(*) filter(WHERE txn_type = 'deposit' ) as deposited ,
count(*) filter(WHERE txn_type = 'purchase'  or  txn_type = 'withdrawal' ) as used
from customer_transactions
group by customer_id, txn_month
)
select txn_month, count(customer_id)
from data 
where deposited> 1 and  used>=1
group by txn_month
order by txn_month

-- What is the closing balance for each customer at the end of the month?
WITH running_data AS (
  SELECT
    customer_id,
    to_char(txn_date, 'YYYY-MM') AS txn_month,
    txn_date,
    -- turn each txn into a signed amount
    CASE
      WHEN txn_type = 'deposit'                THEN  txn_amount
      WHEN txn_type IN ('withdrawal','purchase') THEN -txn_amount
      ELSE 0
    END AS signed_amount,
    -- cumulative running balance per customer over time
    SUM(
      CASE
        WHEN txn_type = 'deposit'                THEN  txn_amount
        WHEN txn_type IN ('withdrawal','purchase') THEN -txn_amount
        ELSE 0
      END
    ) OVER (
      PARTITION BY customer_id
      ORDER BY   txn_date
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_balance,
    -- identify the last txn in each customer/month
    ROW_NUMBER() OVER (
      PARTITION BY customer_id, to_char(txn_date, 'YYYY-MM')
      ORDER BY   txn_date DESC
    ) AS rn
  FROM customer_transactions
)
SELECT
  customer_id,
  txn_month           AS month,
  running_balance     AS closing_balance
FROM running_data
WHERE rn = 1
ORDER BY customer_id, txn_month;



-- What is the closing balance for each customer at the end of the month?
-- What is the percentage of customers who increase their closing balance by more than 5%?
WITH running_data AS (
  SELECT customer_id,
    to_char(txn_date, 'YYYY-MM') AS txn_month,
    txn_date,
    -- cumulative running balance per customer over time
    SUM(
      CASE
        WHEN txn_type = 'deposit'                THEN  txn_amount
        WHEN txn_type IN ('withdrawal','purchase') THEN -txn_amount
        ELSE 0
      END
    ) OVER (
      PARTITION BY customer_id
      ORDER BY   txn_date
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_balance,
    -- identify the last txn in each customer/month
    ROW_NUMBER() OVER (
      PARTITION BY customer_id, to_char(txn_date, 'YYYY-MM')
      ORDER BY   txn_date DESC
    ) AS rn
  FROM customer_transactions
),
customer_data as(
SELECT
  customer_id,
  txn_month           AS month,
  running_balance     AS closing_balance,
  case when running_balance is null  or  running_balance =0 then null 
  else 
  (lead(running_balance) over(partition by  customer_id) - running_balance  )*100.0/ running_balance 
  end  as percentage
FROM running_data
WHERE rn = 1
ORDER BY customer_id, txn_month
)

select  count( distinct case when percentage >5 then customer_id  end)*100.0/ count(distinct customer_id)
from customer_data
where percentage is not null 


-- C. Data Allocation Challenge
-- To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

-- Option 1: data is allocated based off the amount of money at the end of the previous month
-- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
-- Option 3: data is updated real-time
-- For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

-- running customer balance column that includes the impact each transaction
-- customer balance at the end of each month
-- minimum, average and maximum values of the running balance for each customer
-- Using all of the data available - how much data would have been required for each option on a monthly basis?

WITH data AS (
  SELECT 
    customer_id,
    TO_CHAR(txn_date, 'YYYY-MM') AS txn_month,
    txn_date,
    SUM(
      CASE
        WHEN txn_type = 'deposit' THEN txn_amount
        WHEN txn_type IN ('withdrawal', 'purchase') THEN - txn_amount
        ELSE 0
      END
    ) OVER (
      PARTITION BY customer_id
      ORDER BY txn_date
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_balance
  FROM customer_transactions
)
SELECT 
  customer_id, 
  txn_month,
  running_balance,
  LAST_VALUE(running_balance) OVER (
    PARTITION BY customer_id, txn_month
    ORDER BY txn_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
  ) AS month_end_balance,
  MIN(running_balance) OVER (PARTITION BY customer_id, txn_month) AS min_end_balance,
  MAX(running_balance) OVER (PARTITION BY customer_id, txn_month) AS max_end_balance,
  AVG(running_balance) OVER (PARTITION BY customer_id, txn_month) AS avg_end_balance
FROM data
ORDER BY customer_id, txn_month;

