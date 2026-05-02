-- This presents the monthly view of how much revenue is retained compared to whole resource

{{ config(materialized='table', tags=["finance"]) }}

select
    date_trunc(pickup_at, month) as trip_month,
    sum(actual_fare) as gross_revenue,

    -- Revenue after driver payouts and processing fees
    sum(net_revenue) as net_revenue,

    -- This calculates the driver's fee plus processing fee
    sum(actual_fare - net_revenue) as total_deductions

from {{ ref('fact_trips') }}
where trip_status = 'completed'
group by 1