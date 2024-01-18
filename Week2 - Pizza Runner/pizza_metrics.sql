-- 1. How many pizzas were ordered?
select
count(pizza_id) as total_pizzas_ordered
from pizza_runner.customer_orders;


-- 2. How many unique customer orders were made?
select
count(distinct order_id) as total_orders_made
from pizza_runner.runner_orders_modified
where cancellation is null;


-- 3. How many successful orders were delivered by each runner?
select
runner_id,count(distinct order_id) orders_delivered
from pizza_runner.runner_orders_modified
where cancellation is null
group by 1
order by 2 desc;

-- 4. How many of each type of pizza was delivered?
with delivered_pizzas as (
select * from pizza_runner.runner_orders_modified
where cancellation is null)

select 
co.pizza_id,pn.pizza_name,count(*) pizza_num_delivered
from delivered_pizzas dp
left join pizza_runner.customer_orders  co using(order_id)
inner join pizza_runner.pizza_names pn  on pn.pizza_id = co.pizza_id
group by 1,2
order by 3 desc;



-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
with delivered_pizzas as (
select * from pizza_runner.runner_orders_modified
)

select 
co.customer_id,pn.pizza_name,count(*) pizza_type_ordered
from delivered_pizzas dp
left join pizza_runner.customer_orders  co using(order_id)
inner join pizza_runner.pizza_names pn  on pn.pizza_id = co.pizza_id
group by 1,2
order by co.customer_id asc, count(*) desc ;


-- 6. What was the maximum number of pizzas delivered in a single order?
with completed_orders as (
select 
*
from pizza_runner.runner_orders_modified
where cancellation is null
)

select
comp.order_id,count(co.pizza_id) pizzas_delivered
from completed_orders comp
join pizza_runner.customer_orders_modified co
on co.order_id=comp.order_id
group by 1
order by 2 desc
limit 1;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
with cte0 as (
select
customer_id,order_id,pizza_id,extras,exclusions,
case when extras is not null or exclusions is not null then 'Changes' else 'No Changes' end as changes
from pizza_runner.customer_orders_modified)

select
customer_id,changes,count(changes) as count_changes
from cte0
right join pizza_runner.runner_orders_modified ro using(order_id)
where ro.cancellation is null
group by 1,2
order by 3 desc;


-- 8. How many pizzas were delivered that had both exclusions and extras?
with cte0 as (
select
customer_id,order_id,pizza_id,extras,exclusions,
case when extras is not null and exclusions is not null then 'Changes' else 'No Changes' end as changes
from pizza_runner.customer_orders_modified)

select
changes, count(changes) as changes_count
from cte0
right join pizza_runner.runner_orders_modified ro using(order_id)
where ro.cancellation is null
group by 1
order by 2 desc


-- 9. What was the total volume of pizzas ordered for each hour of the day?
select
extract(hour from order_time) as hour_of_day,
count(pizza_id) as pizzas_ordered
from pizza_runner.customer_orders_modified
group by 1
order by 2 desc;


-- 10. What was the volume of orders for each day of the week?
select
extract(dow from order_time) as day_of_week,
to_char(order_time,'Day') as dow,
count(pizza_id) as pizzas_ordered
from pizza_runner.customer_orders_modified
group by 1,2
order by 3 desc;