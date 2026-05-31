{{ config(
    materialized='table',
    schema='marts'
) }}

with staging_flights as (
    select * from {{ ref('stg_flight') }} 
),

distinct_aircrafts as (
    select distinct tail_number
    from staging_flights
    where tail_number is not null 
)

select
    row_number() over (order by tail_number) as aircraft_id,
    tail_number
from distinct_aircrafts