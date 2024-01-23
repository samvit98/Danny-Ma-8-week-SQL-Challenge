-- Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

select 
s.customer_id,s.plan_id,p.plan_name,p.price,s.start_date
from foodie_fi.subscriptions s
join foodie_fi.plans p using(plan_id)
where s.customer_id in (1,2,11,13,15,16,18,19)
order by s.customer_id,s.start_date
;


-- Data Analysis Questions

-- 1. How many customers has Foodie-Fi ever had?
select
count(distinct customer_id) as total_customers
from foodie_fi.subscriptions s;

-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
select
extract(month from start_date) as month,
count(plan_id) as count_of_trial_plans
from foodie_fi.subscriptions s
where plan_id=0
group by extract(month from start_date)
order by 1;


-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
select
plan_id,plan_name,
count(*) as events_per_plan
from foodie_fi.subscriptions s
join foodie_fi.plans p using(plan_id)
where extract(year from start_date)>2020
group by 1,2
order by 1;

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
select
sum(case when plan_id=4 then 1 else 0 end) as customer_churn_count,
round(sum(case when plan_id=4 then 1 else 0 end) :: decimal /count(distinct customer_id) :: decimal,1) as percentage_cust_churned
from foodie_fi.subscriptions s;


-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
with cust_db as (
select 
customer_id,plan_id,start_date::date as start_date,
lead(plan_id)  over(partition by customer_id order by start_date) as next_plan
from foodie_fi.subscriptions s
order by customer_id,start_date)

select 
sum(case when plan_id = 0 and next_plan=4 then 1 else 0 end) as count_cust_churn,
sum(case when plan_id = 0 and next_plan=4 then 1 else 0 end)::decimal / count(distinct customer_id)::decimal as percentage_cust_churn
from cust_db;


-- 6. What is the number and percentage of customer plans after their initial free trial?
with cust_db as (
select 
customer_id,plan_id,start_date::date as start_date,
lead(plan_id)  over(partition by customer_id order by start_date) as next_plan
from foodie_fi.subscriptions s
order by customer_id,start_date
)

select 
next_plan,count(*) as next_plans,round(count(*)::decimal / (select count(distinct customer_id) from cust_db) :: decimal,2) as percentage_of_customer_plans
from cust_db 
where plan_id = 0 and next_plan is not null
group by next_plan
;



-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
with cust_db as (

  select
  *,
  lead(start_date) over(partition by customer_id order by start_date) as next_date
  from foodie_fi.subscriptions s
  where start_date<='2020-12-31'

)


select  
c.plan_id,
p.plan_name,
count(plan_id) as customer_count,
round(count(plan_id):: decimal * 100 / (select count(distinct customer_id) from cust_db)::decimal,2) as percentage
from cust_db c
join foodie_fi.plans p using(plan_id)

-- this condition is put up to find the latest active plan of the customer and not all previous plans
where next_date is null or next_date >'2020-12-31' 


group by 
c.plan_id,
p.plan_name
order by 
c.plan_id;

-- 8. How many customers have upgraded to an annual plan in 2020?
with cust_db as (
select
*,
lead(plan_id) over(partition by customer_id order by start_date) as next_plan,
lead(start_date) over(partition by customer_id order by start_date) as next_start_date
from foodie_fi.subscriptions s)

select
count(distinct customer_id)
from cust_db
where next_plan = 3 and next_start_date <= '2020-12-31'
;


-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
with cust_db as (
select
*,
lead(plan_id) over(partition by customer_id order by start_date) as next_plan,
lead(start_date) over(partition by customer_id order by start_date) as next_start_date
from foodie_fi.subscriptions s),
first_day as (
select
customer_id,
min(start_date) as first_day
from foodie_fi.subscriptions s
 group by 1
  order by 1
), days_to_annual as (
select
customer_id,next_start_date,first_day, next_start_date-first_day as days
from cust_db
join first_day using(customer_id)
where next_plan=3)


select 
avg(days) as avg_days_to_annual
from days_to_annual;

-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
with cust_db as (
select
*,
lead(plan_id) over(partition by customer_id order by start_date) as next_plan,
lead(start_date) over(partition by customer_id order by start_date) as next_start_date
from foodie_fi.subscriptions s),
first_day as (
select
customer_id,
min(start_date) as first_day
from foodie_fi.subscriptions s
 group by 1
  order by 1
), days_to_annual as (
select
customer_id,next_start_date,first_day, next_start_date-first_day as days
from cust_db
join first_day using(customer_id)
where next_plan=3),
db_final as (
select 
*,
FLOOR(days/30) as group_day
from days_to_annual
)
SELECT CONCAT((group_day *30) +1 , '-',(group_day +1)*30, ' days') as days,
        COUNT(group_day) as number_days
FROM db_final
GROUP BY group_day;

-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
with cust_db as (
select
*,
lead(plan_id) over(partition by customer_id order by start_date) as next_plan,
lead(start_date) over(partition by customer_id order by start_date) as next_start_date
from foodie_fi.subscriptions s)

select 
count(*) as customers_downgrade
from cust_db
where next_plan = 1 and plan_id=2 and start_date <= '2020-12-31';
