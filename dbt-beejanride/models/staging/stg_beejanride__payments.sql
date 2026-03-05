with source as (
        SELECT 
            payment_id,
            trip_id,
            amount as total_amount,
            fee as platform_fee,
            currency as amount_currency,
            payment_status,
            payment_provider,
            created_at as created_at_timestamp
            --cast(created_at as date) as payments_created_at --only date from timestamp

        FROM {{ source('beejanride', 'payments_raw') }}
 
)

SELECT * FROM source
