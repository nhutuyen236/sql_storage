DROP TABLE IF EXISTS public.leflair2_product_variant_count ;

CREATE TABLE IF NOT EXISTS public.leflair2_product_variant_count  AS 
WITH temp AS (SELECT
	pt.product_create_date,
	pt.id as template_id,
	pp.id,
	pp.barcode,
	pt.name AS product_name, 
	pc.complete_name AS category,
	pbc.name AS brand,
	array_to_string(array_agg(distinct rp.name),',') as vendor, -- 1 product has more 1 vendor
	pp.image_url,
	pt.web_description,
	CASE 
		WHEN pt.is_published = 'true' THEN 'publish'
	ELSE 'no_publish'
	END AS publish_state,
	pp.sku_create_date AS create_date,
	rp2.name AS created_by,
	(COALESCE(sor.remaining_quantity, 0) + COALESCE(sq.available_qty, 0)) AS website_available_qty
FROM ingested_data.leflair2_product_product pp
INNER JOIN ingested_data.leflair2_product_template pt ON pt.id = pp.product_tmpl_id
LEFT JOIN ingested_data.leflair2_product_brand pbc on pbc.id = pt.brand_id
LEFT JOIN ingested_data.leflair2_product_category pc ON pc.id = pt.categ_id
LEFT JOIN ingested_data.leflair2_product_supplierinfo ps ON ps.product_id = pp.id
LEFT JOIN ingested_data.leflair2_res_partner rp ON rp.id = ps.name AND ps.product_id = pp.id
LEFT JOIN ingested_data.leflair2_res_users ru ON pp.create_uid = ru.id
LEFT JOIN ingested_data.leflair2_res_partner rp2 ON rp2.id = ru.partner_id
LEFT JOIN ingested_data.leflair2_stock_order_rule sor ON sor.product_id = pp.id
LEFT JOIN (SELECT  
				product_id,
				SUM(quantity - reserved_quantity) as available_qty	
			FROM ingested_data.leflair2_stock_quant
	GROUP BY 1) sq ON sq.product_id = pp.id
-- use sum because stock in various location
WHERE pt.product_type = 'product' AND pp.barcode IS NOT NULL
GROUP BY 1,2,3,4,5,6,7,9,10,11,12,13,14
ORDER BY 1),

temp2 AS (
			SELECT  
				product_id,
				CASE 
					WHEN location_id = 17 THEN 'Transshipment'
					WHEN location_id = 18 THEN 'Consignment'
					WHEN location_id = 20 THEN 'Outright'
				END AS type
			FROM ingested_data.leflair2_stock_quant
	WHERE location_id in (17,18,20)
	GROUP BY 1,2),
	
temp3 AS (
			SELECT 
				product_id,
				array_to_string(array_agg(distinct type),',') as final_type
			FROM temp2
			GROUP BY 1
),



final_temp AS (SELECT 
	t.product_create_date,
	t.template_id,	
	t.id,
	t.barcode,
	t.product_name,
	t.category,
	t.brand,
	t.vendor,
	t.image_url AS image,
	t.web_description AS description,
	publish_state,
	t.create_date,
	t.created_by,
	t.website_available_qty,
	CASE
		WHEN temp3.final_type = sor.type THEN COALESCE(temp3.final_type, '')
		ELSE COALESCE(temp3.final_type, '') || ',' || COALESCE(sor.type, '')
	END AS business_type
FROM temp t
LEFT JOIN (SELECT 
				product_id,
				CASE 
					WHEN sorsrr.stock_rule_id = 9 THEN 'DropShip'
					WHEN sorsrr.stock_rule_id = 7 THEN 'Transshipment'	
			 	END AS type
			 FROM ingested_data.leflair2_stock_order_rule sor
LEFT JOIN ingested_data.leflair2_stock_order_rule_stock_rule_rel sorsrr ON sor.id = sorsrr.stock_order_rule_id
) sor ON sor.product_id = t.id
LEFT JOIN temp3 ON temp3.product_id = t.id

GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15)

SELECT 	
		t.id,
		t.template_id,	
		t.barcode,
		t.product_name,
		t.category,
		t.brand,
		t.vendor,
		t.image,
		t.description,
		t.publish_state,
		pp.sku_create_date,
		t.created_by,
		t.website_available_qty,
		lc.main_category,
		CASE
			WHEN LEFT(business_type, 1) = ',' THEN SUBSTRING(business_type, 2)
			WHEN RIGHT(business_type, 1) = ',' THEN LEFT(business_type, LENGTH(business_type) - 1)
		ELSE business_type
		END AS final_business_type
	FROM final_temp t
	LEFT JOIN ingested_data.leflair2_product_product pp ON t.id = pp.id
	LEFT JOIN ingested_data.leflair2_category lc ON lc.category_name = t.category
	GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15


