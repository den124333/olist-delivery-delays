-- 04_late_vs_reviews.sql
-- Do late orders get worse review scores?
--
-- review_score is on order_reviews, so I join on order_id.
-- CASE splits each review into late vs on_time using the same rule
-- as file 01. Then I average the stars in each group.
--
-- This is not proof that lateness caused the low score. The product
-- could also have been bad. But if late orders sit near 2 stars and
-- on-time orders sit near 4, delay is at least strongly related.

SELECT
    CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 'late'
        ELSE 'on_time'
    END AS delivery,
    COUNT(*) AS reviews,
    ROUND(AVG(r.review_score)::numeric, 2) AS avg_review_score
FROM orders o
JOIN order_reviews r
  ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND r.review_score IS NOT NULL
GROUP BY 1
ORDER BY 1;
