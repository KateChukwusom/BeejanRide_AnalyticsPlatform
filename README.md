## BeejanRide dbt Analytics Platform

End-to-end data transformation pipeline for BeejanRide — a ride-hailing platform. Built with dbt on Snowflake, this project transforms raw operational data into analytics-ready models for finance, operations, and fraud monitoring teams.

## Project Overview
Raw transactional data is ingested from a Postgres database into Snowflake's raw schema using Airbyte. 
dbt then transforms this data through three layers. 
The staging layer cleans and standardises each source table. 
The intermediate layer applies business logic and enriches entities — computing metrics like net revenue, rider lifetime value, and fraud indicators. 
These enriched models feed into fct__trips, the central incremental fact table in the marts layer. 
Domain-specific aggregate marts are then built on top of fct__trips and organised into three schemas — finance, operations, and fraud — each powering a specific set of dashboards and analytical use cases.

## Project Structure
```
dbt-beejanride/
├── models/
│   ├── staging/
│   │   ├── _stg_beejanride.yml          
│   │   ├── stg_beejanride__trips.sql
│   │   ├── stg_beejanride__payments.sql
│   │   ├── stg_beejanride__drivers.sql
│   │   ├── stg_beejanride__riders.sql
│   │   ├── stg_beejanride__cities.sql
│   │   └── stg_beejanride__driver_status_events.sql
│   ├── intermediate/
│   │   ├── _int_beejanride.yml
│   │   ├── int__trips_enriched.sql
│   │   ├── int__drivers_enriched.sql
│   │   └── int__riders_enriched.sql
│   └── marts/
│       ├── _mart_beejanride.yml
│       ├── fact_trips.sql
│       ├── dim_drivers.sql
│       ├── dim_riders.sql
│       ├── dim_cities.sql
│       ├── finance/
│       │   ├── mart_daily_revenue_by_city.sql
│       │   ├── mart_gross_vs_net_revenue.sql
│       │   ├── mart_corporate_vs_personal_revenue.sql
│       │   └── mart_payment_failure_rate.sql
│       ├── operations/
│       │   ├── mart_driver_activity.sql
│       │   ├── mart_driver_leaderboard.sql
│       │   ├── mart_driver_churn_tracking.sql
│       │   ├── mart_surge_impact.sql
│       │   └── mart_rider_ltv.sql
│       └── fraud/
│           └── mart_fraud_monitoring.sql
├── tests/
│   └── completed_payments.sql          
├── macros/
│   └── calculate_net_revenue.sql
|   └── generate_schema_name.sql
├── dbt_project.yml
```
## Design Decisions
# 1. Incremental materialisation on fct__trips
fct__trips is materialised as an incremental model using pickup_at as the watermark. Snowflake charges by compute, so running a full refresh of a growing trips table on every dbt run would be costly and slow. Incremental ensures only new trips are processed each run, keeping costs predictable as the platform scales.

# 2. Views for staging and intermediate layers
Staging and intermediate models are materialised as views rather than tables. These layers contain no aggregation and are not queried directly by dashboards, so there is no performance benefit to storing them as tables. Views keep storage costs low and ensure the logic is always evaluated against the latest raw data.

# 3. Tables for mart aggregates
Mart models are materialised as tables because they are queried directly by dashboards. It saves time and it is compute optimized. Pre-computing and storing the aggregations means dashboard queries execute in milliseconds rather than scanning the full fact table on every load.

# 4. Separate schemas per business domain
Mart models are separated into finance, operations, and fraud schemas in Snowflake. This gives each team access only to their domain, makes permission management straightforward, and keeps the warehouse organised as the number of models grows.

## Tradeoffs
## Incremental Loading vs. Simplicity
Making fact_trips and int__trips_enriched incremental reduces Snowflake compute costs significantly at scale. But incremental models are require a reliable 'updated_at' column, and can silently miss late-arriving records,  which is a real risk in a payments and fraud context.

## Keeping detail vs. accidentally duplicating rows
Instead of collapsing rows when calculating driver trip counts and rider spend, I kept every single trip row intact but it caused 8 duplicate rows to sneak in when joining tables together. Because the intermediate models were trip-grained (one row per trip per driver), when you joined on driver_id — which appears multiple times — the join had no way to know which row to pick, so it matched every trip row to every driver row and multiplied them. That's where the 8 duplicates came from.
If the intermediate models had collapsed to one row per driver upfront, the join would have been clean. But you would have lost trip-level detail in the process.
So yes — keeping rows granular is what caused the fan-out after joining.

