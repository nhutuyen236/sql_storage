DROP TABLE IF EXISTS public.leflair2_target_daily_final;

CREATE TABLE IF NOT EXISTS public.leflair2_target_daily_final AS
WITH a_revenue_category_daily AS
(
select sale_date,
    main_category,
    sum(daily_sale) as a_revenue_category
from public.leflair2_sales_performance
group by 1,2
),
t_revenue_category_daily AS (
    SELECT date(concat(substr(t_date,7,4),'-', substr(t_date,4,2), '-', substr(t_date,1,2))) as date,
    category AS main_category,
    CAST(t_revenue_category_daily as bigint) AS t_revenue_category
FROM ingested_data.leflair2_target_daily
)

SELECT trcd.*, arcd.a_revenue_category
FROM t_revenue_category_daily trcd
LEFT JOIN a_revenue_category_daily arcd ON arcd.sale_date = trcd.date AND arcd.main_category = trcd.main_category