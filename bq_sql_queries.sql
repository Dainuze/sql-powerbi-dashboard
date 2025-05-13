Building a dashboard in Power BI, I combine the data from the "orders table", which has information for each individual order with "order_items table", which contains a list of items for each order along with the sale price for each item into a single table. I write a simple SQL query:


SELECT
  orders.order_id,
  orders.user_id,
  orders.status,
  CAST(orders.created_at AS DATE) AS order_created_date,
  order_items.product_id,
  order_items.sale_price
FROM
  `bigquery-public-data.thelook_ecommerce.orders` AS orders
INNER JOIN
  `bigquery-public-data.thelook_ecommerce.order_items` AS order_items
ON
  orders.order_id = order_items.order_id
WHERE
  CAST(orders.created_at AS DATE) BETWEEN '2020-01-01'
  AND '2023-12-31'



Displayed below are additional SQL queries. This is a separate task from my marketing studies, which utilized the same BigQuery database thelook_ecommerce.


1. Traffic sources users come from:

SELECT
  traffic_source,
  COUNT(DISTINCT id) AS user_count
FROM
  `bigquery-public-data.thelook_ecommerce.users`
GROUP BY
  traffic_source
ORDER BY
  user_count DESC;


2. The count of users with at least one “Complete” order (instead of the total user count). The count of “Complete” orders. The average number of “Complete” orders per user (rounded to two decimal places). Results ordered by the average number of complete orders per user in descending order.

SELECT
  u.traffic_source,
  COUNT(DISTINCT u.id) AS user_count_with_complete_orders,
  COUNT(o.order_id) AS complete_order_count,
  ROUND(COUNT(o.order_id) / COUNT(DISTINCT u.id), 2) AS avg_complete_orders_per_user
FROM
  `bigquery-public-data.thelook_ecommerce.users` u
JOIN
  `bigquery-public-data.thelook_ecommerce.orders` o
ON
  u.id = o.user_id
WHERE
  o.status = 'Complete'
GROUP BY
  u.traffic_source
ORDER BY
  user_count_with_complete_orders DESC;


3. Number of orders by traffic source and order status. All orders are included. “Processing” and “Shipped” statuses combined into a single “In progress” status. Traffic sources with empty order statuses excluded. Results ordered alphabetically by traffic source and order status.

SELECT
  u.traffic_source,
  CASE
    WHEN o.status IN ('Processing', 'Shipped') THEN 'In progress'
    ELSE o.status
END
  AS order_status,
  COUNT(o.order_id) AS order_count
FROM
  `bigquery-public-data.thelook_ecommerce.users` u
JOIN
  `bigquery-public-data.thelook_ecommerce.orders` o
ON
  u.id = o.user_id
WHERE
  o.status IS NOT NULL
GROUP BY
  u.traffic_source,
  order_status
ORDER BY
  u.traffic_source,
  order_status;


4. Amount of sessions coming from each traffic source (since each session contains multiple events, I decide to use the timestamp of the first event in each session as the session start):

SELECT
  e.traffic_source,
  e.session_id,
  MIN(e.created_at) AS session_started_at
FROM
  `bigquery-public-data.thelook_ecommerce.events` e
GROUP BY
  e.traffic_source,
  e.session_id
ORDER BY
  e.traffic_source,
  session_started_at;


5. The number of sessions per month and traffic source. The results ordered by traffic source and month (the query above is included into this query):

WITH
  session_starts AS (
  SELECT
    e.traffic_source,
    e.session_id,
    MIN(e.created_at) AS session_start
  FROM
    `bigquery-public-data.thelook_ecommerce.events` e
  GROUP BY
    e.traffic_source,
    e.session_id )
SELECT
  ss.traffic_source,
  DATE_TRUNC(DATE(ss.session_start), MONTH) AS session_month,
  COUNT(DISTINCT ss.session_id) AS session_count
FROM
  session_starts ss
GROUP BY
  ss.traffic_source,
  session_month
ORDER BY
  ss.traffic_source,
  session_month;


6. Calculated the average, minimum and maximum session durations (I create new table session_durations to use a data from it for the query below. I create columns with start and end time of each session using MIN and MAX functions):

WITH
  session_durations AS (
  SELECT
    e.session_id,
    MIN(e.created_at) AS session_start,
    MAX(e.created_at) AS session_end
  FROM
    `bigquery-public-data.thelook_ecommerce.events` e
  GROUP BY
    e.session_id )
SELECT
  ROUND(AVG(TIMESTAMP_DIFF(session_end, session_start, HOUR)), 1) AS avg_session_duration_hours,
  ROUND(MIN(TIMESTAMP_DIFF(session_end, session_start, HOUR)), 1) AS min_session_duration_hours,
  ROUND(MAX(TIMESTAMP_DIFF(session_end, session_start, HOUR)), 1) AS max_session_duration_hours
FROM
  session_durations;



