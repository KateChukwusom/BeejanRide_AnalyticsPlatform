
with source as (
        SELECT 
            rider_id,
            country AS rider_country,
            signup_date,
            referral_code,
            created_at as riders_created_timestamp
            --CAST(created_at as DATE) as riders_created_at

        FROM {{ source('beejanride', 'riders_raw') }}

)

SELECT 
        * 
        FROM source



        