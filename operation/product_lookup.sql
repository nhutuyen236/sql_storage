SELECT 
			pp.barcode,
			pt.name as product_name,
			pp.weight,
			--pt.web_description,
			pt.list_price as retail_price,
			ppi.fixed_price AS sale_price,
			pp.image_url as image_link,
			array_to_string(array_agg(distinct pi.image_url),',') as image_link2,
			--sor.remaining_quantity AS TS_stock
			sq.available_qty
FROM product_product pp
LEFT JOIN product_template pt ON pt.id = pp.product_tmpl_id
left join product_image pi on pi.product_tmpl_id = pt.id
LEFT JOIN (SELECT 
				product_id,
				(quantity - reserved_quantity) AS available_qty
			FROM stock_quant
			WHERE location_id = 20) sq ON sq.product_id = pp.id
LEFT JOIN (
			select 
				sor.id, 
				sor.product_id,
				sor.remaining_quantity
			from stock_order_rule sor 
			LEFT JOIN stock_order_rule_stock_rule_rel sorsrr on sorsrr.stock_order_rule_id = sor.id
			where sorsrr.stock_rule_id = 7) sor on sor.product_id = pp.id
LEFT JOIN (
		SELECT 
			*,
			ROW_NUMBER() OVER (PARTITION BY product_id order by create_date desc) AS product_rank
		FROM product_pricelist_item 
		WHERE sale_event_id = 1) AS ppi ON ppi.product_id = pp.id
WHERE pp.barcode in  ('ATLF-BLOW-BL-L',
'ATLF-BLOW-BL-M',
'ATLF-BLOW-BL-XL',
'ATLF-BLOW-W-L',
'ATLF-BLOW-W-M',
'ATLF-BLOW-W-XL',
'ATLF-DONT-BL-L',
'ATLF-DONT-BL-M',
'ATLF-DONT-BL-XL',
'ATLF-DONT-W-L',
'ATLF-DONT-W-M',
'ATLF-DONT-W-XL',
'ATLF-NOT-BL-L',
'ATLF-NOT-BL-M',
'ATLF-NOT-BL-XL',
'ATLF-NOT-W-L',
'ATLF-NOT-W-M',
'ATLF-NOT-W-XL',
'ATLF-COME-BL-L',
'ATLF-COME-BL-M',
'ATLF-COME-BL-XL',
'ATLF-COME-W-L',
'ATLF-COME-W-M',
'ATLF-COME-W-XL',
'ATLF-GIT-NA-L',
'ATLF-GIT-NA-M',
'ATLF-GIT-NA-XL',
'ATLF-WHO-W-L',
'ATLF-WHO-W-M',
'ATLF-WHO-W-XL')
and ppi.product_rank = 1
GROUP BY 1,2,3,4,5,6,8
order by 1



