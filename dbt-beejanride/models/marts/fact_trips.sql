{{ config(
    materialized='table'
) }}

with drivers as (

            select distinct
                driver_id,
                trip_id,
                driver_lifetime_trips
            from {{ ref('int__drivers_enriched') }}
),

riders as (
        
        select distinct
                rider_id,
                rider_lifetime_value
            from {{ ref('int__riders_enriched') }}
),

trips as (

            select 
                trip_id,
                driver_id,
                rider_id,
                city_id,
                pickup_at,
                updated_at,
                dropoff_at,
                corporate_trip_flag,
                extreme_surge_multiplier,
                duplicate_trip_payments,
                trip_status,
                actual_fare,
                trip_duration_minutes,
                net_revenue,
                failed_payments_on_completed_trip,
                fraud_indicators

            from {{ ref('int__trips_enriched')}}
),
final as 
            (
        select 
            d.driver_id,
            d.trip_id,
            d.driver_lifetime_trips,
            r.rider_id,
            r.rider_lifetime_value,
            t.city_id,
            t.pickup_at,
            t.updated_at,
            t.dropoff_at,
            t.corporate_trip_flag,
            t.extreme_surge_multiplier,
            t.trip_status,
            t.actual_fare,
            t.trip_duration_minutes,
            t.net_revenue,
            t.failed_payments_on_completed_trip,
            t.fraud_indicators,
            t.duplicate_trip_payments

            from trips t
            left join drivers d on t.driver_id=d.driver_id
            left join riders r on t.rider_id=r.rider_id

            )

select * from final
qualify row_number() over (partition by trip_id order by updated_at desc) = 1

{% if is_incremental() %}
where updated_at > (select max(updated_at) from {{ this }})
{% endif %}