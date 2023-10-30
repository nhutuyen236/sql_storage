SELECT
	po.name,
	rp.name AS vendor,
	TO_CHAR(po.date_approve + '7 HOUR','YYYY-MM-DD HH24:MI:SS') AS confirmed_date,
	CASE 
		WHEN po.picking_type_id = 7 THEN 'Dropship'
		WHEN po.picking_type_id = 9 then 'Outright'
		WHEN po.picking_type_id = 10 then 'Transshipment'
		ELSE ''
	END AS procurement_type,
	SUM(pol.product_uom_qty) AS quantity,
	SUM(pol.qty_received) AS qty_received,
	SUM(pol.product_uom_qty) - SUM(pol.qty_received) AS missing_qty,
	CASE 
		WHEN abc.count_ready = 0 THEN 'Closed' 
		ELSE 'Open' 
	END AS PO_status,
	CASE 
		WHEN cde.Cancelable = 'yes' THEN 'yes' 
		ELSE 'no' 
	END AS Cancelable,
	po.amount_untaxed AS untaxed_amount,
	po.amount_total AS total,
	sp2.amilo_ir_code
FROM purchase_order po
LEFT JOIN res_partner rp ON rp.id = po.partner_id
LEFT JOIN purchase_order_line pol ON pol.order_id = po.id 
LEFT JOIN sale_order so ON so.id = pol.sale_order_id
LEFT JOIN stock_picking sp2 ON sp2.origin = po.name
LEFT JOIN (
  				SELECT 
  					origin,
    				COUNT(CASE WHEN state in ('assigned', 'process') THEN state ELSE NULL END) AS count_ready
    		FROM stock_picking
    		WHERE origin LIKE 'P%'
    		GROUP BY 1
   ) AS abc ON abc.origin = po.name
LEFT JOIN (
					SELECT 
							res_name AS PO,
							'yes' AS Cancelable 
						FROM mail_activity
						WHERE res_model = 'purchase.order' AND note LIKE '%cancelled%'
						GROUP BY 1,2) AS cde ON cde.po = po.name
WHERE po.picking_type_id IN (7,9,10) AND po.date_approve > NOW() - INTERVAL '4 MONTH'
GROUP BY 1,2,3,4,8,9,10,11,12