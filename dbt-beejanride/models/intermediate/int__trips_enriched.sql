{{ config(
    materialized='table'
) }}



with trips as (
        select 
            trip_id,
            rider_id,
            driver_id,
            city_id,
            pickup_at,
            dropoff_at,
            trip_status,
            is_corporate,
            actual_fare,
            created_at,
            updated_at,
            surge_multiplier

                    from {{ ref('stg_beejanride__trips') }}
),

payments as (

            select 
                payment_id,
                trip_id,
                amount,
                fee,
                payment_status
            from {{ ref('stg_beejanride__payments')}}

), 

payment_quality as (

            select 
                trip_id,
                count(payment_id) as count_payment_id,
                sum(amount) as total_payment_amount,
                sum(fee) as total_platform_fee,
                max(case when payment_status = 'failed' then TRUE else FALSE end) as has_failed_payments,

            -- 1 if this trip has more than one payment record(duplicates)
                (CASE WHEN COUNT(payment_id) > 1 THEN TRUE ELSE FALSE END) as duplicate_trip_payments
                from payments 
                group by trip_id
),

trip_enriched as (

        select 
            t.trip_id,
            t.rider_id,
            t.driver_id,
            t.city_id,
            t.pickup_at,
            t.updated_at,
            t.dropoff_at,
            t.trip_status,
            t.is_corporate,
            t.actual_fare,
            t.created_at,
            t.surge_multiplier,
            p.has_failed_payments,
            p.duplicate_trip_payments,

        -- Calculated Metrics

        -- total minutes between pickup and dropoff(Trip duration minutes)
            date_diff(t.dropoff_at, t.pickup_at, minute) as trip_duration_minutes,

        -- 1 or true if rider is travelling under a corporate account, 0 or false otherwise
            case when t.is_corporate then TRUE else FALSE end as corporate_trip_flag,

        -- net revenue after deducting platform fee from total payment
            {{ calculate_net_revenue('coalesce(p.total_payment_amount, 0)', 'coalesce(p.total_platform_fee, 0)') }} as net_revenue,

        -- 1 or true if surge multiplier exceeds 10, 0 or false if otherwise
            coalesce(t.surge_multiplier > 10, FALSE) as extreme_surge_multiplier,

        -- 1 or true if trip was completed but payment did not go through
            case when t.trip_status = 'completed' and p.has_failed_payments then TRUE else FALSE end as failed_payments_on_completed_trip

        from trips t 
            left join payment_quality p 
                on t.trip_id = p.trip_id
),

final as (

            select 
            tp.trip_id,
            tp.rider_id,
            tp.driver_id,
            tp.city_id,
            tp.pickup_at,
            tp.updated_at,
            tp.dropoff_at,
            tp.trip_status,
            tp.is_corporate,
            tp.actual_fare,
            tp.created_at,
            tp.surge_multiplier,
            tp.has_failed_payments,
            tp.duplicate_trip_payments,
            tp.trip_duration_minutes, 
            tp.corporate_trip_flag,
            tp.net_revenue,
            tp.extreme_surge_multiplier,
            tp.failed_payments_on_completed_trip,
        -- condtions that specify fraud indicators
            (extreme_surge_multiplier OR 
            failed_payments_on_completed_trip OR
             duplicate_trip_payments)
              as fraud_indicators

            from trip_enriched tp

)
select * from final 
{% if is_incremental() %}
where updated_at > (select max(updated_at) from {{ this }})
{% endif %}
