{{ config(materialized='incremental',
            unique_key = 'trip_id')}}

with drivers as (

            select 
                driver_id,
                trip_id,
                driver_lifetime_trips
            from {{ ref('int__drivers_enriched') }}

),

riders as (
        
        select 
            trip_id, 
            rider_id,
            rider_lifetime_value
        from {{ ref('int__riders_enriched') }}
),

trips as (

            select 
                trip_id,
                city_id,
                pickup_at,
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
            left join drivers d on d.trip_id=t.trip_id
            left join riders r on r.trip_id=t.trip_id

            )

select * from final

{% if is_incremental() %}
where pickup_at > (select max(pickup_at) from {{ this }})
{% endif %}