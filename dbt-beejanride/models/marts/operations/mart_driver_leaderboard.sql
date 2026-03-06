-- Ranks drivers by total net revenue earned — used for the driver leaderboard dashboard
{{ config(materialized='table', tags=['operations']) }}

select
    driver_id,

    -- How many completed trips this driver has done
    count(trip_id) as total_trips,
    -- Total net revenue this driver has generated for BeejanRide
    sum(net_revenue) as total_net_revenue,
    -- Average fare per trip, to map productivity
    avg(actual_fare) as avg_fare_per_trip,
    -- Most recent trip timestamp — useful to confirm driver is still active
    max(pickup_at) as last_trip_at,
    -- Lifetime trips 
    driver_lifetime_trips

from {{ ref('fact_trips') }}
where trip_status = 'completed'

-- Group by driver and lifetime trips (lifetime trips is driver level--one row per driver))
group by 1, 6

-- Best performing drivers appear at the top
order by total_net_revenue desc