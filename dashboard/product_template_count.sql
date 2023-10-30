DROP TABLE IF EXISTS public.leflair2_product_template_count;

CREATE TABLE IF NOT EXISTS public.leflair2_product_template_count AS

SELECT
		pt.product_create_date,
		pt.id,
		pt.name as product_name,
		pt.image_url,
		pt.web_description,
		CASE 
			WHEN pt.is_published = 'true' THEN 'publish'
		ELSE 'no_publish'
		END AS publish_state,
		lc.main_category,
		CASE 
			 WHEN lc.main_category = 'Accessories' THEN 'Tuyên Nguyễn'
			 WHEN lc.main_category = 'Fashion' THEN 'Duy Ma'
			 WHEN lc.main_category = 'FMCG' THEN 'Tiến Nguyễn'
			 WHEN lc.main_category = 'Home & Living' THEN 'Nhi Hoàng'
			 WHEN lc.main_category = 'Health & Beauty' THEN 'Tiến Nguyễn'
			 WHEN lc.main_category = 'Mom Kid Baby' THEN 'Nhi Hoàng'
		END AS buyer,
		SUM(COALESCE(sor.remaining_quantity, 0) + COALESCE(sq.available_qty, 0)) AS website_available_qty
FROM ingested_data.leflair2_product_template pt
LEFT JOIN ingested_data.leflair2_product_product pp ON pp.product_tmpl_id = pt.id
LEFT JOIN ingested_data.leflair2_stock_order_rule sor ON sor.product_id = pp.id
LEFT JOIN (SELECT  
				product_id,
				SUM(quantity - reserved_quantity) as available_qty	
			FROM ingested_data.leflair2_stock_quant
			GROUP BY 1) sq ON sq.product_id = pp.id
LEFT JOIN ingested_data.leflair2_product_category pc ON pc.id = pt.categ_id
LEFT JOIN ingested_data.leflair2_category lc ON pc.complete_name = lc.category_name		
WHERE pt.product_type = 'product'
GROUP BY 1,2,3,4,5,6,7,8
