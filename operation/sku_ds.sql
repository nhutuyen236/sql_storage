SELECT
	rp.name AS vendor,
    po.name AS PO,
    pol.name AS product_name,
    pp.barcode,
	pol.product_uom_qty AS quantity,
	pol.qty_received AS qty_received
FROM purchase_order_line pol
LEFT JOIN purchase_order po ON pol.order_id = po.id
LEFT JOIN product_product pp ON pol.product_id = pp.id
LEFT JOIN res_partner rp ON rp.id = pol.partner_id
WHERE po.picking_type_id = 7
GROUP BY 1,2,3,4,5,6