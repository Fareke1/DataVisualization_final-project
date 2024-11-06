DESCRIBE transactions_info;
DESCRIBE customer_info;

WITH Monthly_Transactions AS (
    SELECT 
        ID_client AS customer_id,
        DATE_FORMAT(STR_TO_DATE(date_new, '%Y-%m-%d'), '%Y-%m') AS month,
        COUNT(*) AS transaction_count,
        AVG(Sum_payment) AS avg_transaction_amount
    FROM transactions_info
    WHERE STR_TO_DATE(date_new, '%Y-%m-%d') BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY ID_client, DATE_FORMAT(STR_TO_DATE(date_new, '%Y-%m-%d'), '%Y-%m')
),
Continuous_Customers AS (
    SELECT 
        customer_id
    FROM Monthly_Transactions
    GROUP BY customer_id
    HAVING COUNT(DISTINCT month) = 12  -- Условие для 12 месяцев без пропусков
)
SELECT 
    c.Id_client,
    AVG(t.Sum_payment) AS avg_check,
    SUM(t.Sum_payment) / 12 AS avg_monthly_amount, 
    COUNT(t.Id_check) AS total_operations
FROM Continuous_Customers c
JOIN transactions_info t ON c.customer_id = t.ID_client
WHERE STR_TO_DATE(t.date_new, '%Y-%m-%d') BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY c.Id_client;


WITH Monthly_Stats AS (
    SELECT 
        DATE_FORMAT(STR_TO_DATE(date_new, '%Y-%m-%d'), '%Y-%m') AS month,
        AVG(Sum_payment) AS avg_monthly_check,
        COUNT(Id_check) AS total_operations,
        COUNT(DISTINCT ID_client) AS active_customers,
        SUM(Sum_payment) AS monthly_total_amount
    FROM transactions_info
    WHERE STR_TO_DATE(date_new, '%Y-%m-%d') BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY DATE_FORMAT(STR_TO_DATE(date_new, '%Y-%m-%d'), '%Y-%m')
)
SELECT 
    month,
    avg_monthly_check,
    total_operations / 12 AS avg_operations_per_month,
    active_customers / 12 AS avg_customers_per_month,
    (total_operations / (SELECT COUNT(*) FROM transactions_info WHERE STR_TO_DATE(date_new, '%Y-%m-%d') BETWEEN '2015-06-01' AND '2016-06-01')) * 100 AS yearly_operations_share,
    (monthly_total_amount / (SELECT SUM(Sum_payment) FROM transactions_info WHERE STR_TO_DATE(date_new, '%Y-%m-%d') BETWEEN '2015-06-01' AND '2016-06-01')) * 100 AS yearly_amount_share
FROM Monthly_Stats;

SELECT 
    DATE_FORMAT(STR_TO_DATE(t.date_new, '%Y-%m-%d'), '%Y-%m') AS month,
    ci.Gender,
    COUNT(*) AS operations,
    SUM(t.Sum_payment) AS total_spent,
    (SUM(t.Sum_payment) / (SELECT SUM(Sum_payment) FROM transactions_info WHERE DATE_FORMAT(STR_TO_DATE(date_new, '%Y-%m-%d'), '%Y-%m') = month)) * 100 AS monthly_spent_share
FROM transactions_info t
JOIN customer_info ci ON t.ID_client = ci.Id_client
WHERE STR_TO_DATE(t.date_new, '%Y-%m-%d') BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY month, ci.Gender;


WITH Age_Groups AS (
    SELECT 
        Id_client,
        CASE 
            WHEN Age IS NULL THEN 'Unknown'
            WHEN Age BETWEEN 0 AND 9 THEN '0-9'
            WHEN Age BETWEEN 10 AND 19 THEN '10-19'
            WHEN Age BETWEEN 20 AND 29 THEN '20-29'
            WHEN Age BETWEEN 30 AND 39 THEN '30-39'
            WHEN Age BETWEEN 40 AND 49 THEN '40-49'
            WHEN Age BETWEEN 50 AND 59 THEN '50-59'
            WHEN Age BETWEEN 60 AND 69 THEN '60-69'
            ELSE '70+'
        END AS age_group
    FROM customer_info
),
Quarterly_Stats AS (
    SELECT 
        ag.age_group,
        CONCAT(YEAR(STR_TO_DATE(date_new, '%Y-%m-%d')), ' Q', QUARTER(STR_TO_DATE(date_new, '%Y-%m-%d'))) AS quarter,
        SUM(t.Sum_payment) AS total_amount,
        COUNT(t.Id_check) AS total_transactions,
        AVG(t.Sum_payment) AS avg_transaction_amount,
        (SUM(t.Sum_payment) / (SELECT SUM(Sum_payment) FROM transactions_info WHERE STR_TO_DATE(date_new, '%Y-%m-%d') BETWEEN '2015-06-01' AND '2016-06-01')) * 100 AS percentage_share
    FROM transactions_info t
    JOIN Age_Groups ag ON t.ID_client = ag.Id_client
    WHERE STR_TO_DATE(t.date_new, '%Y-%m-%d') BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY ag.age_group, quarter
)
SELECT * FROM Quarterly_Stats;

