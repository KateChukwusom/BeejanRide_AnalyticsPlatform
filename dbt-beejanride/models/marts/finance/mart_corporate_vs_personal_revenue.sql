-- This model calculates revenue between corporate accounts and regular personal riders

{{ config(materialized='table', tags=["finance"]) }}

select
    date_trunc(pickup_at, month) as trip_month,

    -- This flag indicates which one is corporate and personal
    case
        when corporate_trip_flag then 'corporate'
        else 'personal'
    end as trip_type,

    count(trip_id) as total_trips,

    -- Gross revenue before deductions, for personal and corporate
    sum(actual_fare) as gross_revenue,

    -- Net revenue retained, for personal and corporate
        sum(net_revenue) as net_revenue

from {{ ref('fact_trips') }}
where trip_status = 'completed'

group by 1, 2