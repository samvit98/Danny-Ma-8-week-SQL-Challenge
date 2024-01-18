-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT EXTRACT(WEEK FROM registration_date) AS week,
       COUNT(runner_id) AS runner_count
FROM pizza_runner.runners
GROUP BY EXTRACT(WEEK FROM registration_date);


-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
with successful_orders as 
(
  select
  order_id,runner_id,
  extract(minute from pickup_time :: timestamp - order_time) as time_taken_runner
  from pizza_runner.runner_orders_modified rom
  inner join pizza_runner.customer_orders_modified com using(order_id)
  where rom.cancellation is null

)

select 
runner_id,
avg(time_taken_runner) as avg_time_taken_by_runner_minutes
from successful_orders
group by 1
order by 2 asc;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
with successful_orders as 
(
  select
  order_id,runner_id,
  extract(minute from pickup_time :: timestamp - order_time) as time_taken_runner
  from pizza_runner.runner_orders_modified rom
  inner join pizza_runner.customer_orders_modified com using(order_id)
  where rom.cancellation is null

)

select 
runner_id,
avg(time_taken_runner) as avg_time_taken_by_runner_minutes
from successful_orders
group by 1
order by 2 asc;


-- 4. What was the average distance travelled for each customer?
with successful_orders as 
(
  select
  com.customer_id,round(avg(rom.distance_km),2) as avg_distance_travelled
  from pizza_runner.runner_orders_modified rom
  inner join pizza_runner.customer_orders_modified com using(order_id)
  where rom.cancellation is null
  group by 1
  order by 2 desc

)

select 
*
from successful_orders;

-- 5. What was the difference between the longest and shortest delivery times for all orders?
select
max(duration_mins) max_duration,
min(duration_mins) min_duration,
max(duration_mins)-min(duration_mins) as max_min_duration
from pizza_runner.runner_orders_modified rom
where rom.cancellation is null;

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
select
runner_id,
round(avg(distance_km/duration_mins),2) as avg_speed
from pizza_runner.runner_orders_modified rom
where rom.cancellation is null
group by 1
order by 2
;

-- 7. What is the successful delivery percentage for each runner?
select
runner_id,
round(avg(case when rom.cancellation is null then 1 else 0 end),2) as successful_delivery_percentage,
round(avg(distance_km/duration_mins),2) as avg_speed
from pizza_runner.runner_orders_modified rom
group by 1
order by 1;