SELECT
	rp.name AS contact,
	po.name AS Source_document,
	sp.amilo_request_id,
	TO_CHAR((sp.create_date + INTERVAL '7 HOUR'),'YYYY-MM-DD HH24:MI:SS') AS create_date,
	sp.state,
	TO_CHAR((sp.write_date + INTERVAL '7 HOUR'),'YYYY-MM-DD HH24:MI:SS') AS Last_Updated_on 
FROM stock_picking sp
INNER JOIN purchase_order po ON po.name = sp.origin
LEFT JOIN res_partner rp ON rp.id = sp.partner_id
WHERE sp.create_date > NOW() - INTERVAL '4 MONTH' AND sp.picking_type_id = 7
GROUP BY 1,2,3,4,5,6
ORDER BY 1,2,4
