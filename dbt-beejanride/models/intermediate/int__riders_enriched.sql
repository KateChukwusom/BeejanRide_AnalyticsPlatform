{{ config(materialized='view')}}

with riders as (
        select 
            rider_id,
            rider_country,
            signup_date,
            referral_code,
            riders_created_timestamp

        from {{ ref('stg_beejanride__riders') }}
),


trips as (

        select 
            trip_id,
            rider_id,
            actual_fare,
            trip_status,
            SUM(actual_fare) OVER (PARTITION BY rider_id) as rider_lifetime_value
        from {{ ref('stg_beejanride__trips') }}
),

final as (

            select 
                t.trip_id,
                r.rider_id,
                r.rider_country,
                r.signup_date,
                t.actual_fare,
                t.trip_status,
                t.rider_lifetime_value,
                r.riders_created_timestamp,
                r.referral_code

            from riders r
            left join trips t
            on r.rider_id = t.rider_id


)

select * from final