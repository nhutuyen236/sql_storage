SELECT
    rp.name AS vendor,
    sp.name AS receipt,
    TO_CHAR(sp.create_date + INTERVAL '7 HOUR','YYYY-MM-DD') AS create_date,
    'Consignment' AS procurement_type,
    sp.state AS receipt_status,
    TO_CHAR(sp.write_date + INTERVAL '7 HOUR','YYYY-MM-DD') AS last_updated_on_rc,
    SUM(sm.product_uom_qty) AS demand,
	SUM(sml.qty_done) AS done,
    (SUM(sm.product_uom_qty) - SUM(sml.qty_done)) AS missing_qty
FROM stock_picking sp
LEFT JOIN res_partner rp ON rp.id = sp.partner_id
LEFT JOIN stock_move sm ON sm.picking_id = sp.id
LEFT JOIN stock_move_line sml ON sml.move_id = sm.id
WHERE sp.picking_type_id = 8
GROUP BY 1,2,3,4,5,6
ORDER BY 1