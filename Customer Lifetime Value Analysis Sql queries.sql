-Customer Lifetime Value (CLV) Analysis (SQL Portfolio Project)
--Project Goal
--calculate customer lifetime value, segment customers using RFM (Recency, Frequency, Monetary), and identify high-value vs at-risk customers.

--1. Calculate CLV per Customer

SELECT 
  c.customer_id,
  COUNT(DISTINCT o.order_id) AS total_orders,
  SUM(oi.total_price) AS total_spent,
  ROUND(SUM(oi.total_price) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id
ORDER BY total_spent DESC;

--2. RFM Segmentation

WITH rfm AS (
  SELECT 
    c.customer_id,
    MAX(o.order_date) AS last_order_date,
    COUNT(DISTINCT o.order_id) AS frequency,
    SUM(oi.total_price) AS monetary
  FROM customers c
  JOIN orders o ON c.customer_id = o.customer_id
  JOIN order_items oi ON o.order_id = oi.order_id
  GROUP BY c.customer_id
),
rfm_scores AS (
  SELECT 
    customer_id,
    DATE_PART('day', CURRENT_DATE - last_order_date) AS recency,
    frequency,
    monetary,
    NTILE(4) OVER (ORDER BY DATE_PART('day', CURRENT_DATE - last_order_date)) AS r_score,
    NTILE(4) OVER (ORDER BY frequency DESC) AS f_score,
    NTILE(4) OVER (ORDER BY monetary DESC) AS m_score
  FROM rfm
)
SELECT *,
       (r_score::TEXT || f_score::TEXT || m_score::TEXT) AS rfm_segment
FROM rfm_scores
ORDER BY rfm_segment;

--3. High-Value Customers

SELECT 
  customer_id,
  monetary,
  frequency,
  recency
FROM (
  SELECT 
    customer_id,
    DATE_PART('day', CURRENT_DATE - MAX(o.order_date)) AS recency,
    COUNT(DISTINCT o.order_id) AS frequency,
    SUM(oi.total_price) AS monetary
  FROM orders o
  JOIN order_items oi ON o.order_id = oi.order_id
  GROUP BY customer_id
) sub
WHERE monetary > 1000 AND frequency >= 5 AND recency < 60;

--4. CLV by Country

SELECT 
  c.country,
  COUNT(DISTINCT c.customer_id) AS total_customers,
  ROUND(SUM(oi.total_price), 2) AS total_revenue,
  ROUND(SUM(oi.total_price) / COUNT(DISTINCT c.customer_id), 2) AS avg_clv
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.country
ORDER BY avg_clv DESC;