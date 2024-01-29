-- Recursive CTE to create a base table 'customer_base' from subscriptions and plans
WITH RECURSIVE customer_base AS 
(
    SELECT 
        s.customer_id,
        s.plan_id,
        p.plan_name,
        s.start_date AS payment_date,
        s.start_date,
        LEAD(s.start_date, 1) OVER(PARTITION BY s.customer_id ORDER BY s.start_date, s.plan_id) AS next_date,
        p.price AS amount
    FROM foodie_fi.subscriptions s
    LEFT JOIN foodie_fi.plans p ON p.plan_id = s.plan_id
),

-- Filtered CTE 'customer_base_filter' to exclude 'trial' and 'churn' plans
customer_base_filter AS
(
    SELECT
        customer_id,
        plan_id,
        plan_name,
        payment_date,
        start_date,
        -- If 'next_date' is NULL or beyond '2020-12-31', set it to '2020-12-31'
        CASE WHEN next_date IS NULL OR next_date > '2020-12-31' THEN '2020-12-31'::date ELSE next_date END AS next_date,
        amount
    FROM customer_base
    WHERE plan_name NOT IN ('trial', 'churn')
),

-- Recursive CTE 'Date_CTE' for generating payment dates
Date_CTE AS
(
    SELECT
        customer_id,
        plan_id,
        plan_name,
        start_date,
        -- Subquery to find the earliest 'start_date' for each customer and plan
        (
            SELECT
                start_date
            FROM customer_base_filter
            WHERE customer_id = cbf.customer_id AND plan_id = cbf.plan_id
            ORDER BY start_date
            LIMIT 1
        ) AS payment_date,
        next_date,
        amount
    FROM customer_base_filter cbf

    UNION ALL

    SELECT
        b.customer_id,
        b.plan_id,
        b.plan_name,
        b.start_date,
        -- Increment 'payment_date' by one month
        (b.payment_date + INTERVAL '1 month'):: date AS payment_date,
        b.next_date,
        b.amount
    FROM Date_CTE b
    -- Continue recursion until 'payment_date' is less than 'next_date - 1 month' and 'plan_id' is not 3
    WHERE b.payment_date < b.next_date - interval '1 month' AND b.plan_id != 3
)

-- Final SELECT statement to retrieve data and apply ranking
SELECT 
    customer_id,
    plan_id,
    plan_name,
    payment_date,
    amount,
    -- Rank the payment dates within each customer's partition
    RANK() OVER(PARTITION BY customer_id ORDER BY payment_date) AS payment_order
FROM Date_CTE
WHERE extract(year from payment_date)='2020'
ORDER BY customer_id,plan_id,payment_date;


-- The growth rate is calculated as the number of customers at the start and at the end of the time interval
-- In this case it will be the growth rate in customers which were in 2020 and the new customers who joined in 2021.

with cust_db as(
select 
extract(year from start_date) as year,
extract(month from start_date) as month,
count(distinct customer_id)::decimal as current_month_customers,
lag(count(distinct customer_id)) over(order by extract(year from start_date))::decimal as prev_month_customers
from foodie_fi.subscriptions
group by 1,2
order by 1,2)

select 
year,month,current_month_customers,prev_month_customers,
round((current_month_customers -prev_month_customers)*100/prev_month_customers,2) as monthly_growth_rate
from cust_db





