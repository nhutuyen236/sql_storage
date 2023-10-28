With temp AS(SELECT 
    so.name AS so,
    TO_CHAR(DATE(so.create_date), 'YYYY-MM-DD') AS create_date,
    sp.name AS receipt,
    sss.external_id_wms as amilo_request_id,
    sp.state AS receipt_state,
    MAX(case when ss.name = 'Pending' then TO_CHAR(sss.transition_datetime + '7 HOUR', 'YYYY-MM-DD HH24:MI:SS') else null end) as "Pending",
    MAX(case when ss.name = 'Confirm' then TO_CHAR(sss.transition_datetime + '7 HOUR', 'YYYY-MM-DD HH24:MI:SS') else null end) as "Confirmed",
    MAX(case when ss.name = 'Ready To Ship' then TO_CHAR(sss.transition_datetime + '7 HOUR', 'YYYY-MM-DD HH24:MI:SS') else null end) as "Ready To Ship",
    MAX(case when ss.name = 'Shipped' then TO_CHAR(sss.transition_datetime + '7 HOUR', 'YYYY-MM-DD HH24:MI:SS') else null end) as "Shipped",
    MAX(case when ss.name = 'Successfully Delivery' then TO_CHAR(sss.transition_datetime + '7 HOUR', 'YYYY-MM-DD HH24:MI:SS') else null end) as "Successfully Delivery",
    MAX(case when ss.name = 'Return Request' then TO_CHAR(sss.transition_datetime + '7 HOUR', 'YYYY-MM-DD HH24:MI:SS') else null end) as "Return Request",
    MAX(case when ss.name = 'Returned' then TO_CHAR(sss.transition_datetime + '7 HOUR', 'YYYY-MM-DD HH24:MI:SS') else null end) as "Returned",
    MAX(case when ss.name = 'Canceled' then TO_CHAR(sss.transition_datetime + '7 HOUR', 'YYYY-MM-DD HH24:MI:SS') else null end) as "Canceled",
    MAX(case when ss.name = 'On Return Failed Delivery' then TO_CHAR(sss.transition_datetime + '7 HOUR', 'YYYY-MM-DD HH24:MI:SS') else null end) as "On Return Failed Delivery",
    MAX(case when ss.name = 'Return Failed Delivery' then TO_CHAR(sss.transition_datetime + '7 HOUR', 'YYYY-MM-DD HH24:MI:SS') else null end) as "Return Failed Delivery"
    FROM sale_order so
INNER JOIN sale_order_line sol ON sol.order_id = so.id
INNER JOIN stock_picking sp ON sp.sale_id = so.id
INNER JOIN sale_shipment_status sss ON sss.picking_id = sp.id
INNER JOIN shipment_status ss ON ss.id = sss.shipment_status_id
WHERE so.create_date > NOW() - INTERVAL '4 MONTH'
GROUP BY 1,2,3,4,5),

abc AS (SELECT so.name, STRING_AGG( distinct sp.state, ', ') AS state
FROM sale_order so
inner join stock_picking sp ON sp.sale_id = so.id
group by 1),

def AS (SELECT 
	abc.name,
	CASE
		WHEN abc.state = 'done' THEN 'done'
		WHEN abc.state = 'cancel' THEN 'cancel'
		WHEN abc.state = 'cancel, done' THEN 'done'
		WHEN abc.state = 'done, cancel' THEN 'done'
	ELSE 'processing'
	END AS so_final_state
from abc),

sale AS (SELECT 
so.name AS so,
SUM(sol.product_uom_qty) AS sale_qty,
SUM(sol.qty_delivered) AS qty_delivered
FROM sale_order so
LEFT JOIN sale_order_line sol ON sol.order_id = so.id
WHERE so.state != 'draft' AND sol.product_id != 41119
AND sol.is_reward_line is null
GROUP BY 1),

receipt AS (
SELECT
sp.name,
SUM(sml.product_uom_qty) AS sl_dat_receipt,
SUM(sml.qty_done) AS sl_giao_receipt
FROM stock_picking sp 
LEFT JOIN stock_move_line sml ON sml.picking_id = sp.id
GROUP BY 1
),

rt AS (
    SELECT name,
    SUBSTRING(origin FROM POSITION('AMLSG' IN origin)) as source_doc
    from stock_picking
    WHERE NAME LIKE '%RT%'
),

final AS(
SELECT t.*,
def.so_final_state,
sale.sale_qty,
sale.qty_delivered,
receipt.sl_dat_receipt,
receipt.sl_giao_receipt,
rt.name AS phieu_return
FROM temp t
LEFT JOIN def ON def.name = t.so
LEFT JOIN sale ON sale.so = t.so
LEFT JOIN receipt ON receipt.name = t.receipt
LEFT JOIN rt ON rt.source_doc = t.receipt)

SELECT 
    so,
    sale_qty,
    qty_delivered,
    so_final_state,
    create_date,
    receipt,
    amilo_request_id,
    sl_dat_receipt,
    sl_giao_receipt,
    receipt_state,
    "Pending",
    "Confirmed",
    "Ready To Ship",
    "Shipped",
    "Successfully Delivery",
    "Return Request",
    "Returned",
    "Canceled",
    "On Return Failed Delivery",
    "Return Failed Delivery",
    phieu_return
FROM final




