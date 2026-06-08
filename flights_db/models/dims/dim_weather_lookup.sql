{{ config(
    materialized='table',
    schema='warehouse'
) }}

with unique_combinations as (
    select distinct 
        weather_hash,
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
    from {{ ref('int_weather_lookup') }}
)

select 
    row_number() over (order by temp_range, wind_speed_range, precipitation_range) as weather_id,
    *
from unique_combinations