{{ config(materialized='table', tags=['fraud']) }}

select
    driver_id,
    rider_id,
    trip_id,
    pickup_at,
    city_id,
    actual_fare,
    duplicate_trip_payments,
    fraud_indicators,
    extreme_surge_multiplier,
    failed_payments_on_completed_trip
from {{ ref('fact_trips') }}
where
    fraud_indicators = true
    or duplicate_trip_payments = true
    or extreme_surge_multiplier = true

    