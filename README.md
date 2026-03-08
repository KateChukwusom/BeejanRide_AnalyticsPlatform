## BeejanRide dbt Analytics Platform

End-to-end data transformation pipeline for BeejanRide, a ride-hailing platform. Built with dbt on Snowflake, this project transforms raw operational data into analytics-ready models for finance, operations, and fraud monitoring teams.

## Project Overview
Raw transactional data is ingested from a Postgres database into Snowflake's raw schema using Airbyte. 
dbt then transforms this data through three layers. 
Domain-specific aggregate marts are then built on top of fct__trips and organised into three schemas — finance, operations, and fraud.

# Source Layer
The Source layer represents the raw data ingested from operational systems into the warehouse. These tables are loaded directly into Snowflake without transformation and serve as the foundation for the entire analytics pipeline.

- Key characteristics:
Raw ingestion from application databases
Minimal transformation
Used as the starting point for all dbt models
Defined using sources.yml in dbt

Source tables include:
trips_raw

payments_raw

drivers_raw

riders_raw

cities_raw

driver_status_events_raw

# Staging Layer
The Staging layer standardizes and prepares raw data for downstream transformations. Models in this layer are typically implemented as views and focus on renaming columns, basic validation, and light transformations.

- Responsibilities of the staging layer:
Standardize column naming conventions

Handle simple derived fields

Filter or clean invalid records

Maintain a one-to-one relationship with source tables

Staging models include:
stg__trips

stg__payments

stg__drivers

stg__riders

stg__cities

stg__driver_status_events

This layer ensures that downstream models interact with clean, consistently structured data.

# Intermediate Layer
The Intermediate layer contains enriched models that apply business logic and more complex transformations. These models combine multiple staging tables and compute analytical features using derived columns and window functions.

Responsibilities:
Join staging models

Implement business logic

Calculate derived metrics

Compute window functions

Intermediate models include:

int__trips_enriched

int__drivers_enriched

int__riders_enriched

Examples of calculations performed in this layer include:
trip_duration_minutes

driver_lifetime_trips

rider_lifetime_value

fraud_indicators

duplicate_trip_payments

The intermediate layer prepares data for the dimensional model while keeping the logic modular and reusable.

4. Core Layer (Dimensional Model)

The Core layer implements the warehouse’s star schema, which serves as the central analytical data model.

The model consists of a fact table surrounded by several dimension tables.

Fact Table:

fact_trips

Dimension Tables:

dim_drivers

dim_riders

dim_cities

fact_trips captures transactional ride data at the trip level and includes key metrics such as:

actual_fare

net_revenue

trip_duration_minutes

surge_multiplier

driver_lifetime_trips

rider_lifetime_value

Dimension tables store descriptive attributes about riders, drivers, and cities.

This star schema design supports efficient analytical queries and simplifies BI reporting.

5. Mart Layer

The Mart layer provides aggregated data tailored to specific business domains such as finance, operations, and fraud monitoring.

All mart models are derived from the fact_trips table.

Finance marts:

daily_revenue_by_city

gross_vs_net_revenue

corporate_vs_personal

payment_failure_rate

Operations marts:

driver_activity

driver_leaderboard

driver_churn_tracking

surge_impact

rider_ltv

Fraud mart:

fraud_monitoring

These marts enable business teams to analyze operational performance, revenue trends, driver activity, and potential fraudulent behavior.

Summary

The layered architecture ensures:

Clear separation of responsibilities

Reusable transformations

Scalable data modeling

Transparent data lineage

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

