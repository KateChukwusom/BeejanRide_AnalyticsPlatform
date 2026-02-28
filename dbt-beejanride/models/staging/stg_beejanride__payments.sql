with source as (
        SELECT 
            payment_id,
            trip_id,
            amount as total_amount,
            fee as platform_fee,
            currency as amount_currency,
            payment_status,
            payment_provider,
            created_at,
            cast(created_at as date) as created_at --only date from timestamp

        FROM {{ source ('beejanride', 'payments_raw')}}

)

SELECT * FROM source;