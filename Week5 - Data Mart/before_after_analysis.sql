WITH ba_2020 AS (
    SELECT
        calendar_year,
        SUM(CASE WHEN week_date < '2020-06-15' AND week_date >= ('2020-06-15'::DATE - INTERVAL '4 week') THEN sales ELSE 0 END) AS before_sales_4,
        SUM(CASE WHEN week_date > '2020-06-15' AND week_date <= ('2020-06-15'::DATE + INTERVAL '4 week') THEN sales ELSE 0 END) AS after_sales_4,
        SUM(CASE WHEN week_date < '2020-06-15' AND week_date >= ('2020-06-15'::DATE - INTERVAL '12 week') THEN sales ELSE 0 END) AS before_sales_12,
        SUM(CASE WHEN week_date > '2020-06-15' AND week_date <= ('2020-06-15'::DATE + INTERVAL '12 week') THEN sales ELSE 0 END) AS after_sales_12
    FROM
        data_mart.clean_weekly_sales
    WHERE
        calendar_year = '2020'
    GROUP BY
        calendar_year
),
ba_2018 AS (
    SELECT
        calendar_year,
        SUM(CASE WHEN week_date < '2018-06-15' AND week_date >= ('2018-06-15'::DATE - INTERVAL '4 week') THEN sales ELSE 0 END) AS before_sales_4,
        SUM(CASE WHEN week_date > '2018-06-15' AND week_date <= ('2018-06-15'::DATE + INTERVAL '4 week') THEN sales ELSE 0 END) AS after_sales_4,
        SUM(CASE WHEN week_date < '2018-06-15' AND week_date >= ('2018-06-15'::DATE - INTERVAL '12 week') THEN sales ELSE 0 END) AS before_sales_12,
        SUM(CASE WHEN week_date > '2018-06-15' AND week_date <= ('2018-06-15'::DATE + INTERVAL '12 week') THEN sales ELSE 0 END) AS after_sales_12
    FROM
        data_mart.clean_weekly_sales
    WHERE
        calendar_year = '2018'
    GROUP BY
        calendar_year
),
ba_2019 AS (
    SELECT
        calendar_year,
        SUM(CASE WHEN week_date < '2019-06-15' AND week_date >= ('2019-06-15'::DATE - INTERVAL '4 week') THEN sales ELSE 0 END) AS before_sales_4,
        SUM(CASE WHEN week_date > '2019-06-15' AND week_date <= ('2019-06-15'::DATE + INTERVAL '4 week') THEN sales ELSE 0 END) AS after_sales_4,
        SUM(CASE WHEN week_date < '2019-06-15' AND week_date >= ('2019-06-15'::DATE - INTERVAL '12 week') THEN sales ELSE 0 END) AS before_sales_12,
        SUM(CASE WHEN week_date > '2019-06-15' AND week_date <= ('2019-06-15'::DATE + INTERVAL '12 week') THEN sales ELSE 0 END) AS after_sales_12
    FROM
        data_mart.clean_weekly_sales
    WHERE
        calendar_year = '2019'
    GROUP BY
        calendar_year
)

SELECT
    '2020' AS calendar_year,
    before_sales_4,
    after_sales_4,
    after_sales_4 - before_sales_4 AS change_4,
    ROUND(((after_sales_4 - before_sales_4)::DECIMAL / before_sales_4::DECIMAL) * 100, 2) AS percentage_change_4,
    before_sales_12,
    after_sales_12,
    after_sales_12 - before_sales_12 AS change_12,
    ROUND(((after_sales_12 - before_sales_12)::DECIMAL / before_sales_12::DECIMAL) * 100, 2) AS percentage_change_12
FROM
    ba_2020

UNION ALL 

SELECT
    '2018' AS calendar_year,
    before_sales_4,
    after_sales_4,
    after_sales_4 - before_sales_4 AS change_4,
    ROUND(((after_sales_4 - before_sales_4)::DECIMAL / before_sales_4::DECIMAL) * 100, 2) AS percentage_change_4,
    before_sales_12,
    after_sales_12,
    after_sales_12 - before_sales_12 AS change_12,
    ROUND(((after_sales_12 - before_sales_12)::DECIMAL / before_sales_12::DECIMAL) * 100, 2) AS percentage_change_12
FROM
    ba_2018

UNION ALL

SELECT
    '2019' AS calendar_year,
    before_sales_4,
    after_sales_4,
    after_sales_4 - before_sales_4 AS change_4,
    ROUND(((after_sales_4 - before_sales_4)::DECIMAL / before_sales_4::DECIMAL) * 100, 2) AS percentage_change_4,
    before_sales_12,
    after_sales_12,
    after_sales_12 - before_sales_12 AS change_12,
    ROUND(((after_sales_12 - before_sales_12)::DECIMAL / before_sales_12::DECIMAL) * 100, 2) AS percentage_change_12
FROM
    ba_2019;
