{{ config(
    materialized='view',
    schema='staging'
) }}

select
    row_number() over (order by airport, station, valid) as weather_id,
    airport as airport_iata,
    state as state,
    network as network,
    station as station,
    valid as valid_at,
    elevation as elevation,
    tmpc as temperature_celsius,
    sped as wind_speed,
    p01m as precipitation,
    vsby as visibility,
    gust_mph as wind_gust_mph,
    wxcodes as weather_codes,
    ice_accretion_1hr as ice_accretion_1hr,
    snowdepth as snow_depth
from {{ source('raw_data', 'weather') }}
