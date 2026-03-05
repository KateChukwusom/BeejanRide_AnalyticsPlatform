{{ config(materialized='table')}}

with drivers as (

            select 
                
                driver_id,
                city_id,
                vehicle_id,
                driver_status,
                rating,
                onboarding_date
                
            from {{ ref ('int__drivers_enriched') }}
),

final as (

            select 
                driver_id,
                city_id,
                vehicle_id,
                onboarding_date,
                driver_status,
                rating
            from drivers
            QUALIFY ROW_NUMBER() OVER (PARTITION BY driver_id ORDER BY onboarding_date DESC) = 1  
)

select * from final 