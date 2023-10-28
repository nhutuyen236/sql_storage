SELECT
    rp.name AS vendor,
    po.name AS PO,
    CASE 
    WHEN po.picking_type_id = 7 THEN 'Dropship'
    WHEN po.picking_type_id = 9 then 'Outright'
    WHEN po.picking_type_id = 10 then 'Transshipment'
    ELSE ''
    END AS procurement_type,
    DATE(po.create_date + INTERVAL '7 HOUR') AS create_date,
    DATE(po.date_approve + INTERVAL '7 HOUR') AS approved_date,
    DATE(po.write_date + INTERVAL '7 HOUR') as Last_Updated_on,
    COUNT(pol.product_id) AS sku_qty,
    SUM(pol.product_qty) AS ordered_qty,
    SUM(pol.qty_received) AS received_qty,
    SUM(pol.product_qty) - SUM(pol.qty_received) AS missing_qty,
    SUM(pol.qty_received * pol.price_unit) AS received_amount,
    SUM(pol.price_total) AS total_amount
FROM 
    purchase_order po
LEFT JOIN purchase_order_line pol ON pol.order_id = po.id
LEFT JOIN res_partner rp ON rp.id = po.partner_id
GROUP BY 1,2,3,4,5,6
ORDER BY 1




