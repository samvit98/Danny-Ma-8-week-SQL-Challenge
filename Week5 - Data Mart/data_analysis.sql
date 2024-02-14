-- What day of the week is used for each week_date value?
SELECT
    week_date,
    EXTRACT(DAY FROM week_date) AS day_of_week
FROM
    data_mart.clean_weekly_sales;

-- What range of week numbers are missing from the dataset?
WITH RECURSIVE week_numbers AS (
    SELECT 1 AS week_number
    UNION ALL
    SELECT week_number + 1 AS week_number
    FROM week_numbers
    WHERE week_number < 52
)
SELECT *
FROM week_numbers
WHERE week_number NOT IN (
    SELECT DISTINCT week_number FROM data_mart.clean_weekly_sales
);

-- How many total transactions were there for each year in the dataset?
SELECT
    calendar_year,
    SUM(transactions) AS total_transactions
FROM
    data_mart.clean_weekly_sales
GROUP BY
    calendar_year
ORDER BY
    total_transactions DESC;

-- What is the total sales for each region for each month?
SELECT
    region,
    month_number,
    SUM(sales) AS total_sales
FROM
    data_mart.clean_weekly_sales
GROUP BY
    region, month_number
ORDER BY
    region ASC, month_number ASC;

-- What is the total count of transactions for each platform?
SELECT
    platform,
    SUM(transactions) AS total_transactions
FROM
    data_mart.clean_weekly_sales
GROUP BY
    platform
ORDER BY
    total_transactions DESC;

-- What is the percentage of sales for Retail vs Shopify for each month?
SELECT
    calendar_year,
    month_number,
    ROUND((SUM(CASE WHEN platform = 'Shopify' THEN sales ELSE 0 END)::DECIMAL / SUM(sales)::DECIMAL)*100, 2) AS Shopify_sales_percentage,
    ROUND((SUM(CASE WHEN platform = 'Retail' THEN sales ELSE 0 END)::DECIMAL / SUM(sales)::DECIMAL)*100, 2) AS Retail_sales_percentage
FROM
    data_mart.clean_weekly_sales
GROUP BY
    calendar_year, month_number
ORDER BY
    calendar_year ASC, month_number ASC;

-- What is the percentage of sales by demographic for each year in the dataset?
WITH yearly_sales AS (
    SELECT 
        calendar_year,
        SUM(sales)::DECIMAL AS total_sales
    FROM 
        data_mart.clean_weekly_sales
    GROUP BY 
        calendar_year
)
SELECT
    d1.calendar_year,
    ROUND((SUM(CASE WHEN demographic = 'Couples' THEN sales ELSE 0 END)::DECIMAL / yearly_sales.total_sales * 100), 2) AS Couples_sales_percentage,
    ROUND((SUM(CASE WHEN demographic = 'Families' THEN sales ELSE 0 END)::DECIMAL / yearly_sales.total_sales * 100), 2) AS Families_sales_percentage,
    ROUND((SUM(CASE WHEN demographic = 'unknown' THEN sales ELSE 0 END)::DECIMAL / yearly_sales.total_sales * 100), 2) AS Unknown_sales_percentage
FROM
    data_mart.clean_weekly_sales d1
JOIN yearly_sales ON d1.calendar_year = yearly_sales.calendar_year
GROUP BY
    d1.calendar_year, yearly_sales.total_sales
ORDER BY
    d1.calendar_year ASC;


-- Which age_band and demographic values contribute the most to Retail sales?
SELECT
    age_band,
    demographic,
    SUM(CASE WHEN platform = 'Retail' THEN sales ELSE 0 END) AS retail_sales
FROM
    data_mart.clean_weekly_sales d1
WHERE
    segment != 'null'
GROUP BY
    1, 2
ORDER BY
    3 DESC;

-- Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
SELECT
    calendar_year,
    ROUND(SUM(CASE WHEN platform = 'Retail' THEN sales ELSE 0 END)::DECIMAL / SUM(CASE WHEN platform = 'Retail' THEN transactions ELSE 0 END)::DECIMAL, 2) AS retail_avg_transaction_size,
    ROUND(SUM(CASE WHEN platform = 'Shopify' THEN sales ELSE 0 END)::DECIMAL / SUM(CASE WHEN platform = 'Shopify' THEN transactions ELSE 0 END)::DECIMAL, 2) AS shopify_avg_transaction_size
FROM
    data_mart.clean_weekly_sales d1
GROUP BY
    1
ORDER BY
    1 ASC;
