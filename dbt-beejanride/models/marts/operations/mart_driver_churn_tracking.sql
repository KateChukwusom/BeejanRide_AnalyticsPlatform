{{ config(materialized='table', tags=['operations']) }}

-- This measures the percentage of drivers that stop working over a specific period of time
with last_trips as (
    select
        driver_id,
        max(pickup_at) as last_trip_at,
        driver_lifetime_trips
    from {{ ref('fact_trips') }}
    where trip_status = 'completed'
    group by 1, 3
)

select
        -- find each driver's most recent trip
    driver_id,
    last_trip_at,
    driver_lifetime_trips,
        -- How many days have passed since their last trip
    date_diff(cast(current_timestamp() as datetime), last_trip_at, day) as days_since_last_trip,
    case
        when date_diff(cast(current_timestamp() as datetime), last_trip_at, day) > 30
        then 'churned'
        when date_diff(cast(current_timestamp() as datetime), last_trip_at, day) > 14
        then 'at_risk'
        else 'active'
    end as churn_status
from last_trips