-- 1. What are the standard ingredients for each pizza?
select 
topping_id,topping_name,count(pizza_id) as topping_count
from pizza_runner.pizza_recipes_modified
group by 1,2
having count(pizza_id)>1
;



-- 2. What was the most commonly added extra?
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

-- 3. What was the most common exclusion?
with most_excluded_topping as (
select 
unnest(STRING_TO_ARRAY(exclusions, ',')) AS unnested_exclusions,
count(distinct order_id) as number_of_orders
from pizza_runner.customer_orders_modified
group by 1
order by 2 desc
limit 1
)

select
unnested_exclusions,topping_name,number_of_orders
from most_excluded_topping met
inner join pizza_runner.pizza_toppings pt
on pt.topping_id :: text= met.unnested_exclusions;


-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

WITH extras_cte AS (
SELECT 
e.record_id,
'Extra ' || STRING_AGG(t.topping_name, ', ') AS record_options
FROM pizza_runner.extras e
JOIN pizza_runner.pizza_toppings t ON e.topping_id = t.topping_id :: text
GROUP BY e.record_id
),
exclusions_cte AS (
    SELECT 
        e.record_id,
        'Exclude ' || STRING_AGG(t.topping_name, ', ') AS record_options
    FROM pizza_runner.exclusions e
    JOIN pizza_runner.pizza_toppings t ON e.topping_id = t.topping_id :: text
    GROUP BY e.record_id
),
union_cte AS (
    SELECT * FROM extras_cte
    UNION
    SELECT * FROM exclusions_cte
)

select 
record_id,order_id,
concat_ws('-',max(pn.pizza_name),string_agg(uc.record_options,'-')) as pizza_and_toppings
from pizza_runner.customer_orders_modified
inner join pizza_runner.pizza_names pn using(pizza_id)
left join union_cte uc using(record_id)
group by record_id, order_id
;



-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
with ingredients as (
select
record_id,order_id,
pizza_id,
prm.pizza_name,
case when prm.topping_id :: text in (select topping_id from pizza_runner.extras e where co.record_id=e.record_id) then '2x' || prm.topping_name :: text else prm.topping_name :: text end as topping
from pizza_runner.customer_orders_modified co
inner join pizza_runner.pizza_recipes_modified prm using(pizza_id)
where prm.topping_id :: text not in (select topping_id from pizza_runner.exclusions e where co.record_id=e.record_id))

select 
record_id,order_id,
concat(pizza_name,': ',String_agg(topping,',')) as pizza_and_ingredients
from ingredients
group by record_id,order_id,pizza_name;



-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

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
