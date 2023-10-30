SELECT 
	sp.create_date + INTERVAL '7 HOUR' AS created_on,
	sp.name AS transfer,
	sp.origin AS reference,
	CASE 
		WHEN sp.name LIKE 'AMLSG/OUT/%' THEN 'Consignment/Outright'
		WHEN sp.name LIKE 'DS%' THEN 'Dropship'	
		WHEN sp.name LIKE 'AMLSG/TS_OUT/%' THEN 'Transshipment'
		WHEN sp.name LIKE 'RT%' THEN 'Returned'
	END AS procurement,
	pt.name AS product_name,
	pp.barcode,
	SUM(sml.product_uom_qty) AS demand,
 	SUM(sml.qty_done) AS done,
 	CASE
 		 WHEN sp.state = 'cancel' THEN (sml.product_uom_qty - sml.qty_done)
 		 ELSE null 
 	END AS cancellation,
 	sp.amilo_shipment_status AS shipment_status,	
	sp.state AS status
FROM stock_move_line sml
LEFT JOIN product_product pp on sml.product_id = pp.id
LEFT JOIN product_template pt on pt.id = pp.product_tmpl_id 
LEFT JOIN stock_picking sp on sml.picking_id = sp.id
WHERE sp.name NOT LIKE '%IN%'
GROUP BY 1,2,3,4,5,6,9,10,11
ORDER BY 2
