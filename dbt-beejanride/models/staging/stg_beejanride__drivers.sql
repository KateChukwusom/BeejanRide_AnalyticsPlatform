with source as (
    SELECT 
        driver_id,
        city_id,
        vehicle_id,
        driver_status,
        rating,
        onboarding_date,
        created_at,                                  
        created_at as created_at_timestamp,          
        updated_at,                                  
        updated_at as updated_at_timestamp           

    FROM {{ source('beejanride', 'drivers_raw') }}
)

SELECT * FROM source