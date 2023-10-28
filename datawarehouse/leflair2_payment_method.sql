DROP TABLE IF EXISTS public.leflair2_payment_method;

CREATE TABLE IF NOT EXISTS public.leflair2_payment_method AS
SELECT  
	so.sale_date AS sale_date,
	so.so,
	pa.name AS payment_method,
	so.state,
	SUM(sol.price_subtotal) as sale
FROM ingested_data.leflair2_sale_order so
LEFT JOIN ingested_data.leflair2_sale_order_line sol ON sol.order_id = so.id
LEFT JOIN ingested_data.leflair2_payment_acquirer pa ON pa.id = so.payment_method_id
WHERE so.state NOT IN ('draft', 'cancel', 'sent') AND sol.product_uom_qty != 0  
GROUP BY 1,2,3,4
order by 1