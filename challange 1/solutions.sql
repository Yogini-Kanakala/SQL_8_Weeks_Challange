
--What is the total amount each customer spent at the restaurant?
select  s.customer_id,  sum(m.price )
from sales s 
inner join menu m 
on  s.product_id= m.product_id
group by s.customer_id;


--How many days has each customer visited the restaurant?
select  customer_id, count(distinct order_date)
from sales 
group by customer_id;

-- What was the first item from the menu purchased by each customer?

with data as(
select  s.customer_id, m.product_name,s.order_date,
ROW_NUMBER() over( partition by s.customer_id order by s.order_date asc) as rank
from sales s inner join  menu m on s.product_id=m.product_id
)
select customer_id,product_name 
from data
where rank =1

--What is the most purchased item on the menu and how many times was it purchased by all customers?
select m.product_name, count(s.product_id)
from sales s inner join menu m
on s.product_id=m.product_id
group by m.product_name
order by count(s.product_id) desc
limit 1
--solution using CTE
WITH item_counts AS (
  SELECT 
    m.product_name, 
    COUNT(s.product_id) AS purchase_count,
    RANK() OVER (ORDER BY COUNT(s.product_id) DESC) AS rank
  FROM sales s
  INNER JOIN menu m ON s.product_id = m.product_id
  GROUP BY m.product_name
)
SELECT product_name, purchase_count
FROM item_counts
WHERE rank = 1;


--Which item was the most popular for each customer?
with data as (
select s.customer_id, m.product_name,
 count(m.product_name),
  DENSE_RANK() over( partition by s.customer_id order by count(m.product_name) desc ) as rank
from sales s inner join menu m
on s.product_id=m.product_id

group by s.customer_id,  m.product_name
) 
select customer_id , product_name
from data
where rank =1





--Which item was purchased first by the customer      after they became a member?

with data as (
select 
s.customer_id,
m.product_name,
s.order_date,
rank() over( partition by  s.customer_id order by s.order_date ) as rank
from sales s 
inner join menu m 
on s. product_id=m.product_id
inner join members mem
on s.customer_id=mem.customer_id
where s.order_date>= mem.join_date
)
select  customer_id, product_name
from data
where rank=1;

--What is the total items and amount spent for each member before they became a member?

select 
s.customer_id,
count(s.product_id),
sum(m.price)
from sales s inner join menu m 
on s.product_id=m.product_id
left join members mem 
on s.customer_id= mem.customer_id 
where s.order_date < mem.join_date or mem.join_date is null
group by s.customer_id


--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select 
s.customer_id,
sum(
case when  m.product_name='sushi' then m.price*2*10
else m.price*10
end) as points
from sales s inner join menu m 
on s.product_id=m.product_id
group by s.customer_id

--In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

select 
s.customer_id,
sum(
case when mem.join_date- s.order_date <= 6  then m.price*2*10
else m.price*10
end) as points
from sales s inner join menu m 
on s.product_id=m.product_id
inner join members mem 
on s.customer_id=mem.customer_id
and  s.order_date>= mem.join_date 
AND s.order_date <= '2021-01-31'
group by s.customer_id


--Write an SQL query to join customer purchases with product and membership data, indicating membership status based on purchase date versus join date. Extend the query to rank only member purchases by order date and price, showing NULL rank for non-members.
SELECT 
  s.customer_id,
  s.order_date,
  m.product_name,
  m.price,
  CASE 
    WHEN s.order_date >= mem.join_date THEN 'Y' 
    ELSE 'N' 
  END AS member,
  case when s.order_date >= mem.join_date then 
  rank() 
    OVER (
      PARTITION BY s.customer_id
      ORDER by
	  	CASE WHEN s.order_date >= mem.join_date THEN s.order_date ELSE NULL END,
          CASE WHEN s.order_date >= mem.join_date THEN m.price ELSE NULL END DESC
    ) 
	else null 
	end as ranking
FROM sales s
LEFT JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mem ON s.customer_id = mem.customer_id
ORDER BY s.customer_id, s.order_date, m.price DESC;