with source as (
    
    SELECT 
    city_id,
    city_name,
    country as country_name,
    launch_date
    from {{ source('beejanride','cities_raw') }}
) 
select * from source