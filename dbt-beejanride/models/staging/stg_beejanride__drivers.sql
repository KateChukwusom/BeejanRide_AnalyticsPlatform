with source as (
    SELECT 
    driver_id,
    city_id,
    vehicle_id,
    driver_status,
    rating,
    onboarding_date,
    created_at,
    updated_at,
    CAST (created_at as DATE) as created_at, -- only created date
    CAST (updated_at as DATE) as updated_at  -- only updated date

    from {{ source ('beejanride', 'drivers_raw')}}
)

select * from source