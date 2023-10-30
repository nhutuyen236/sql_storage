SELECT cohort_month,
       order_month,
       month_delta,
       COUNT(DISTINCT order_1_count)                               AS order_1_count,
       COUNT(DISTINCT order_2_count)                               AS order_2_count,
       COUNT(order_count)                                          AS order_count,
       SUM(order_amount)                                           AS order_amount,
       PERCENTILE_CONT(0.5) WITHIN GROUP ( ORDER BY order_amount ) AS order_median
FROM (SELECT DISTINCT TO_CHAR(customer_order_n.order_1_date, 'YYYY-MM-01')  AS cohort_month,
                      TO_CHAR(sale_order.date_order, 'YYYY-MM-01')          AS order_month,
                      (EXTRACT(YEAR FROM sale_order.date_order) - EXTRACT(YEAR FROM customer_order_n.order_1_date)) * 12
                          + EXTRACT(MONTH FROM sale_order.date_order) -
                      EXTRACT(MONTH FROM customer_order_n.order_1_date) + 1 AS month_delta,
                      res_partner.phone                                     AS order_1_count,
                      CASE
                          WHEN TO_CHAR(sale_order.date_order, 'YYYY-MM-01') =
                               TO_CHAR(customer_order_n.order_2_date, 'YYYY-MM-01')
                              THEN res_partner.phone END                    AS order_2_count,
                      sale_order.id                                         AS order_count,
                      sale_order.amount_total                               AS order_amount

      FROM stock_picking
               JOIN stock_picking_type ON stock_picking.picking_type_id = stock_picking_type.id
               JOIN sale_order ON stock_picking.sale_id = sale_order.id
               JOIN res_partner ON sale_order.partner_shipping_id = res_partner.id
               JOIN
           (SELECT phone,
                   MIN(CASE WHEN rank = 1 THEN date_order END) AS order_1_date,
                   MIN(CASE WHEN rank = 2 THEN date_order END) AS order_2_date
            FROM (SELECT res_partner.phone,
                         sale_order.date_order,
                         RANK() OVER ( PARTITION by res_partner.phone ORDER BY sale_order.date_order ) rank
                  FROM stock_picking
                           JOIN stock_picking_type ON stock_picking.picking_type_id = stock_picking_type.id
                           JOIN sale_order ON stock_picking.sale_id = sale_order.id
                           JOIN res_partner ON sale_order.partner_shipping_id = res_partner.id
                  WHERE stock_picking_type.sequence_code = 'OUT'
                    AND stock_picking.sale_id IS NOT NULL
                    AND stock_picking.state = 'done'
                    AND sale_order.state != 'cancel'
                  ORDER BY 1, 2
                 ) AS order_rank
            GROUP BY 1
           ) AS customer_order_n
           ON res_partner.phone = customer_order_n.phone
      WHERE stock_picking_type.sequence_code = 'OUT'
        AND stock_picking.sale_id IS NOT NULL
        AND stock_picking.state = 'done'
        AND sale_order.state != 'cancel'
     ) AS distinct_orders
GROUP BY 1, 2, 3
ORDER BY 1, 2