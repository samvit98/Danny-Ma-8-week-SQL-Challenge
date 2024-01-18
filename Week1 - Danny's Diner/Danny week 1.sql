/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

-- 1:
select
s.customer_id,sum(m.price)
from dannys_diner.sales s
left join dannys_diner.menu m using(product_id)
group by 1
order by 2 desc

--2
select
customer_id,count(distinct order_date) as days_visited_rest
from dannys_diner.sales
group by 1 
order by 2 desc

--3
with d_rank_cte as (
select
customer_id,m.product_name,s.order_date,dense_rank() over(partition by customer_id order by order_date asc) as d_rank
from dannys_diner.sales s
left join dannys_diner.menu m using(product_id))

select customer_id,product_name
from d_rank_cte
where d_rank=1

--4 What is the most purchased item on the menu and how many times was it purchased by all customers?

with popular_product as (
select
s.product_id, count(*) product_order_num
from dannys_diner.sales s
group by s.product_id
order by 2 desc
limit 1
)

select 
s.customer_id,m.product_name,count(*) order_num
from dannys_diner.sales s
left join dannys_diner.menu m using(product_id)
where s.product_id in (select product_id from popular_product)
group by 1,2
order by 3 desc

-- 5. Which item was the most popular for each customer?
with customer_item_counts as (
select
s.customer_id,s.product_id,count(*) as order_num
from dannys_diner.sales s
group by 1,2
order by customer_id asc,count(*) desc
),
fav_food_rank as (

  select *,dense_rank() over(partition by customer_id order by order_num desc) as prod_rank
  from customer_item_counts
)

select
customer_id,product_name,order_num
from fav_food_rank f
left join dannys_diner.menu m using(product_id)
where prod_rank=1

-- 6. Which item was purchased first by the customer after they became a member?
With Rank as
(
Select  S.customer_id,
        M.product_name,
	Dense_rank() OVER (Partition by S.Customer_id Order by S.Order_date) as Rank
From dannys_diner.Sales S
Join dannys_diner.Menu M
ON m.product_id = s.product_id
JOIN dannys_diner.Members Mem
ON Mem.Customer_id = S.customer_id
Where S.order_date >= Mem.join_date  
)
Select *
From Rank
Where Rank = 1

-- 7. Which item was purchased just before the customer became a member?
With Rank as
(
Select  S.customer_id,
        M.product_name,
	Dense_rank() OVER (Partition by S.Customer_id Order by S.Order_date desc) as d_rank
From dannys_diner.Sales S
Join dannys_diner.Menu M
ON m.product_id = s.product_id
JOIN dannys_diner.Members Mem
ON Mem.Customer_id = S.customer_id
Where S.order_date < Mem.join_date  
)

select * from Rank
where d_rank=1

-- 8. What is the total items and amount spent for each member before they became a member?

select
s.customer_id,count(product_id) as total_items,sum(men.price) as amt_spent
from dannys_diner.sales s
inner join dannys_diner.members m 
on s.customer_id=m.customer_id and s.order_date < m.join_date
left join dannys_diner.menu men using(product_id)
group by 1
order by 1

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with sales_with_points as (
select
customer_id,product_id,
case when men.product_name = 'sushi' then 20*men.price 
else 10*men.price end as points
from dannys_diner.sales s
left join dannys_diner.menu men using (product_id))

select 
customer_id, sum(points) as total_points
from sales_with_points
group by 1
order by 2 desc


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

select
customer_id,
sum(case when (order_date >= join_date and order_date<= join_date + Interval '7' day) or (s.product_id =1) then 20* men.price
else 10*men.price end) as total_points
from dannys_diner.sales s
inner join dannys_diner.members mem using(customer_id)
left join dannys_diner.menu men using (product_id)
where extract(month from order_date)=1 
group by customer_id
order by 2 desc