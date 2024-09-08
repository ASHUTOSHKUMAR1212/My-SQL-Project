USE NEW_WHEELS;

##[Q1] What is the distribution of customers across states?

SELECT state, COUNT(*) AS customer_count
FROM customer_T
GROUP BY state;


##[Q2] What is the average rating in each quarter?

WITH RatingMapping AS (
    SELECT
        CUSTOMER_FEEDBACK,
        CASE CUSTOMER_FEEDBACK
            WHEN 'Very Bad' THEN 1
            WHEN 'Bad' THEN 2
            WHEN 'Okay' THEN 3
            WHEN 'Good' THEN 4
            WHEN 'Very Good' THEN 5
        END AS numeric_rating
    FROM
        new_wheels.order_t
)
SELECT 
    YEAR(ORDER_DATE) AS year,
    QUARTER(ORDER_DATE) AS quarter,
    AVG(numeric_rating) AS average_rating
FROM 
    new_wheels.order_t
JOIN
    RatingMapping ON new_wheels.order_t.CUSTOMER_FEEDBACK = RatingMapping.CUSTOMER_FEEDBACK
GROUP BY 
    year, quarter;


## [Q3] Are customers getting more dissatisfied over time?

WITH FeedbackCounts AS (
    SELECT 
        YEAR(order_date) AS year,
        QUARTER(order_date) AS quarter,
        SUM(CASE WHEN CUSTOMER_FEEDBACK = 'Very Bad' THEN 1 ELSE 0 END) AS very_bad_count,
        SUM(CASE WHEN CUSTOMER_FEEDBACK = 'Bad' THEN 1 ELSE 0 END) AS bad_count,
        SUM(CASE WHEN CUSTOMER_FEEDBACK = 'Okay' THEN 1 ELSE 0 END) AS okay_count,
        SUM(CASE WHEN CUSTOMER_FEEDBACK = 'Good' THEN 1 ELSE 0 END) AS good_count,
        SUM(CASE WHEN CUSTOMER_FEEDBACK = 'Very Good' THEN 1 ELSE 0 END) AS very_good_count,
        COUNT(*) AS total_feedback_count
    FROM 
        new_wheels.order_t
    GROUP BY 
        year, quarter
)
SELECT 
    year,
    quarter,
    (very_bad_count / total_feedback_count) * 100 AS percentage_very_bad,
    (bad_count / total_feedback_count) * 100 AS percentage_bad,
    (okay_count / total_feedback_count) * 100 AS percentage_okay,
    (good_count / total_feedback_count) * 100 AS percentage_good,
    (very_good_count / total_feedback_count) * 100 AS percentage_very_good
FROM 
    FeedbackCounts;
    
    
## [Q4] Which are the top 5 vehicle makers preferred by the customer.

SELECT 
    vehicle_maker,
    COUNT(*) AS customer_count
FROM 
    new_wheels.product_t
GROUP BY 
    vehicle_maker
ORDER BY 
    customer_count DESC
LIMIT 5;



## [Q5] What is the most preferred vehicle make in each state?

WITH RankedMakes AS (
    SELECT
        c.STATE,
        p.VEHICLE_MAKER,
        COUNT(*) AS customer_count,
        RANK() OVER (PARTITION BY c.STATE ORDER BY COUNT(*) DESC) AS rnk
    FROM
        CUSTOMER_T c
    JOIN
        ORDER_T o ON c.CUSTOMER_ID = o.CUSTOMER_ID
    JOIN
        PRODUCT_T p ON o.PRODUCT_ID = p.PRODUCT_ID
    GROUP BY
        c.STATE, p.VEHICLE_MAKER
)
SELECT
    STATE,
    VEHICLE_MAKER
FROM
    RankedMakes
WHERE
    rnk = 1;


##  [Q6] What is the trend of number of orders by quarters?

SELECT 
    YEAR(order_date) AS year,
    QUARTER(order_date) AS quarter,
    COUNT(*) AS order_count
FROM 
    new_wheels.order_t
GROUP BY 
    year, quarter
ORDER BY 
    year, quarter;
    


## [Q7] What is the quarter over quarter % change in revenue? 

WITH RevenueByQuarter AS (
    SELECT 
        YEAR(ORDER_DATE) AS year,
        QUARTER(ORDER_DATE) AS quarter,
        SUM(QUANTITY * VEHICLE_PRICE * (1 - DISCOUNT / 100)) AS total_revenue
    FROM 
        order_t
    GROUP BY 
        year, quarter
)
SELECT 
    year,
    quarter,
    total_revenue,
    (total_revenue - LAG(total_revenue, 1) OVER (ORDER BY year, quarter)) / LAG(total_revenue, 1) OVER (ORDER BY year, quarter) * 100 AS qoq_percentage_change
FROM 
    RevenueByQuarter;
    

## [Q8] What is the trend of revenue and orders by quarters?

 WITH RevenueByQuarter AS (
    SELECT 
        YEAR(ORDER_DATE) AS year,
        QUARTER(ORDER_DATE) AS quarter,
        SUM(QUANTITY * VEHICLE_PRICE * (1 - DISCOUNT / 100)) AS total_revenue
    FROM 
        order_t
    GROUP BY 
        year, quarter
),
OrdersByQuarter AS (
    SELECT 
        YEAR(ORDER_DATE) AS year,
        QUARTER(ORDER_DATE) AS quarter,
        COUNT(*) AS total_orders
    FROM 
        order_t
    GROUP BY 
        year, quarter
)
SELECT 
    R.year,
    R.quarter,
    R.total_revenue,
    O.total_orders
FROM 
    RevenueByQuarter R
JOIN 
    OrdersByQuarter O ON R.year = O.year AND R.quarter = O.quarter
ORDER BY 
    R.year, R.quarter;
 

## [Q9] What is the average discount offered for different types of credit cards?

SELECT 
    c.CREDIT_CARD_TYPE,
    AVG(o.DISCOUNT) AS average_discount
FROM 
    order_t o
JOIN 
    customer_t c ON o.CUSTOMER_ID = c.CUSTOMER_ID
GROUP BY 
    c.CREDIT_CARD_TYPE;
    
    
    
## [Q10] What is the average time taken to ship the placed orders for each quarters?   

SELECT 
    YEAR(ORDER_DATE) AS year,
    QUARTER(ORDER_DATE) AS quarter,
    AVG(DATEDIFF(SHIP_DATE, ORDER_DATE)) AS average_ship_time
FROM 
    order_t
WHERE 
    SHIP_DATE IS NOT NULL
GROUP BY 
    year, quarter
ORDER BY 
    year, quarter;
