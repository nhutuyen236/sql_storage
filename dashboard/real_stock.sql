DROP TABLE IF EXISTS public.leflair2_real_stock;

CREATE TABLE IF NOT EXISTS public.leflair2_real_stock AS

WITH vendor_temp AS (SELECT 
						ps.product_id,
						array_to_string(array_agg(distinct rp.name),',') as vendor
					FROM 
						ingested_data.leflair2_product_supplierinfo ps
					LEFT JOIN ingested_data.leflair2_res_partner rp ON rp.id = ps.name
					GROUP BY 1),
					
type_temp AS (SELECT 
						product_id,
						CASE
							WHEN location_id = 20 THEN 'Outright'
							WHEN location_id = 17 THEN 'Transhipment'
							WHEN location_id = 18 THEN 'Consignment'
						END AS procurement_type
					FROM  ingested_data.leflair2_stock_quant
					WHERE (quantity - reserved_quantity) > 0
					GROUP BY 1,2),
f_type_temp AS (SELECT 
						product_id,
						array_to_string(array_agg(distinct procurement_type),',') as procurement_type
				FROM type_temp
				GROUP BY 1)


SELECT 
	im.*,
	vt.vendor,
	ftt.procurement_type,
	pb.name AS brand,
	pc.complete_name,
	lc.main_category,
	lc.sub_category,
	CASE 
			 WHEN lc.main_category = 'Accessories' THEN 'Tuyên Nguyễn'
			 WHEN lc.main_category = 'Fashion' THEN 'Kiều Thu'
			 WHEN lc.main_category = 'FMCG' THEN 'Tiến Nguyễn'
			 WHEN lc.main_category = 'Home & Living' THEN 'Nhi Hoàng'
			 WHEN lc.main_category = 'Health & Beauty' THEN 'Tiến Nguyễn'
			 WHEN lc.main_category = 'Mom Kid Baby' THEN 'Nhi Hoàng'
	END AS buyer,
	CASE 
			WHEN CAST(im.stock_age AS INT) < 30 THEN 'Green Stock (< 30 days)'
			WHEN CAST(im.stock_age AS INT) >= 30 AND CAST(im.stock_age AS INT) <= 59 THEN 'Red Stock (30-59 days)'
			WHEN CAST(im.stock_age AS INT) >= 60 THEN 'Black Stock (> 60 days)'
	END AS age_bucket
FROM ingested_data.leflair2_inventory_amilo im
LEFT JOIN ingested_data.leflair2_product_product pp ON pp.barcode = im.sku
left join vendor_temp vt on vt.product_id = pp.id
LEFT JOIN ingested_data.leflair2_product_supplierinfo ps ON ps.product_id = pp.id
LEFT JOIN ingested_data.leflair2_res_partner rp ON rp.id = ps.name
LEFT JOIN ingested_data.leflair2_product_template pt ON pp.product_tmpl_id = pt.id
LEFT JOIN ingested_data.leflair2_product_brand pb on pb.id = pt.brand_id
LEFT JOIN ingested_data.leflair2_product_category pc ON pt.categ_id = pc.id
LEFT JOIN ingested_data.leflair2_category lc ON pc.complete_name = lc.category_name
LEFT JOIN f_type_temp ftt ON ftt.product_id = pp.id
ORDER BY 4