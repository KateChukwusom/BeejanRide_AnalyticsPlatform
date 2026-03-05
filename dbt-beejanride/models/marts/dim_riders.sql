{{ config(materialized='table')}}

with riders as (
        select
            rider_id,
            rider_country,
            signup_date,
            referral_code,
            riders_created_timestamp
            
        from {{ ref('int__riders_enriched') }}
),

final as (

        select 
            rider_id,
            rider_country,
            signup_date,
            referral_code,
            riders_created_timestamp
            
        from riders
        QUALIFY ROW_NUMBER() OVER (PARTITION BY rider_id ORDER BY signup_date DESC) = 1  
)

select * from final