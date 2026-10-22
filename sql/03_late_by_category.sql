-- 03_late_by_category.sql
-- Same late rule, now by product category.
--
-- Category is not on orders either. Path I use:
--   orders -> order_items  (one order can have several products)
--   order_items -> products
--   products -> category_translation  (Portuguese name -> English)
--
-- LEFT JOIN on translation because some products have no English name.
-- COALESCE then falls back to the Portuguese name, then 'unknown'.
--
-- Important limitation: I count ITEMS, not unique orders. If one late
-- order has a phone and a case, it shows up in two categories. That is
-- still the right grain for "which products arrive late".
--
-- HAVING COUNT(*) >= 200 so tiny categories do not jump to the top.

WITH late_by_category AS (
    SELECT
        COALESCE(
            t.product_category_name_english,
            p.product_category_name,
            'unknown'
        ) AS category,
        COUNT(*) AS delivered_items,
        COUNT(*) FILTER (
            WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
        ) AS late_items,
        ROUND(
            100.0 * COUNT(*) FILTER (
                WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
            ) / COUNT(*),
            2
        ) AS late_rate_pct
    FROM orders o
    JOIN order_items i
      ON o.order_id = i.order_id
    JOIN products p
      ON i.product_id = p.product_id
    LEFT JOIN category_translation t
      ON p.product_category_name = t.product_category_name
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
    GROUP BY 1
    HAVING COUNT(*) >= 200
)
SELECT
    category,
    delivered_items,
    late_items,
    late_rate_pct,
    RANK() OVER (ORDER BY late_rate_pct DESC) AS late_rank
FROM late_by_category
ORDER BY late_rate_pct DESC;
