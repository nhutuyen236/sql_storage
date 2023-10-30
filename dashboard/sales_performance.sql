DROP TABLE IF EXISTS public.leflair2_sales_performance;

CREATE TABLE IF NOT EXISTS public.leflair2_sales_performance AS

WITH temp AS (SELECT
    pb.name AS brand_name,
    pp.barcode as sku,
    rp.name AS supplier,
    CONCAT(pt.name,' ','(',pr.name,')') AS product,
    sub_query.so,
    sub_query.sale_qty,
    sub_query.daily_sale,
    sub_query.product_price_before_tax,
    gpo.purchasing_price,
    sub_query.product_id,
    sub_query.partner_id,
    sub_query.sale_date,
    sub_query.create_date,
    sub_query.qty_delivered,
    pv.purchase_price AS price_purchase,
    pp.fix_price AS retail_price,
    pc.complete_name AS category_name,
    lc.main_category,
    lc.sub_category
  FROM
      (SELECT
        so.so,
        SUM(sol.product_uom_qty) AS sale_qty,
        SUM(sol.price_subtotal) AS daily_sale,
        SUM(sol.qty_delivered) AS qty_delivered,
        SUM(sol.price_reduce_taxexcl) as product_price_before_tax,
        sol.product_id,
        so.sale_date,
        so.create_date,
        so.pricelist_id,
        so.partner_id
    FROM ingested_data.leflair2_sale_order_line sol
    LEFT JOIN ingested_data.leflair2_sale_order so ON sol.order_id = so.id
    WHERE so.state NOT IN ('draft', 'cancel', 'sent')
    GROUP BY 1,6,7,8,9,10) sub_query
    LEFT JOIN ingested_data.leflair2_product_product pp ON sub_query.product_id = pp.id
    LEFT JOIN ingested_data.leflair2_product_template pt ON pp.product_tmpl_id = pt.id
    LEFT JOIN ingested_data.leflair2_product_brand pb ON pb.id = pt.brand_id
    LEFT JOIN ingested_data.leflair2_product_category pc ON pt.categ_id = pc.id
    LEFT JOIN ingested_data.price_vendor_pertime pv ON pv.product_id = sub_query.product_id AND pv.so = sub_query.so
    LEFT JOIN ingested_data.leflair2_product_supplierinfo ps ON ps.product_id = pp.id
    LEFT JOIN ingested_data.leflair2_res_partner rp ON rp.id = ps.name
    LEFT JOIN ingested_data.leflair2_product_pricelist pr ON pr.id = sub_query.pricelist_id
    LEFT JOIN ingested_data.leflair2_category lc ON pc.complete_name = lc.category_name
    LEFT JOIN ingested_data.leflai2_get_price_po gpo ON sub_query.product_id = gpo.product_id AND gpo.so = sub_query.so
    ),

tmp_pt AS(
  select pt.name as product_parent_name, 
  pp.product_tmpl_id as product_id, 
  count(pp.id) as number_of_variant
  from ingested_data.leflair2_product_product pp
left join ingested_data.leflair2_product_template pt ON pt.id = pp.product_tmpl_id
group by 1,2
),

tmp_ps_pc AS (SELECT pt.id as product_id,
        pt.name as sku_name,
        pt.name as product_parent_name,
        ab.name as product_color,
        abc.name as product_size
  FROM ingested_data.leflair2_product_template pt
  LEFT JOIN ingested_data.leflair2_product_product pp ON pp.product_tmpl_id = pp.id
  LEFT JOIN (SELECT ptav.attribute_id, ptav.product_tmpl_id, pav.name 
  FROM ingested_data.leflair2_product_template_attribute_value ptav
  INNER JOIN ingested_data.leflair2_product_attribute_value pav ON pav.id = ptav.product_attribute_value_id      
  WHERE ptav.attribute_id = 2) ab ON pt.id  = ab.product_tmpl_id
  LEFT JOIN (SELECT ptav2.attribute_id, ptav2.product_tmpl_id, pav.name 
  FROM ingested_data.leflair2_product_template_attribute_value ptav2
  INNER JOIN ingested_data.leflair2_product_attribute_value pav ON pav.id = ptav2.product_attribute_value_id       
  WHERE ptav2.attribute_id != 2) abc ON pt.id  = abc.product_tmpl_id
  GROUP BY 1,2,3,4,5),
f_tmp AS (
SELECT
    temp.brand_name,
    temp.supplier,
    temp.sku,
    temp.product,
    temp.so,
    temp.sale_qty,
    temp.qty_delivered,
    temp.daily_sale,
    temp.product_price_before_tax,
    CASE WHEN temp.purchasing_price IS NULL then temp.price_purchase
    ELSE temp.purchasing_price END AS purchase_price,
    temp.product_id,
    temp.sale_date,
    temp.create_date,
    temp.retail_price,
    temp.category_name,
    temp.main_category,
    temp.sub_category,
    substring(rp.email from '(?<=@)[^.]+(?=\.)') as provider,
    date(rp.create_date) as customer_create_date,
    tmp_pt.number_of_variant,
    tmp_pt.product_parent_name
FROM temp
LEFT JOIN ingested_data.leflair2_product_product pp2 ON pp2.id = temp.product_id
LEFT JOIN tmp_pt ON tmp_pt.product_id = pp2.product_tmpl_id
LEFT JOIN ingested_data.res_partner rp ON temp.partner_id = rp.id
),
t_tmp AS (
SELECT
    f_tmp.brand_name,
    f_tmp.supplier,
    f_tmp.sku,
    f_tmp.product,
    f_tmp.so,
    f_tmp.sale_qty,
    f_tmp.qty_delivered,
    f_tmp.daily_sale,
    f_tmp.product_price_before_tax,
    CASE WHEN f_tmp.purchase_price IS NULL then pls.price 
    ELSE f_tmp.purchase_price END AS purchase_price,
    f_tmp.product_id,
    f_tmp.sale_date,
    f_tmp.create_date,
    f_tmp.retail_price,
    f_tmp.category_name,
    f_tmp.main_category,
    f_tmp.sub_category,
    f_tmp.provider,
    f_tmp.customer_create_date,
    f_tmp.number_of_variant,
    f_tmp.product_parent_name
FROM f_tmp
LEFT JOIN ingested_data.leflair2_product_supplierinfo pLs ON pls.product_id = f_tmp.product_id
),
e_tmp AS (
SELECT
    t_tmp.brand_name,
    t_tmp.supplier,
    t_tmp.sku,
    t_tmp.product,
    t_tmp.so,
    t_tmp.sale_qty,
    t_tmp.qty_delivered,
    t_tmp.daily_sale,
    t_tmp.product_price_before_tax,
    CASE WHEN ptt.thue_percent != 0.0 THEN t_tmp.purchase_price - (t_tmp.purchase_price * ptt.thue_percent)
    ELSE t_tmp.purchase_price END as purchase_price,
    --t_tmp.purchase_price - (t_tmp.purchase_price * ptt.thue_percent) as purchase_price,
    t_tmp.product_id,
    t_tmp.sale_date,
    t_tmp.create_date,
    t_tmp.retail_price,
    t_tmp.category_name,
    t_tmp.main_category,
    t_tmp.sub_category,
    t_tmp.provider,
    t_tmp.customer_create_date,
    t_tmp.number_of_variant,
    t_tmp.product_parent_name
FROM t_tmp 
left join ingested_data.product_template_tax ptt on ptt.sku_id = t_tmp.product_id)
SELECT DISTINCT * FROM e_tmp