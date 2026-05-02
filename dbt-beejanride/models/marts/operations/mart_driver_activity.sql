-- Daily activity breakdown per driver to monitor operations and productivity

{{ config(materialized='table', tags=['operations']) }}

select
    driver_id,

    -- One row per driver per day
    date_trunc(pickup_at, day) as activity_date,
    -- How many trips they completed on this day
    count(trip_id) as trips_on_day,
    -- Total minutes they spent actively driving (pickup to dropoff)
    sum(trip_duration_minutes) as total_drive_time_minutes,
    -- How much they earned on this the day for BeejanRide
    sum(net_revenue) as daily_earnings

from {{ ref('fact_trips') }}
where trip_status = 'completed'
group by 1, 2