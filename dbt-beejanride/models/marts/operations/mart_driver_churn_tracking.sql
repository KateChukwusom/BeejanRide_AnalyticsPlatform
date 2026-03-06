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
    datediff('day', last_trip_at, current_timestamp) as days_since_last_trip,
    case
        -- If it is more than 30 days then churned
        when datediff('day', last_trip_at, current_timestamp) > 30
        then 'churned'
        -- If it 14-30 days, then the driver is at risk of getting churned
        when datediff('day', last_trip_at, current_timestamp) > 14
        then 'at_risk'
        -- if it is within 14 days since their last trip, then active
        else 'active'
    end as churn_status
from last_trips