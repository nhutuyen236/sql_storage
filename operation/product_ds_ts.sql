SELECT
	pp.barcode,
	pt.name AS product_name,
	pc.complete_name AS category_name,
	pb.name AS brand,
	array_to_string(array_agg(distinct rp.name),',') as Supplier,
	pp.length,
	pp.height,
	pp.width,
	pp.weight,
	imd.external_id
FROM product_product pp
INNER JOIN product_template pt ON pt.id = pp.product_tmpl_id
INNER JOIN product_category pc ON pc.id = pt.categ_id
INNER JOIN (
			SELECT 
				id,
				name
		  	FROM product_public_category
		  	WHERE type_of_category = 'brand') pb ON pb.id = pt.brand_id
INNER JOIN (
			SELECT 
				sor.id, 
				sor.product_id 
			FROM stock_order_rule sor
			INNER JOIN stock_order_rule_stock_rule_rel sorsrr ON sor.id = sorsrr.stock_order_rule_id
			WHERE sorsrr.stock_rule_id = 7
			) sor1 ON sor1.product_id = pp.id	
LEFT JOIN product_supplierinfo ps ON ps.product_id = pp.id
LEFT JOIN res_partner rp ON rp.id = ps.name AND ps.product_id = pp.id
LEFT JOIN (
			SELECT 
				res_id, 
				CONCAT(module, name) AS external_id 
			FROM ir_model_data
			WHERE model ='product.product') imd ON imd.res_id = pp.id
WHERE pt.is_published is true
GROUP BY 1,2,3,4,6,7,8,9,10