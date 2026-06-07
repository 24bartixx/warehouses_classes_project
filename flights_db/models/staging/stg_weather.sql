{{ config(
    materialized='view',
    schema='staging'
) }}

select
    upper(trim(airport)) ::VARCHAR(3) as airport_iata,
    valid::TIMESTAMP as valid_at,
    elevation::SMALLINT as airport_elevation,

    tmpc ::NUMERIC as temperature_celsius,
    sped ::NUMERIC as wind_speed_mph,
    gust_mph ::NUMERIC as gust_speed_mph,
    p01m ::NUMERIC as precipitation_1h,
    snowdepth ::NUMERIC as snowdepth,
    vsby ::NUMERIC as visibility_miles,
    ice_accretion_1hr ::NUMERIC as ice_accretion_1hr,

    coalesce(upper(trim(wxcodes)), '') as weather_codes
    
from {{ source('raw_data', 'weather') }}
