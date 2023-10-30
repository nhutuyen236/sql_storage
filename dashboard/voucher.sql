DROP TABLE IF EXISTS public.leflair2_voucher;
CREATE TABLE IF NOT EXISTS public.leflair2_voucher AS
SELECT 
    so.sale_date,
    so.so AS order_name,
    so.amount_total AS revenue,
    sol.price_unit * -1 AS voucher_value,
    pt.name AS voucher_name,
	so.state
FROM ingested_data.leflair2_sale_order so
LEFT JOIN ingested_data.leflair2_sale_order_line sol ON sol.order_id = so.id
LEFT JOIN ingested_data.leflair2_product_product pp ON pp.id = sol.product_id
LEFT JOIN ingested_data.leflair2_product_template pt ON pt.id = pp.product_tmpl_id
WHERE sol.is_reward_line IS TRUE