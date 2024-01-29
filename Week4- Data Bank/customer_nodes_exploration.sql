-- Customer Nodes Exploration

-- How many unique nodes are there on the Data Bank system?
select
count(distinct node_id) as unique_node_cnt
from data_bank.customer_nodes;
-- What is the number of nodes per region?
select
region_id, region_name,
count(distinct node_id) as unique_node_cnt
from data_bank.customer_nodes
join data_bank.regions using(region_id)
group by region_id,region_name
order by region_id,region_name
;
-- How many customers are allocated to each region?
select
region_id, region_name,
count(distinct customer_id) as unique_cust_cnt
from data_bank.customer_nodes
join data_bank.regions using(region_id)
group by region_id,region_name
order by region_id,region_name
;
-- How many days on average are customers reallocated to a different node?
with cust_db as (
SELECT 
customer_id,node_id,
sum((end_date - start_date)::int) AS days_in_a_node
FROM data_bank.customer_nodes
WHERE end_date !='9999-12-31'
group by customer_id,node_id)

select 
round(avg(days_in_a_node),2) as avg_days
from cust_db
;

-- What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

with region_db as (
SELECT 
customer_id,region_id,node_id,
sum((end_date - start_date)::int) AS days_in_a_node
FROM data_bank.customer_nodes
WHERE end_date !='9999-12-31'
group by customer_id,region_id,node_id

)
select 
region_id,region_name,round(avg(days_in_a_node),2) as avg_days,
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY days_in_a_node) AS median,
PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY days_in_a_node) AS eighty_perc,
PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY days_in_a_node) AS ninety_fifth_perc
from region_db
inner join data_bank.regions using(region_id)
group by 1,2
order by 1
;


