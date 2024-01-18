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


