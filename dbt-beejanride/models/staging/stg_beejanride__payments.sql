with source as (
        SELECT 
            payment_id,
            trip_id,
            amount,                                    
            amount as total_amount,                    
            fee,                                       
            fee as platform_fee,                       
            currency,                                  
            payment_status,
            payment_provider,
            created_at
           

        FROM {{ source('beejanride', 'payments_raw') }}
)

SELECT * FROM source
