-- 01_late_orders.sql
-- Question I am answering: of the orders I can actually judge, how often
-- did the package arrive after the date Olist promised?
--
-- I first tried listing every late row (customer_id + the two dates).
-- That works, but GitHub needs a number, not 7,000 lines. So I switched
-- to COUNT.
--
-- Late = customer got it AFTER order_estimated_delivery_date.
-- I only keep delivered orders with a real arrival timestamp. Cancelled
-- or missing dates cannot be late or on time.

SELECT
    COUNT(*) AS delivered_orders,

    -- FILTER keeps the on-time rows in the total, but only counts a row
    -- here when it is late. AND in WHERE would throw those rows away.
    COUNT(*) FILTER (
        WHERE order_delivered_customer_date > order_estimated_delivery_date
    ) AS late_orders,

    -- 100.0 so PostgreSQL does decimal division, not integer division.
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_delivered_customer_date > order_estimated_delivery_date
        ) / COUNT(*),
        2
    ) AS late_rate_pct
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;
