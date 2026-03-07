
{{ config(materialized='table', tags=["finance"]) }}

select
    -- Truncate the timestamp to adjust the date so we can group by day
    date_trunc('day', pickup_at) as trip_date,
    city_id,
    
    -- This counts the total number of completed trips on this day in this city
    count(trip_id) as total_trips,

    -- This measures the full fare(Gross) the rider paid before any deductions
    sum(actual_fare) as gross_revenue,

    -- This measures the what the company retains after driver payout and fees
    sum(net_revenue) as net_revenue

from {{ ref('fact_trips') }}

    -- This accounts for only completed trips
where trip_status = 'completed'

group by 1, 2  