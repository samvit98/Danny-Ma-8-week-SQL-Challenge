DROP TABLE IF EXISTS data_mart.clean_weekly_sales;
CREATE TABLE data_mart.clean_weekly_sales AS
(
SELECT 
  region,platform,
to_date(week_date, 'DD/MM/YY') as week_date,
extract(week from to_date(week_date, 'DD/MM/YY')) as week_number,
to_char(to_date(week_date, 'DD/MM/YY'),'Day') as day_of_week,
extract(month from to_date(week_date, 'DD/MM/YY')) as month_number,
extract(year from to_date(week_date, 'DD/MM/YY')) as calendar_year,
segment,
case when segment = 'null' then 'unknown'
when right(segment,1)='1' then 'Young Adults'
when right(segment,1)='2' then 'Middle Aged' 
when right(segment,1)='3' or right(segment,1)='4' then 'Retirees'
end as age_band,
case when segment = 'null' then 'unknown'
when left(segment,1)='C' then 'Couples'
when left(segment,1)='F' then 'Families' end as demographic,transactions,sales,
round(sales :: decimal / transactions :: decimal,2) as avg_transaction
FROM data_mart.weekly_sales
);