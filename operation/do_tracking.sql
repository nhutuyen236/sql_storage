select 
	sp.create_date + INTERVAL '7 HOUR' as created_on,
	sp.name as transfer,
	sp.origin as reference,
	case 
		when sp.name LIKE 'AMLSG/OUT/%' then 'Consignment/Outright'
		when sp.name like 'DS%' then 'Dropship'	
		when sp.name like 'AMLSG/TS_OUT/%' then 'Transshipment'
		when sp.name like 'RT%' then 'Returned'
	end as procurement,
	pt.name as product_name,
	pp.barcode,
	SUM(sml.product_uom_qty) AS demand,
 	SUM(sml.qty_done) AS done,
 	case
 		 when sp.state = 'cancel' then (sml.product_uom_qty - sml.qty_done)
 		 else null 
 	end as cancellation,
 	sp.amilo_shipment_status as shipment_status,	
	sp.state as status
from stock_move_line sml
left join product_product pp on sml.product_id = pp.id
left join product_template pt on pt.id = pp.product_tmpl_id 
left join stock_picking sp on sml.picking_id = sp.id
WHERE sp.name NOT LIKE '%IN%'
group by 1,2,3,4,5,6,9,10,11
order by 2
