SELECT 
	CAST(pp.barcode AS TEXT),
	pt.name AS product_name,
	rp.name AS vendor_name,
	pbc.name AS brand_name,
	pc.complete_name AS category_name,
	array_to_string(array_agg(distinct ppc1.name),',') AS web_cate,
	pp.fix_price AS retail_price,
	sor.remaining_quantity AS TS_DS_stock,
	sq.quantity AS OR_CS_stock,
	ps.price AS purchase_price,
	ppi.fixed_price AS sale_price,
	sub_query.sale_qty,
	CASE WHEN pt.is_published = 'True' then 'publish' ELSE 'no publish' END AS "publish/no publish"
FROM product_product pp
LEFT JOIN product_template pt ON pt.id = pp.product_tmpl_id
LEFT JOIN (SELECT 
				id,
				name 
			FROM product_public_category
			WHERE type_of_category = 'brand') pbc ON pbc.id = pt.brand_id
LEFT JOIN product_category pc ON pc.id = pt.categ_id
LEFT JOIN product_supplierinfo ps ON ps.product_id = pp.id
LEFT JOIN res_partner rp ON rp.id = ps.name AND ps.product_id = pp.id
LEFT JOIN stock_order_rule sor ON sor.product_id = pp.id
LEFT JOIN (SELECT 
				product_id,
				SUM(quantity) AS quantity
			FROM stock_quant
			WHERE location_id IN (18,20)
			GROUP BY 1) sq ON sq.product_id = pp.id
--18: consignment stock, 20: outright stock
LEFT JOIN (SELECT *,
	ROW_NUMBER() OVER (PARTITION BY product_id order by create_date desc) AS product_rank
			FROM product_pricelist_item 
			WHERE sale_event_id = 1) AS ppi ON ppi.product_id = pp.id
--sale_event_id = 1(discount_pricelist)
LEFT JOIN product_public_category_product_template_rel ppcptr ON ppcptr.product_template_id = pt.id
LEFT JOIN (SELECT * 
			FROM product_public_category 
			WHERE type_of_category in ('category','sale_event')) AS ppc1 ON ppc1.id = ppcptr.product_public_category_id
LEFT JOIN (SELECT sol.product_id,
       		SUM(CASE WHEN so.state IN ('sale', 'done') THEN sol.product_uom_qty ELSE 0 END) AS sale_qty
    FROM sale_order_line sol
    INNER JOIN sale_order so ON sol.order_id = so.id 
	WHERE sol.product_id != 41119 AND sol.is_reward_line IS NULL
	GROUP BY 1
) AS sub_query ON sub_query.product_id = pp.id
WHERE pp.barcode IS NOT null AND pp.barcode NOT LIKE 'DELETE%' and ppi.product_rank = 1
GROUP BY 1,2,3,4,5,7,8,9,10,11,12,13
ORDER BY 1