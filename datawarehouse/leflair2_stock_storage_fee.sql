DROP TABLE IF EXISTS public.leflair2_stock_storage_fee;

CREATE TABLE IF NOT EXISTS public.leflair2_stock_storage_fee AS


WITH vendor_temp AS (SELECT 
						ps.product_id,
						array_to_string(array_agg(distinct rp.name),',') as vendor
					FROM 
						ingested_data.leflair2_product_supplierinfo ps
					LEFT JOIN ingested_data.leflair2_res_partner rp ON rp.id = ps.name
					GROUP BY 1)


SELECT 
	sf.sku,
	sf.product_name,
	sf.inventory_cost,
	TO_CHAR(TO_DATE(sf.fee_calculation_time, 'YYYY-MM'), 'MM-YYYY') AS fee_calculation_time,
	rp.name AS vendor,
	lc.main_category
FROM ingested_data.leflair2_storage_fee sf
LEFT JOIN ingested_data.leflair2_product_product pp ON pp.barcode = sf.sku
LEFT JOIN vendor_temp vt ON vt.product_id = pp.id
LEFT JOIN ingested_data.leflair2_product_supplierinfo ps ON ps.product_id = pp.id
LEFT JOIN ingested_data.leflair2_res_partner rp ON rp.id = ps.name
LEFT JOIN ingested_data.leflair2_product_template pt ON pp.product_tmpl_id = pt.id
LEFT JOIN ingested_data.leflair2_product_category pc ON pt.categ_id = pc.id
LEFT JOIN ingested_data.leflair2_category lc ON pc.complete_name = lc.category_name