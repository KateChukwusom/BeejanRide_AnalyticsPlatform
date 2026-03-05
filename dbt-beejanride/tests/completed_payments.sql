-- Returns completed trips that have a failed payment
-- dbt expects zero rows

select trip_id, trip_status, failed_payments_on_completed_trip
from {{ ref('fact_trips') }}
where trip_status = 'completed' and failed_payments_on_completed_trip = 1