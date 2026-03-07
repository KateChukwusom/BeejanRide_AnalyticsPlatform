-- This analyzes the revenue impact extreme surges (>10)
{{ config(materialized='table', tags=['operations']) }}

select
    date_trunc('day', pickup_at) as trip_date,
    city_id,

    -- All trips on this day in this city (completed only)
    count(trip_id) as total_trips,

    -- Count of trips flagged as extreme surge (multiplier > 10)
   count_if(extreme_surge_multiplier) as extreme_surge_trips,
    -- Average fare across all trips — compare with extreme_surge_trips
    -- to see how much surge is inflating the average
    avg(actual_fare) as avg_fare,

    -- Net revenue on this day, revenue should increase a bit here
    sum(net_revenue) as total_net_revenue

from {{ ref('fact_trips') }}
where trip_status = 'completed'
group by 1, 2