WITH abc AS (SELECT 
				pp.barcode,
				pt.name AS product_name,
				pbc.name AS brand_name,
				pc.complete_name as category,
				pp.fix_price AS retail_price,
				ppi.fixed_price AS sale_price,
				ps.price AS purchase_price,
				(COALESCE(sor.remaining_quantity, 0) + COALESCE(sq.available_qty, 0)) AS website_available_qty,
				CASE WHEN pt.is_published = 'True' then 'publish' ELSE 'no publish' END AS "is_published",
				array_to_string(array_agg(distinct rp.name),',') as vendor
FROM product_product pp
LEFT JOIN product_template pt ON pt.id = pp.product_tmpl_id
LEFT JOIN (
			SELECT *,
				ROW_NUMBER() OVER (PARTITION BY product_id order by create_date desc) AS product_rank
			FROM product_supplierinfo
			WHERE date_end >= CURRENT_DATE AND date_end <= '2023-12-31') ps ON ps.product_id = pp.id  
LEFT JOIN res_partner rp ON rp.id = ps.name AND ps.product_id = pp.id
LEFT JOIN product_category pc ON pc.id = pt.categ_id
LEFT JOIN (
			SELECT 
				*,
				ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY create_date DESC) AS product_rank
			FROM product_pricelist_item 
			WHERE sale_event_id = 1) AS ppi ON ppi.product_id = pp.id
LEFT JOIN (
			SELECT  
				product_id,
				SUM(quantity - reserved_quantity) as available_qty	
			FROM stock_quant
			GROUP BY 1) sq ON sq.product_id = pp.id
LEFT JOIN (SELECT 
				id,
				name 
			FROM product_public_category
			WHERE type_of_category = 'brand') pbc ON pbc.id = pt.brand_id
LEFT JOIN stock_order_rule sor ON sor.product_id = pp.id
WHERE ppi.product_rank = 1 AND ps.product_rank = 1 AND pp.active IS TRUE
GROUP BY 1,2,3,4,5,6,7,8,9)

SELECT 
	barcode, 
	product_name, 
	category, 
	retail_price, 
	sale_price, 
	purchase_price, 
	is_published,
	CASE 
		WHEN website_available_qty < 0 THEN 0
	ELSE website_available_qty 
	END AS website_qty,
	vendor,
	brand_name 
FROM abc