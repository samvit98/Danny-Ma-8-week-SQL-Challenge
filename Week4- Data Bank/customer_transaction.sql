-- Customer Transactions
-- What is the unique count and total amount for each transaction type?
select
txn_type,
count(*) as txn_cnt,
sum(txn_amount) as total_amount
from data_bank.customer_transactions
group by 1
;
-- What is the average total historical deposit counts and amounts for all customers?
with cust_txn_db as (
select
customer_id,txn_type,
count(*) as txn_cnt,
sum(txn_amount) as total_txn_amount
from data_bank.customer_transactions
where txn_type = 'deposit'
group by 1,2)

select
txn_type,
round(avg(txn_cnt),2) as avg_deposit_cnt,
round(avg(total_txn_amount),2) as avg_amt_deposit
from cust_txn_db
group by 1
;

-- For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

with cust_txn_db as (
select
customer_id,
extract(month from txn_date) as month_id,
to_char(txn_date, 'Month') AS month_name,
sum(case when txn_type = 'deposit' then 1 else 0 end) as deposit_cnt,
sum(case when txn_type <> 'deposit' then 1 else 0 end) as purchase_or_withdrawl_cnt
from data_bank.customer_transactions
group by 1,2,3)

select 
month_id,month_name,
count(customer_id) as cust_cnt
from cust_txn_db
where deposit_cnt>1 and purchase_or_withdrawl_cnt=1
group by month_id,month_name
order by 1
;

-- What is the closing balance for each customer at the end of the month?
with cust_txn as(
select
customer_id,
date_trunc('month' ,txn_date) as month_id,txn_date,
sum(case when txn_type = 'deposit' then txn_amount else -txn_amount end) as txn_action
from data_bank.customer_transactions
group by customer_id,extract(month from txn_date),txn_date
order by customer_id,txn_date),
cust_last_txn_month as (
select 
*,
sum(txn_action) over (partition by customer_id order by txn_date asc) as balance,
dense_rank() over (partition by customer_id,month_id order by txn_date desc) as dr
from cust_txn)

select 
customer_id, month_id + interval '1 month' - interval '1 day' as month_end, balance as closing_balance
from cust_last_txn_month
where dr=1
;


-- What is the percentage of customers who increase their closing balance by more than 5%?

with cust_txn as(
select
customer_id,
date_trunc('month' ,txn_date) as month_id,txn_date,
sum(case when txn_type = 'deposit' then txn_amount else -txn_amount end) as txn_action
from data_bank.customer_transactions
-- where customer_id=109
group by customer_id,extract(month from txn_date),txn_date
order by customer_id,txn_date),
cust_last_txn_month as (
select 
*,
sum(txn_action) over (partition by customer_id order by txn_date asc) as balance,
  dense_rank() over (partition by customer_id,month_id order by txn_date desc) as dr
from cust_txn),
cust_closing_bal as (
select 
customer_id, month_id + interval '1 month' - interval '1 day' as month_end, balance as closing_balance,
lag(balance) over(partition by customer_id order by month_id + interval '1 month' - interval '1 day') as prev_closing_balance
from cust_last_txn_month
where dr=1),
final_db as (
select 
*,
(closing_balance-prev_closing_balance) / prev_closing_balance as percent_change_closing_bal,
case when (closing_balance > prev_closing_balance) and ((closing_balance-prev_closing_balance) / prev_closing_balance)>0.05 then 1 else 0 end as more_than_5_percent
from cust_closing_bal
where prev_closing_balance is not null and prev_closing_balance <> 0)

select
round((sum(more_than_5_percent) :: decimal / 
count(more_than_5_percent):: decimal)*100,2) as more_than_5_percent
from final_db
;

