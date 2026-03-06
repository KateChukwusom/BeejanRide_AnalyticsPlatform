-- Lifetime value view per rider — used for retention and marketing analysis
{{ config(materialized='table', tags=['operations']) }}

select
    rider_id,

    -- Total number of completed trips this rider has taken
    count(trip_id) as total_trips,

    -- When they first used BeejanRide
    min(pickup_at) as first_trip_at,

    -- When they last used BeejanRide — helps identify dormant riders
    max(pickup_at) as last_trip_at,

    -- Total amount the rider has been charged across all trips
    sum(actual_fare) as gross_spend,

    -- This is the net revenue BeejanRide has earned from this rider lifetime
    rider_lifetime_value as ltv

from {{ ref('fact_trips') }}
where trip_status = 'completed'

-- Group by rider and ltv (ltv is rider-level, already aggregated in int__riders_enriched)
group by 1, 6