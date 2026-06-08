{{ config(
    materialized='table',
    schema='warehouse'
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
    -- md5(tail_number) ::VARCHAR(32) as aircraft_id,
    row_number() over (order by tail_number) as aircraft_id,
    tail_number
from distinct_aircrafts
