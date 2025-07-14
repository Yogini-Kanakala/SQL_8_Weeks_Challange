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
