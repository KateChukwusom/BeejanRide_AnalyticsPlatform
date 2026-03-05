with source as (

        SELECT 
            event_id,
            driver_id,
            status as driver_status,
            event_timestamp

        FROM {{ source('beejanride', 'driver_status_events_raw') }}

) 
SELECT * FROM source