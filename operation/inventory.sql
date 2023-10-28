SELECT 
	pp.barcode as sku,
	pt.name AS product_name,
	rp.name AS vendor_name,
    sl.complete_name AS stock_location,
    sq.stock_available
FROM product_product pp
LEFT JOIN product_template pt ON pt.id = pp.product_tmpl_id
LEFT JOIN product_category pc ON pc.id = pt.categ_id
LEFT JOIN product_supplierinfo ps ON ps.product_id = pp.id
LEFT JOIN res_partner rp ON rp.id = ps.name AND ps.product_id = pp.id
INNER JOIN (SELECT 
				product_id,
               	location_id,
				(quantity - reserved_quantity) AS stock_available
			FROM stock_quant
			WHERE location_id IN (17,18,20)
			) sq ON sq.product_id = pp.id 
LEFT JOIN stock_location sl ON sl.id = sq.location_id
WHERE sq.stock_available > 0
GROUP BY 1,2,3,4,5
ORDER BY 3,4
