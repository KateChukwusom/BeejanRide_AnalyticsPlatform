{% snapshot snap_drivers %}

{{
    config(
        target_schema='snapshots',
        unique_key='driver_id',
        strategy='timestamp',
        updated_at='updated_at'
    )
}}

select
    -- Driver identifiers
    driver_id,

    -- Driver attributes to track
    driver_status ,
    vehicle_id,
    rating ,

    -- Timestamp dbt uses to detect changes
    updated_at

from {{ source('beejanride', 'drivers_raw') }}

{% endsnapshot %}