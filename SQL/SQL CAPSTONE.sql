-- Overall delivery performance

-- Calculate delivered, on-time and late orders, percentages and average delay.


select * from olist.dim_customer
select * from olist.dim_product 
select * from olist.dim_date
select * from olist.dim_seller
select * from olist.fact_order_items
select * from olist.fact_orders
select * from olist.fact_payments
select * from olist.fact_reviews
-- on time delivery status
select count(*) as delivered_orders
from olist.fact_orders
where order_status='delivered' and
order_delivered_customer_date is not null and
order_estimated_delivery_date is not null and
order_delivered_customer_date :: date <=  order_estimated_delivery_date 

-- late delivery orders
select count(*) as delivered_orders
from olist.fact_orders
where order_status='delivered' and
order_delivered_customer_date is not null and
order_estimated_delivery_date is not null and
order_delivered_customer_date :: date >=  order_estimated_delivery_date


WITH TEMP1 AS
(SELECT COUNT(*) AS TOTAL_COUNT,
    COUNT(CASE WHEN ORDER_DELIVERED_CUSTOMER_DATE::DATE <= ORDER_ESTIMATED_DELIVERY_DATE THEN 1 END) AS DELIVERED_ON_ESTIMATED,
    COUNT(CASE WHEN ORDER_DELIVERED_CUSTOMER_DATE::DATE >= ORDER_ESTIMATED_DELIVERY_DATE THEN 1 END) AS DELIVERED_AFTER_ESTIMATED
FROM 
    OLIST.FACT_ORDERS 
WHERE 
    ORDER_STATUS = 'delivered' 
    AND ORDER_DELIVERED_CUSTOMER_DATE IS NOT NULL 
    AND ORDER_ESTIMATED_DELIVERY_DATE IS NOT NULL
)
SELECT ROUND(100*DELIVERED_ON_ESTIMATED/NULLIF(TOTAL_COUNT,0),2) AS DELIVERY_ONTIME_PERCENT,
		ROUND(100*DELIVERED_AFTER_ESTIMATED/NULLIF(TOTAL_COUNT,0),2) AS DELIVERY_AFTER_PERCENT
FROM TEMP1

-- Calculate average delivery delay

SELECT 
AVG(ORDER_DELIVERED_CUSTOMER_DATE::DATE
            - ORDER_ESTIMATED_DELIVERY_DATE)
FROM OLIST.FACT_ORDERS
WHERE ORDER_STATUS = 'delivered'
AND ORDER_DELIVERED_CUSTOMER_DATE IS NOT NULL
AND ORDER_ESTIMATED_DELIVERY_DATE IS NOT NULL
AND ORDER_DELIVERED_CUSTOMER_DATE::DATE
    > ORDER_ESTIMATED_DELIVERY_DATE




WITH DELIVERY_STATUS AS
(SELECT ORDER_ID,
CASE
 	WHEN  ORDER_DELIVERED_CUSTOMER_DATE IS NULL OR 
	 	  ORDER_ESTIMATED_DELIVERY_DATE IS NULL  THEN 'UNKNOWN'
	WHEN 
		ORDER_DELIVERED_CUSTOMER_DATE::DATE <=
		ORDER_ESTIMATED_DELIVERY_DATE THEN 'ON_TIME'
	ELSE  
	  'LATE'
	 END AS DELIVERY_STATUS,
CASE 
	WHEN 
		ORDER_DELIVERED_CUSTOMER_DATE::DATE >
		ORDER_ESTIMATED_DELIVERY_DATE  
		THEN 
		
		 ORDER_DELIVERED_CUSTOMER_DATE::DATE-ORDER_ESTIMATED_DELIVERY_DATE::DATE
	ELSE NULL
	END AS DELAY_DAYS
FROM OLIST.FACT_ORDERS
WHERE ORDER_STATUS='delivered'
)

SELECT COUNT(*) AS TOTAL_DELIVERED_ORDERS,
		COUNT(*) FILTER (
        WHERE delivery_status = 'ON_TIME') AS ON_TIME_DELIVERY,
		COUNT(*) FILTER(
		WHERE DELIVERY_STATUS='LATE') AS LATE_ORDERS ,
		COUNT(*) FILTER (
        WHERE delivery_status = 'UNKNOWN') AS UNKNOWN_ORDERS ,
		ROUND(
        100.0 * COUNT(*) FILTER (WHERE delivery_status = 'ON_TIME')/
      			NULLIF(COUNT(*) FILTER (WHERE delivery_status IN ('ON_TIME', 'LATE')),0),2) AS ON_TIME_PERCENTAGE,
     ROUND(
        100.0 * COUNT(*) FILTER (WHERE delivery_status = 'LATE')/
        
        NULLIF(COUNT(*) FILTER (WHERE delivery_status IN ('ON_TIME', 'LATE')),0),2) AS LATE_PERCENTAGE,
		ROUND(AVG(DELAY_DAYS)::NUMERIC, 2) AS AVG_DELAY_DAYS 
FROM  DELIVERY_STATUS
	
.........................
-- Delivery delay distribution
-- Business question: How severe are Olist's delivery delay

WITH DELAY_ANALYSIS AS(
SELECT ORDER_ID, ORDER_DELIVERED_CUSTOMER_DATE::DATE
        - ORDER_ESTIMATED_DELIVERY_DATE::DATE AS DELAY_DAYS
FROM OLIST.FACT_ORDERS
WHERE ORDER_STATUS = 'delivered'
      AND ORDER_DELIVERED_CUSTOMER_DATE IS NOT NULL
      AND ORDER_ESTIMATED_DELIVERY_DATE IS NOT NULL
      AND ORDER_DELIVERED_CUSTOMER_DATE::DATE
          > ORDER_ESTIMATED_DELIVERY_DATE::DATE
),
DELAY_CATEGORIES AS(
SELECT ORDER_ID,DELAY_DAYS,
	CASE 
		WHEN DELAY_DAYS BETWEEN 1 AND 3  THEN '1-3 DAYS(MINOR)'
		WHEN DELAY_DAYS BETWEEN 4 AND 7  THEN '4-7 DAYS(MODERATE)'
		WHEN DELAY_DAYS BETWEEN 8 AND 14  THEN '8-14 DAYS(HIGH)'
		WHEN DELAY_DAYS BETWEEN 15 AND 30  THEN '15-30 DAYS(SEVERE)'
		ELSE  'ABOVE 30 DAYS (VERY_SEVERE)' 
		END AS DELAY_CATEGORY,
	 CASE
        WHEN DELAY_DAYS BETWEEN 1 AND 3 THEN 1
        WHEN DELAY_DAYS BETWEEN 4 AND 7 THEN 2
        WHEN DELAY_DAYS BETWEEN 8 AND 14 THEN 3
        WHEN DELAY_DAYS BETWEEN 15 AND 30 THEN 4
            ELSE 5
        END AS CATEGORY_ORDER
	FROM DELAY_ANALYSIS
),
CATEGORY_SUMMARY AS (
    SELECT
        DELAY_CATEGORY,CATEGORY_ORDER,COUNT(*) AS TOTAL_ORDERS
FROM DELAY_CATEGORIES
GROUP BY DELAY_CATEGORY, CATEGORY_ORDER
)
SELECT
    DELAY_CATEGORY,TOTAL_ORDERS,
ROUND(100.0 * TOTAL_ORDERS/ SUM(TOTAL_ORDERS) OVER (),2) AS DELAY_PERCENTAGE
  FROM CATEGORY_SUMMARY
ORDER BY CATEGORY_ORDER

..................................
-- Analysis 3 — Monthly delivery performance
-- Business question: Is delivery performance improving or worsening over time?


WITH MONTHLY_DELIVERY AS (
    SELECT
        ORDER_ID,DATE_TRUNC( 'month',ORDER_PURCHASE_TIMESTAMP )::DATE AS ORDER_MONTH,
     CASE
            WHEN ORDER_DELIVERED_CUSTOMER_DATE IS NULL
                 OR ORDER_ESTIMATED_DELIVERY_DATE IS NULL    THEN 'UNKNOWN'
          
			WHEN ORDER_DELIVERED_CUSTOMER_DATE::DATE
                 <= ORDER_ESTIMATED_DELIVERY_DATE::DATE   THEN 'ON_TIME'
            ELSE 'LATE'
        END AS DELIVERY_STATUS,

     CASE
            WHEN ORDER_DELIVERED_CUSTOMER_DATE::DATE
                 > ORDER_ESTIMATED_DELIVERY_DATE::DATE
            THEN ORDER_DELIVERED_CUSTOMER_DATE::DATE
                 - ORDER_ESTIMATED_DELIVERY_DATE::DATE
            ELSE NULL
        END AS DELAY_DAYS
FROM OLIST.FACT_ORDERS
WHERE ORDER_STATUS = 'delivered'
)
SELECT ORDER_MONTH,COUNT(*) AS TOTAL_DELIVERED_ORDERS,
COUNT(*) FILTER (WHERE DELIVERY_STATUS = 'ON_TIME') AS ON_TIME_ORDERS,
COUNT(*) FILTER (WHERE DELIVERY_STATUS = 'LATE') AS LATE_ORDERS,
COUNT(*) FILTER (WHERE DELIVERY_STATUS = 'UNKNOWN' ) AS UNKNOWN_ORDERS,
ROUND(100.0 * COUNT(*) FILTER ( WHERE DELIVERY_STATUS = 'ON_TIME' )
           / 
            COUNT(*) )AS ON_TIME_PERCENTAGE,
ROUND(100.0 * COUNT(*) FILTER (WHERE DELIVERY_STATUS = 'LATE')
			/
            COUNT(*) )AS LATE_PERCENTAGE,
 ROUND(AVG(DELAY_DAYS), 2) AS AVERAGE_DELAY_DAYS
FROM MONTHLY_DELIVERY
GROUP BY ORDER_MONTH
ORDER BY ORDER_MONTH

-- Analysis 4 — Customer satisfaction: On-time vs late delivery
-- One of our most important analyses
-- Business question: Do late deliveries result in lower customer review scores?

-- We will connect fact_orders and fact_reviews using order_id.

WITH TEMP1 AS (
    SELECT O.ORDER_ID,
        CASE
            WHEN O.ORDER_DELIVERED_CUSTOMER_DATE::DATE
                 <= O.ORDER_ESTIMATED_DELIVERY_DATE::DATE
            THEN 'ON TIME'
            ELSE 'LATE'
        END AS DELIVERY_STATUS,
        R.REVIEW_SCORE
    FROM OLIST.FACT_ORDERS O
    INNER JOIN OLIST.FACT_REVIEWS R
        ON O.ORDER_ID = R.ORDER_ID
    WHERE O.ORDER_STATUS = 'delivered'
      AND O.ORDER_DELIVERED_CUSTOMER_DATE IS NOT NULL
      AND O.ORDER_ESTIMATED_DELIVERY_DATE IS NOT NULL
      AND R.REVIEW_SCORE IS NOT NULL
)
SELECT
    DELIVERY_STATUS,
    COUNT(*) AS TOTAL_REVIEWS,
    ROUND(AVG(REVIEW_SCORE), 2) AS AVERAGE_REVIEW_SCORE,
    COUNT(*) FILTER (WHERE REVIEW_SCORE <= 2  ) AS NEGATIVE_REVIEWS,
     ROUND(COUNT(*) FILTER (WHERE REVIEW_SCORE <= 2 ) * 100.0 / COUNT(*), 2 ) AS NEGATIVE_REVIEW_PERCENTAGE,
     COUNT(*) FILTER (WHERE REVIEW_SCORE >= 4 ) AS POSITIVE_REVIEWS,
     ROUND( COUNT(*) FILTER ( WHERE REVIEW_SCORE >= 4) * 100.0 / COUNT(*), 2) AS POSITIVE_REVIEW_PERCENTAGE
FROM TEMP1
GROUP BY DELIVERY_STATUS      
ORDER BY DELIVERY_STATUS

-- Overall review score distribution
-- Business question: What is the overall customer satisfaction level?

-- We calculate the number and percentage of reviews for each score from 1 to 5.

SELECT
    REVIEW_SCORE,COUNT(*) AS TOTAL_REVIEWS,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2 ) AS REVIEW_PERCENTAGE
FROM OLIST.FACT_REVIEWS
WHERE REVIEW_SCORE BETWEEN 1 AND 5
GROUP BY REVIEW_SCORE
ORDER BY REVIEW_SCORE

-- State-wise delivery performance
-- Business question: Which Brazilian states experience the most delivery problems?

SELECT
    CUSTOMER_STATE AS STATE,
    COUNT(*) AS TOTAL_DELIVERED_ORDERS,
    COUNT(*) FILTER (WHERE ORDER_DELIVERED_CUSTOMER_DATE::DATE > ORDER_ESTIMATED_DELIVERY_DATE::DATE)
     AS LATE_ORDERS,    
     ROUND( COUNT(*) FILTER ( WHERE ORDER_DELIVERED_CUSTOMER_DATE::DATE > ORDER_ESTIMATED_DELIVERY_DATE::DATE)
   	* 100.0 / COUNT(*), 2  ) AS LATE_PERCENTAGE,
    ROUND(AVG( ORDER_DELIVERED_CUSTOMER_DATE::DATE - ORDER_ESTIMATED_DELIVERY_DATE::DATE) 
	FILTER ( WHERE ORDER_DELIVERED_CUSTOMER_DATE::DATE > ORDER_ESTIMATED_DELIVERY_DATE::DATE  ), 2)
    AS AVERAGE_DELAY_DAYS
FROM OLIST.FACT_ORDERS
WHERE ORDER_STATUS = 'delivered'
  AND ORDER_DELIVERED_CUSTOMER_DATE IS NOT NULL
  AND ORDER_ESTIMATED_DELIVERY_DATE IS NOT NULL
GROUP BY CUSTOMER_STATE
ORDER BY LATE_PERCENTAGE DESC

-- Seller-wise delivery performance
-- Business question: Are certain sellers associated with more delivery delays?

WITH SELLER_DELIVERY AS (
    SELECT
        OI.SELLER_ID,OI.ORDER_ID,
        O.ORDER_DELIVERED_CUSTOMER_DATE::DATE AS ACTUAL_DATE,
        O.ORDER_ESTIMATED_DELIVERY_DATE::DATE AS ESTIMATED_DATE
    FROM OLIST.FACT_ORDER_ITEMS OI
    INNER JOIN OLIST.FACT_ORDERS O
        ON OI.ORDER_ID = O.ORDER_ID
    WHERE O.ORDER_STATUS = 'delivered'
      AND O.ORDER_DELIVERED_CUSTOMER_DATE IS NOT NULL
      AND O.ORDER_ESTIMATED_DELIVERY_DATE IS NOT NULL
)
SELECT
    SD.SELLER_ID,DS.SELLER_STATE,
    COUNT(*) AS TOTAL_ORDER_ITEMS,
    COUNT(*) FILTER (WHERE SD.ACTUAL_DATE > SD.ESTIMATED_DATE ) AS LATE_ORDER_ITEMS,
    ROUND(COUNT(*) FILTER (  WHERE SD.ACTUAL_DATE > SD.ESTIMATED_DATE  ) * 100.0 / COUNT(*), 2) AS LATE_PERCENTAGE,
    ROUND(
        AVG(SD.ACTUAL_DATE - SD.ESTIMATED_DATE) FILTER (
            WHERE SD.ACTUAL_DATE > SD.ESTIMATED_DATE
        ), 2
    ) AS AVERAGE_DELAY_DAYS
FROM SELLER_DELIVERY SD
LEFT JOIN OLIST.DIM_SELLER DS
 ON SD.SELLER_ID = DS.SELLER_ID
GROUP BY SD.SELLER_ID, DS.SELLER_STATE
HAVING COUNT(*) >= 20
ORDER BY LATE_PERCENTAGE DESC



-- Analysis 8 — Product category delivery performance
-- Business question: Are certain product categories associated with more delivery delays?

WITH TEMP1 AS
(SELECT P.PRODUCT_ID,P.PRODUCT_CATEGORY_NAME_ENGLISH,O.ORDER_ID ,
ORDER_DELIVERED_CUSTOMER_DATE::DATE AS ACTUAL_DATE,ORDER_ESTIMATED_DELIVERY_DATE::DATE AS ESTIMATED_DATE,
CASE 
		WHEN ORDER_DELIVERED_CUSTOMER_DATE::DATE<=ORDER_ESTIMATED_DELIVERY_DATE::DATE  THEN 'ON_TIME'
		ELSE 'LATE'
		END AS DELIVERY_DAYS ,
	CASE 
		WHEN ORDER_DELIVERED_CUSTOMER_DATE::DATE > ORDER_ESTIMATED_DELIVERY_DATE::DATE  THEN
		ORDER_DELIVERED_CUSTOMER_DATE::DATE-ORDER_ESTIMATED_DELIVERY_DATE::DATE  
		ELSE 0
		END AS DELAY_DAYS
FROM OLIST.DIM_PRODUCT P JOIN OLIST.FACT_ORDER_ITEMS I
ON I.PRODUCT_ID= P.PRODUCT_ID
JOIN  OLIST.FACT_ORDERS O
ON O.ORDER_ID=I.ORDER_ID
WHERE ORDER_STATUS='delivered' AND ORDER_DELIVERED_CUSTOMER_DATE IS NOT NULL AND
ORDER_ESTIMATED_DELIVERY_DATE IS NOT NULL
)
SELECT PRODUCT_CATEGORY_NAME_ENGLISH,COUNT(*) AS TOTAL_DELIVERED_ORDERS,
COUNT(*) FILTER (WHERE  DELIVERY_DAYS = 'LATE') AS LATE_ORDERS,
ROUND(100.0 * COUNT(*) FILTER (WHERE  DELIVERY_DAYS = 'LATE')/COUNT(*) )AS LATE_PERCENTAGE,
ROUND(AVG(DELAY_DAYS),2) AS AVG_DELAY_DAYS
FROM TEMP1
GROUP BY PRODUCT_CATEGORY_NAME_ENGLISH
HAVING COUNT(*) >= 50
ORDER BY LATE_PERCENTAGE DESC

-- Analysis 9 — Actual delivery time analysis
-- Business question: How long does Olist actually take to deliver an order after purchase?
-- Here we measure delivery duration, not lateness.
-- What we calculate:
-- - Average delivery duration.
-- - Median delivery duration.
-- - Minimum delivery duration.
-- - Maximum delivery duration.
-- - 90th percentile delivery duration.
WITH TEMP1 AS (
SELECT ORDER_ID, ORDER_PURCHASE_TIMESTAMP::DATE AS PURCHASE_DATE,
ORDER_DELIVERED_CUSTOMER_DATE::DATE AS ACTUAL_DATE,
ORDER_DELIVERED_CUSTOMER_DATE::DATE-ORDER_PURCHASE_TIMESTAMP::DATE AS DELIVERY_DAYS
FROM OLIST.FACT_ORDERS
WHERE ORDER_STATUS='delivered' AND ORDER_DELIVERED_CUSTOMER_DATE::DATE IS NOT NULL AND
ORDER_PURCHASE_TIMESTAMP::DATE IS NOT NULL
)
SELECT COUNT(*) AS TOTAL_ORDER_DELIEVRED,
ROUND(AVG(DELIVERY_DAYS),2) AS AVG_DELIVERY_DUARATION,
MIN(DELIVERY_DAYS) AS MINI_DELIVERY_DUARTION,
MAX(DELIVERY_DAYS) AS MAX_DELIEVRY_DURATION,
PERCENTILE_CONT(0.9) WITHIN GROUP(ORDER BY DELIVERY_DAYS) AS PCT_90_DELIVERY_DAYS,
PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY DELIVERY_DAYS) AS MEDIAN_DELIVERY_DAYS
FROM TEMP1

-- Analysis 10 — Delivery delays and business impact
-- Business question: How large is the difference in customer satisfaction between late and on-time deliveries, 
-- and how much delivery-related negative feedback does Olist receive?

WITH ORDER_DELIVERY_STATUS AS( 
SELECT ORDER_ID,
	CASE
		WHEN ORDER_DELIVERED_CUSTOMER_DATE::DATE <= ORDER_ESTIMATED_DELIVERY_DATE::DATE THEN 'ON-TIME'
		ELSE 'LATE'
		END AS DELIVERY_STATUS
FROM OLIST.FACT_ORDERS
WHERE ORDER_STATUS = 'delivered'AND ORDER_DELIVERED_CUSTOMER_DATE IS NOT NULL
AND ORDER_ESTIMATED_DELIVERY_DATE IS NOT NULL
),
REVIEW_ANALYSIS AS(
SELECT OD.DELIVERY_STATUS,R.ORDER_ID,R.REVIEW_SCORE
FROM ORDER_DELIVERY_STATUS OD INNER JOIN OLIST.FACT_REVIEWS R
ON OD.ORDER_ID = R.ORDER_ID
WHERE R.REVIEW_SCORE IS NOT NULL
)
SELECT DELIVERY_STATUS,COUNT(*) AS TOTAL_REVIEWS, ROUND(AVG(REVIEW_SCORE), 2) AS AVERAGE_SCORE,
COUNT(*) FILTER (WHERE REVIEW_SCORE <= 2) AS NEGATIVE_REVIEWS,
ROUND(COUNT(*) FILTER (WHERE REVIEW_SCORE <= 2) * 100.0 / COUNT(*), 2) AS NEGATIVE_REVIEW_PERCENTAGE
FROM REVIEW_ANALYSIS
GROUP BY DELIVERY_STATUS
ORDER BY DELIVERY_STATUS



select * from olist.dim_customer; -- customer_unique_id
select * from olist.dim_date; -- date , year , month_number, month_name , quarter , day , day_of_Wwee, day_of_week_number
select * from olist.dim_product; --product_id,product_category_name , product_category_name_english , product_name_length , 
									-- product_description_length , product_photos_qty , product_weight_g , product_length_cm , product_height_cm, product_widht_cm
select * from olist.dim_seller; --seller_id , seller_zip_code_prefix , seller_city , seller_state
select * from olist.fact_order_items; -- order_id , order_item_id , product_id , seller_id , shipping_limit_date , price, freight_value , customer_unique_id , ite_count
select * from olist.fact_orders; -- I. , customer_id , order_status , order_purchase_timestamp , order_approved_at,
								--order_delivered_carrier_date , order_delivered_customer_date , order_estimated_delivery_date , 
								-- customer_unique_id , customer_zip_code_prefix , customer_city , customer_state , order_count
select * from olist.fact_payments; -- order_id , payment_sequential, payment_type , payment_installments, payment_value , customer_unique_id
select * from olist.fact_reviews; -- review_id , order_id , review_score , review_comment_title , review_comment_message



