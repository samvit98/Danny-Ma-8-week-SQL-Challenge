-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
with successful_deliveries as (
select
record_id,com.pizza_id,pn.pizza_name, case when com.pizza_id=1 then 12 else 10 end as pizza_price
from pizza_runner.runner_orders_modified rom
join pizza_runner.customer_orders_modified com using(order_id)
join pizza_runner.pizza_names pn on com.pizza_id=pn.pizza_id
where rom.cancellation is null)

select sum(pizza_price) as total_money_made
from successful_deliveries
;




-- 2.  What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra
with extra_unnested as (
select
record_id,order_id,pizza_id,unnest(string_to_array(extras,',')) as unnested_extras 
from pizza_runner.customer_orders_modified com),
extra_count as (
  select
  record_id,pizza_id, count(unnested_extras) as extra_count
  from extra_unnested
  group by 1,2
),
successful_deliveries as (
select
com.record_id,com.order_id,com.pizza_id,case when com.pizza_id=1 then 12 else 10 end + coalesce(ec.extra_count,0) as pizza_price_with_extras
from pizza_runner.runner_orders_modified rom
join pizza_runner.customer_orders_modified com using(order_id)  
left join extra_count ec on com.record_id=ec.record_id
 where rom.cancellation is null)
 
 select 
 sum(pizza_price_with_extras) total_earning
 from successful_deliveries
  ;




-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

CREATE TABLE pizza_runner.ratings
(
  "order_id" INTEGER,
  "rating" INTEGER

);

INSERT INTO pizza_runner.ratings
("order_id","rating")
VALUES
(1,3),
(2,4),
(3,5),
(4,2),
(5,1),
(6,3),
(7,4),
(8,1),
(9,3),
(10,5); 

select * from pizza_runner.ratings;




-- 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- customer_id
-- order_id
-- runner_id
-- rating
-- order_time
-- pickup_time
-- Time between order and pickup
-- Delivery duration
-- Average speed
-- Total number of pizzas
-- If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
with successful_deliveries as (
select
com.customer_id,
com.record_id,
rom.runner_id,
r.rating,
com.order_time,
rom.pickup_time,
extract(minute from (rom.pickup_time ::timestamp - com.order_time)) as order_pickup_diff,
rom.duration_mins,
rom.distance_km,
rom.distance_km/(rom.duration_mins + extract(minute from (rom.pickup_time ::timestamp - com.order_time))) as avg_speed,
case when com.pizza_id=1 then 12 else 10 end as pizza_price,
rom.distance_km*0.3 as delivery_fee,
case when com.pizza_id=1 then 12 else 10 end + rom.distance_km*0.3 as total_fee_with_delivery

from pizza_runner.runner_orders_modified rom
join pizza_runner.customer_orders_modified com using(order_id) 
left join pizza_runner.ratings r on r.order_id = com.order_id
where rom.cancellation is null
)
select 
sum(total_fee_with_delivery) as total_earning
from successful_deliveries;