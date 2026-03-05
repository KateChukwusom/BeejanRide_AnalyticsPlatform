-- Returns trips where duration is zero or negative
-- dbt expects zero rows

select trip_id, trip_duration_minutes
from {{ ref('fact_trips') }}
where trip_duration_minutes < 0