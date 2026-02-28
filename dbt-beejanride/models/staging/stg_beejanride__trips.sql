with source as (
        SELECT 
            trip_id,
            rider_id,
            driver_id,
            city_id,
            vehicle_id,
            status AS trip_status,
            payment_method,
            is_corporate,
            estimated_fare,
            actual_fare,
            surge_multiplier,
            requested_at,
            pickup_at,
            dropoff_at,
            created_at,
            updated_at


        FROM {{ source ('beejanride', 'trips_raw')}}

)
SELECT * FROM source;