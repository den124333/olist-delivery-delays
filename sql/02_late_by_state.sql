-- 02_late_by_state.sql
-- Same late rule as file 01, but split by the customer's state.
--
-- The state is not on orders. It lives on customers, so I join:
--   orders.customer_id = customers.customer_id
--
-- HAVING COUNT(*) >= 100: I drop tiny states. 2 late out of 10 orders
-- looks like 20 percent but that is too noisy to rank.
--
-- I wrap the totals in a CTE so I can RANK the late rate without
-- copying the long COUNT expression a third time.

WITH late_by_state AS (
    SELECT
        c.customer_state,
        COUNT(*) AS delivered_orders,
        COUNT(*) FILTER (
            WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
        ) AS late_orders,
        ROUND(
            100.0 * COUNT(*) FILTER (
                WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
            ) / COUNT(*),
            2
        ) AS late_rate_pct
    FROM orders o
    JOIN customers c
      ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
    GROUP BY c.customer_state
    HAVING COUNT(*) >= 100
)
SELECT
    customer_state,
    delivered_orders,
    late_orders,
    late_rate_pct,
    RANK() OVER (ORDER BY late_rate_pct DESC) AS late_rank
FROM late_by_state
ORDER BY late_rate_pct DESC;
