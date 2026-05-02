-- Tracks how often payments fail on trips that were successfully completed

{{ config(materialized='table', tags=['finance']) }}

select
    date_trunc(pickup_at, day) as trip_date,
    city_id,

    -- Denominator: all completed trips on this day in this city
    count(trip_id) as completed_trips,

    -- Numerator: trips where the payment failed despite the ride completing
    sum(cast(failed_payments_on_completed_trip as int64)) as failed_payments,

    -- Failure rate as a percentage, rounded to 2 decimal places 
    round(
        sum(cast(failed_payments_on_completed_trip as int64)) / nullif(count(trip_id), 0) * 100, 2) as failure_rate_pct

from {{ ref('fact_trips') }}
where trip_status = 'completed'
group by 1, 2