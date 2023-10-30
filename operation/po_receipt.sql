SELECT
    rp.name AS vendor,
    sp.name AS receipt,
    sp2.name AS backorder,
    sp.amilo_request_id,
    po.name AS PO,
    TO_CHAR(sp.create_date + '7 HOUR', 'YYYY-MM-DD HH24:MI:SS') AS po_confirmed_on,
    CASE WHEN abc.count_ready = 0 THEN 'Closed' ELSE 'Open' END AS PO_status,
    CASE 
      WHEN sp.picking_type_id = 7 THEN 'Dropship'
      WHEN sp.picking_type_id = 8 THEN 'Consignment'
      WHEN sp.picking_type_id = 9 THEN 'Outright'
      WHEN sp.picking_type_id = 10 THEN 'Transshipment'
      ELSE ''
    END AS procurement_type,
    sp.state AS receipt_status,
    TO_CHAR(sp.write_date + '7 HOUR','YYYY-MM-DD HH24:MI:SS') AS Last_Updated_on_rc,
    SUM(sm.product_uom_qty) AS demand,
    SUM(sml.qty_done) AS done,
    (SUM(sm.product_uom_qty) - SUM(sml.qty_done)) AS missing_qty 
FROM stock_picking sp
LEFT JOIN purchase_order po ON sp.origin = po.name
LEFT JOIN res_partner rp ON rp.id = sp.partner_id
LEFT JOIN (
            SELECT 
              backorder_id, 
              name
            FROM stock_picking 
            WHERE picking_type_id = 8
    AND backorder_id IS NOT NULL) sp2 ON sp2.backorder_id = sp.id
LEFT JOIN stock_move sm ON sm.picking_id = sp.id
LEFT JOIN stock_move_line sml ON sml.move_id = sm.id
LEFT JOIN (
            SELECT 
              origin,
              COUNT(CASE WHEN state = 'assigned' THEN state ELSE NULL END) AS count_ready
            FROM stock_picking
            WHERE origin LIKE 'P%'
            GROUP BY 1
          ) AS abc ON abc.origin = po.name
WHERE sp.picking_type_id IN (7,8,9,10) AND sp.create_date > NOW() - INTERVAL '4 MONTH'
GROUP BY 1,2,3,4,5,6,7,8,9,10
ORDER BY 1,5,2