{{ config(
    materialized='table',
    schema='marts'
) }}

with staging_airports as (
    select * from {{ ref('stg_airport') }} 
),

weather_elevation as (
    select 
        airport_iata,
        max(airport_elevation) as elevation
    from {{ ref('stg_weather') }}
    group by airport_iata
)

select
    row_number() over (order by iata_code) as airport_id,
    iata_code,
    airport_name,
    state_name,
    city,
    latitude_zone,
    longitude_zone,
    elevation

from staging_airports sa
left join weather_elevation we
    on sa.iata_code = we.airport_iata