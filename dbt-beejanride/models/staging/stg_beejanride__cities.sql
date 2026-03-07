with source as (
    SELECT 
        city_id,
        city_name,
        country,                        
        country as country_name,        
        launch_date

    FROM {{ source('beejanride', 'cities_raw') }}
)

SELECT * FROM source