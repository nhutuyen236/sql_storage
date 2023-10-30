SELECT rank                                                                         AS order_tally,
       PERCENTILE_CONT(0.5) WITHIN GROUP ( ORDER BY order_rank.order_amount )       AS order_median_amount,
       ROUND(SUM(order_amount) / COUNT(DISTINCT phone), -5)                         AS order_average_amount,
       COUNT(rank)                                                                  AS order_count,
       ROUND(SUM(CASE WHEN date_diff IS NULL THEN 0 ELSE 1.0 END) / COUNT(rank), 3) AS chance_of_next_order,
       ROUND(AVG(EXTRACT(DAYS FROM date_diff::interval)::numeric(9, 2)), 3)         AS days_to_next_order
FROM (SELECT DISTINCT res_partner.phone,
                      sale_order.amount_total                                      AS     order_amount,
                      RANK() OVER (PARTITION BY res_partner.phone ORDER BY sale_order.id) rank,
                      sale_order.date_order                                        AS     order_date,
                      LEAD(sale_order.date_order)
                      OVER (PARTITION BY res_partner.phone ORDER BY sale_order.id) AS     next_order_date,
                      (LEAD(sale_order.date_order)
                       OVER (PARTITION BY res_partner.phone ORDER BY sale_order.id)) -
                      sale_order.date_order                                        AS     date_diff
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
     ) AS order_rank
WHERE rank <= 10
GROUP BY 1
ORDER BY 1