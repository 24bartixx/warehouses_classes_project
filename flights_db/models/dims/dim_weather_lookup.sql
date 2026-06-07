{{ config(
    materialized='incremental',
    unique_key='weather_id',
    incremental_strategy='merge',
    schema='warehouse'
) }}

with int_weather_lookup as (
    select * from {{ ref('int_weather_lookup') }}
)


select distinct
    weather_id,    

    temp_range,
    wind_speed_range,
    gust_speed_range,
    precipitation_range,
    snow_depth_range,
    visibility_range,
    ice_accretion_1h_range,

    is_thunderstorm,
    is_rain,
    is_freezing_precipitation,
    is_snow,
    is_heavy_snow,
    is_fog,
    is_extreme_weather_hazard

from int_weather_lookup w
