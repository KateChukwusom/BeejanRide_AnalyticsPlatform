{{ config(materialized='view')}}


with drivers as (
            select 
                driver_id,
                city_id,
                vehicle_id,
                driver_status,
                rating,
                onboarding_date
            from {{ ref('stg_beejanride__drivers') }}
),

trips as (

            select
                trip_id,
                driver_id,
                city_id,

            -- Calculating driver lifetime trip on a row-detail level
                COUNT(trip_id) OVER (PARTITION BY driver_id) as driver_lifetime_trips
            from {{ ref('stg_beejanride__trips') }}
),


final as (
            select 
                t.trip_id,
                d.driver_id,
                t.driver_lifetime_trips,
                t.city_id, -- city where trip occured
                d.vehicle_id,
                d.driver_status,
                d.rating,
                d.onboarding_date

            from trips t
            left join drivers d
            on t.driver_id = d.driver_id

)

select * from final