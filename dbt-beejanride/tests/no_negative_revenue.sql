-- Returns trips where revenue is negative
-- dbt expects zero rows

select trip_id, net_revenue
from {{ ref('fact_trips') }}
where net_revenue < 0