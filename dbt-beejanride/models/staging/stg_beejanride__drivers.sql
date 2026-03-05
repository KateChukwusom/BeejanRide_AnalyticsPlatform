with source as (
    SELECT 
    driver_id,
    city_id,
    vehicle_id,
    driver_status,
    rating,
    onboarding_date,
    created_at as created_at_timestamp,
    updated_at as updated_at_timestamp
    --CAST (created_at as DATE) as drivers_created_at, -- only created date
    --CAST (updated_at as DATE) as drivers_updated_at  -- only updated date

    from {{ source('beejanride', 'drivers_raw') }}
)

select * from source

