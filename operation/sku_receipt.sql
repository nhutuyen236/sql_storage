SELECT 
	rp.name AS vendor,
	sp.name AS PO,
	sp2.name AS back_order,
    pt.name AS product_name,
    pp.barcode,
	sm.product_uom_qty AS quantity,
	sml.qty_done AS qty_received
FROM stock_picking sp
LEFT JOIN stock_move sm ON sm.picking_id = sp.id
LEFT JOIN stock_move_line sml ON sml.move_id = sm.id
LEFT JOIN product_product pp ON sm.product_id = pp.id
LEFT JOIN product_template pt ON pt.id = pp.product_tmpl_id
LEFT JOIN res_partner rp ON rp.id = sp.partner_id
LEFT JOIN (SELECT 
	backorder_id, 
	name
	FROM stock_picking 
	WHERE picking_type_id = 8
	AND backorder_id IS NOT NULL) sp2 ON sp2.backorder_id = sp.id
WHERE sm.picking_type_id = 8
GROUP BY 1,2,3,4,5,6,7