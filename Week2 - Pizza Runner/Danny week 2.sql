-- Data Modification and Cleaning:
CREATE TABLE pizza_runner.runner_orders_modified AS
SELECT
  order_id,
  runner_id,
  pickup_time,
  CASE WHEN TRIM(RTRIM(LOWER(distance), 'km')) = 'null' THEN NULL
       ELSE TRIM(RTRIM(LOWER(distance), 'km'))::DECIMAL
  END AS distance_km,
  CASE WHEN TRIM(REGEXP_REPLACE(duration, '\D', '', 'g')) = '' THEN NULL
       ELSE TRIM(REGEXP_REPLACE(duration, '\D', '', 'g'))::DECIMAL
  END AS duration_mins,
  CASE WHEN TRIM(cancellation) = 'Restaurant Cancellation' THEN 'rc'
       WHEN TRIM(cancellation) = 'Customer Cancellation' THEN 'cc'
       ELSE NULL
  END AS cancellation
FROM pizza_runner.runner_orders;

CREATE TABLE pizza_runner.customer_orders_modified AS
SELECT order_id, 
       customer_id,
       pizza_id, 
       row_number() over () as record_id,
       CASE WHEN exclusions = '' or exclusions like 'null' or exclusions like 'NaN' THEN NULL
            ELSE exclusions END AS exclusions,
       CASE WHEN extras = '' OR extras like 'null' or extras like 'NaN' THEN NULL
            ELSE extras END AS extras, 
       order_time
FROM pizza_runner.customer_orders;


CREATE TABLE pizza_runner.pizza_recipes_modified AS

with pizza as (
select
pizza_id,
trim(unnest(string_to_array(toppings,','))) as toppings

from pizza_runner.pizza_recipes pr)
select
pizza_id,pizza_name,topping_id,topping_name
from pizza p
left join pizza_runner.pizza_toppings pt 
on cast(pt.topping_id as text)=p.toppings
left join pizza_runner.pizza_names pn using(pizza_id)
order by pizza_id
;

select * from pizza_runner.pizza_recipes_modified;

create table pizza_runner.extras as
select
record_id,
unnest(string_to_array(extras,',')) as topping_id
from pizza_runner.customer_orders_modified ;


create table pizza_runner.exclusions as
select
record_id,
unnest(string_to_array(exclusions,',')) as topping_id
from pizza_runner.customer_orders_modified ;


-- 1. How many pizzas were ordered?
-- select
-- count(pizza_id) as total_pizzas_ordered
-- from pizza_runner.customer_orders;


-- 2. How many unique customer orders were made?
-- select
-- count(distinct order_id) as total_orders_made
-- from pizza_runner.runner_orders_modified
-- where cancellation is null;


-- 3. How many successful orders were delivered by each runner?
-- select
-- runner_id,count(distinct order_id) orders_delivered
-- from pizza_runner.runner_orders_modified
-- where cancellation is null
-- group by 1
-- order by 2 desc;

-- 4. How many of each type of pizza was delivered?
-- with delivered_pizzas as (
-- select * from pizza_runner.runner_orders_modified
-- where cancellation is null)

-- select 
-- co.pizza_id,pn.pizza_name,count(*) pizza_num_delivered
-- from delivered_pizzas dp
-- left join pizza_runner.customer_orders  co using(order_id)
-- inner join pizza_runner.pizza_names pn  on pn.pizza_id = co.pizza_id
-- group by 1,2
-- order by 3 desc;



-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
-- with delivered_pizzas as (
-- select * from pizza_runner.runner_orders_modified
-- )

-- select 
-- co.customer_id,pn.pizza_name,count(*) pizza_type_ordered
-- from delivered_pizzas dp
-- left join pizza_runner.customer_orders  co using(order_id)
-- inner join pizza_runner.pizza_names pn  on pn.pizza_id = co.pizza_id
-- group by 1,2
-- order by co.customer_id asc, count(*) desc ;


-- 6. What was the maximum number of pizzas delivered in a single order?
-- with completed_orders as (
-- select 
-- *
-- from pizza_runner.runner_orders_modified
-- where cancellation is null
-- )

-- select
-- comp.order_id,count(co.pizza_id) pizzas_delivered
-- from completed_orders comp
-- join pizza_runner.customer_orders_modified co
-- on co.order_id=comp.order_id
-- group by 1
-- order by 2 desc
-- limit 1;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
-- with cte0 as (
-- select
-- customer_id,order_id,pizza_id,extras,exclusions,
-- case when extras is not null or exclusions is not null then 'Changes' else 'No Changes' end as changes
-- from pizza_runner.customer_orders_modified)

-- select
-- customer_id,changes,count(changes) as count_changes
-- from cte0
-- right join pizza_runner.runner_orders_modified ro using(order_id)
-- where ro.cancellation is null
-- group by 1,2
-- order by 3 desc;


-- 8. How many pizzas were delivered that had both exclusions and extras?
-- with cte0 as (
-- select
-- customer_id,order_id,pizza_id,extras,exclusions,
-- case when extras is not null and exclusions is not null then 'Changes' else 'No Changes' end as changes
-- from pizza_runner.customer_orders_modified)

-- select
-- changes, count(changes) as changes_count
-- from cte0
-- right join pizza_runner.runner_orders_modified ro using(order_id)
-- where ro.cancellation is null
-- group by 1
-- order by 2 desc


-- 9. What was the total volume of pizzas ordered for each hour of the day?
-- select
-- extract(hour from order_time) as hour_of_day,
-- count(pizza_id) as pizzas_ordered
-- from pizza_runner.customer_orders_modified
-- group by 1
-- order by 2 desc;


-- 10. What was the volume of orders for each day of the week?
-- select
-- extract(dow from order_time) as day_of_week,
-- to_char(order_time,'Day') as dow,
-- count(pizza_id) as pizzas_ordered
-- from pizza_runner.customer_orders_modified
-- group by 1,2
-- order by 3 desc;


-- Runner and Customer experience

-- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
-- SELECT EXTRACT(WEEK FROM registration_date) AS week,
--        COUNT(runner_id) AS runner_count
-- FROM pizza_runner.runners
-- GROUP BY EXTRACT(WEEK FROM registration_date);


-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
-- with successful_orders as 
-- (
--   select
--   order_id,runner_id,
--   extract(minute from pickup_time :: timestamp - order_time) as time_taken_runner
--   from pizza_runner.runner_orders_modified rom
--   inner join pizza_runner.customer_orders_modified com using(order_id)
--   where rom.cancellation is null

-- )

-- select 
-- runner_id,
-- avg(time_taken_runner) as avg_time_taken_by_runner_minutes
-- from successful_orders
-- group by 1
-- order by 2 asc

-- Is there any relationship between the number of pizzas and how long the order takes to prepare?
-- with successful_orders as 
-- (
--   select
--   order_id,runner_id,
--   extract(minute from pickup_time :: timestamp - order_time) as time_taken_runner
--   from pizza_runner.runner_orders_modified rom
--   inner join pizza_runner.customer_orders_modified com using(order_id)
--   where rom.cancellation is null

-- )

-- select 
-- runner_id,
-- avg(time_taken_runner) as avg_time_taken_by_runner_minutes
-- from successful_orders
-- group by 1
-- order by 2 asc


-- What was the average distance travelled for each customer?
-- What was the difference between the longest and shortest delivery times for all orders?
-- What was the average speed for each runner for each delivery and do you notice any trend for these values?
-- What is the successful delivery percentage for each runner?



-- Ingredient Optimization
-- What are the standard ingredients for each pizza?
-- select 
-- topping_id,topping_name,count(pizza_id) as topping_count
-- from pizza_runner.pizza_recipes_modified
-- group by 1,2
-- having count(pizza_id)>1
-- ;



-- What was the most commonly added extra?
with most_used_topping as (
select 
unnest(STRING_TO_ARRAY(extras, ',')) AS unnested_extras,
count(distinct order_id) as number_of_orders
from pizza_runner.customer_orders_modified
group by 1
order by 2 desc
limit 1
)
select
unnested_extras,topping_name,number_of_orders
from most_used_topping mut
left join pizza_runner.pizza_recipes_modified prm
on prm.topping_id :: text = mut.unnested_extras
;

-- What was the most common exclusion?
with most_excluded_topping as (
select 
unnest(STRING_TO_ARRAY(exclusions, ',')) AS unnested_exclusions,
count(distinct order_id) as number_of_orders
from pizza_runner.customer_orders_modified
group by 1
order by 2 desc
limit 1
)
-- select * from pizza_runner.pizza_recipes_modified;
select
unnested_exclusions,topping_name,number_of_orders
from most_excluded_topping met
inner join pizza_runner.pizza_toppings pt
on pt.topping_id :: text= met.unnested_exclusions;


-- Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

-- WITH extras_cte AS (
-- SELECT 
-- e.record_id,
-- 'Extra ' || STRING_AGG(t.topping_name, ', ') AS record_options
-- FROM pizza_runner.extras e
-- JOIN pizza_runner.pizza_toppings t ON e.topping_id = t.topping_id :: text
-- GROUP BY e.record_id
-- ),
-- exclusions_cte AS (
--     SELECT 
--         e.record_id,
--         'Exclude ' || STRING_AGG(t.topping_name, ', ') AS record_options
--     FROM pizza_runner.exclusions e
--     JOIN pizza_runner.pizza_toppings t ON e.topping_id = t.topping_id :: text
--     GROUP BY e.record_id
-- ),
-- union_cte AS (
--     SELECT * FROM extras_cte
--     UNION
--     SELECT * FROM exclusions_cte
-- )

-- select 
-- record_id,order_id,
-- concat_ws('-',max(pn.pizza_name),string_agg(uc.record_options,'-')) as pizza_and_toppings
-- from pizza_runner.customer_orders_modified
-- inner join pizza_runner.pizza_names pn using(pizza_id)
-- left join union_cte uc using(record_id)
-- group by record_id, order_id
-- ;



-- Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
-- with ingredients as (
-- select
-- record_id,order_id,
-- pizza_id,
-- prm.pizza_name,
-- case when prm.topping_id :: text in (select topping_id from pizza_runner.extras e where co.record_id=e.record_id) then '2x' || prm.topping_name :: text else prm.topping_name :: text end as topping
-- from pizza_runner.customer_orders_modified co
-- inner join pizza_runner.pizza_recipes_modified prm using(pizza_id)
-- where prm.topping_id :: text not in (select topping_id from pizza_runner.exclusions e where co.record_id=e.record_id))

-- select 
-- record_id,order_id,
-- concat(pizza_name,': ',String_agg(topping,',')) as pizza_and_ingredients
-- from ingredients
-- group by record_id,order_id,pizza_name;



-- What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

with successful_deliveries as (
select
*
from pizza_runner.runner_orders_modified
join pizza_runner.customer_orders_modified using(order_id)
where cancellation is null
),
cte2 as (
select
record_id,pizza_id,pizza_name,topping_id,topping_name,case when topping_id :: text in (select topping_id from pizza_runner.extras e where sd.record_id=e.record_id) then 2 else 1 end as topping_quantity
from successful_deliveries sd
inner join pizza_runner.pizza_recipes_modified prm using(pizza_id)
where topping_id :: text not in (select topping_id from pizza_runner.extras e where sd.record_id=e.record_id)
order by 1)

select topping_id,topping_name, sum(topping_quantity)
from cte2
group by 1,2
order by 3 desc
