{{ config(materialized='table') }}

with cities as (

        select 
            city_id,
            city_name,
            country_name,
            launch_date
        from {{ ref('stg_beejanride__cities') }}
),

final as (
    select 
        city_id,
        city_name,
        country_name,
        launch_date
    from  cities

)

select * from final