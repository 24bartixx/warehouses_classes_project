{{ config(
    materialized='incremental',
    unique_key=['airport_iata', 'valid_at'],
    incremental_strategy='merge',
    schema='intermediate'
) }}

with staging_weather as (
    select * from {{ ref('stg_weather') }} 

    {% if is_incremental() %}
    where valid_at >= (select max(valid_at) - interval '14 day' from {{ this }})
    {% endif %}
),

deduplicated_weather as (
    select *
    from staging_weather
    qualify row_number() over (
        partition by airport_iata, valid_at
        order by valid_at
    ) = 1
),

categorized_weather as (
    select
        airport_iata,
        valid_at,
        
        case
            when temperature_celsius is null then 'Unknown'
            when temperature_celsius < -5 then 'Below -5°C'
            when temperature_celsius < 0 then '-5°C to 0°C'
            when temperature_celsius < 5 then '0°C to 5°C'
            when temperature_celsius < 10 then '5°C to 10°C'
            when temperature_celsius < 15 then '10°C to 15°C'
            else 'Above 15°C'
        end::VARCHAR(12) as temp_range,

        case
            when wind_speed_mph is null then 'Unknown'
            when wind_speed_mph < 10 then 'Below 10 mph'
            when wind_speed_mph < 25 then '10 mph to 25 mph'
            when wind_speed_mph < 50 then '25 mph to 50 mph'
            else 'Above 50 mph'
        end ::VARCHAR(16) as wind_speed_range,

        case
            when gust_speed_mph is null then 'Unknown'
            when gust_speed_mph < 30 then 'Below 30 mph'
            when gust_speed_mph < 80 then '30 mph to 80 mph'
            else 'Above 80 mph'
        end ::VARCHAR(16) as gust_speed_range,

        case
            when precipitation_1h is null then 'Unknown'
            when precipitation_1h < 3 then 'Below 3 mm'
            when precipitation_1h < 8 then '3 mm to 8 mm'
            when precipitation_1h < 20 then '8 mm to 20 mm'
            else 'Above 20 mm'
        end ::VARCHAR(13) as precipitation_range,

        case
            when snowdepth is null then 'Unknown'
            when snowdepth::NUMERIC < 0.5 then 'Below 0.5 inch'
            when snowdepth::NUMERIC < 1 then '0.5 to 1 inch'
            else 'Above 1 inch'
        end ::VARCHAR(14) as snow_depth_range,

        case
            when visibility_miles is null then 'Unknown'
            when visibility_miles < 0.4 then 'Below 0.4 miles'
            when visibility_miles < 1 then '0.4 to 1 mile'
            when visibility_miles < 3 then '1 to 3 miles'
            else 'Above 3 miles'
        end ::VARCHAR(15) as visibility_range,

        case
            when ice_accretion_1hr is null then 'Unknown'
            when ice_accretion_1hr::NUMERIC < 0.01 then 'Below 0.01 inch'
            when ice_accretion_1hr::NUMERIC < 0.1 then '0.01 inch to 0.1 inch'
            when ice_accretion_1hr::NUMERIC < 0.25 then '0.1 inch to 0.25 inch'
            else 'Above 0.25 inch'
        end ::VARCHAR(21) as ice_accretion_1h_range,

        (
            upper(coalesce(trim(weather_codes), '')) like '%TS%'
            or upper(coalesce(trim(weather_codes), '')) like '%SQ%'
        ) as is_thunderstorm,
        (upper(coalesce(trim(weather_codes), '')) like '%RA%') as is_rain,
        (
            upper(coalesce(trim(weather_codes), '')) like '%FZ%'
            or upper(coalesce(trim(weather_codes), '')) like '%PL%'
        ) as is_freezing_precipitation,
        (upper(coalesce(trim(weather_codes), '')) like '%SN%') as is_snow,
        (
            upper(coalesce(trim(weather_codes), '')) like '%+SN%'
            or upper(coalesce(trim(weather_codes), '')) like '%BLSN%'
        ) as is_heavy_snow,
        (upper(coalesce(trim(weather_codes), '')) like '%FG%') as is_fog,
        (
            upper(coalesce(trim(weather_codes), '')) like '%VA%'
            or upper(coalesce(trim(weather_codes), '')) like '%FC%'
        ) as is_extreme_weather_hazard

    from deduplicated_weather
)

select
    md5(
        concat_ws('|', 
            temp_range, wind_speed_range, gust_speed_range, precipitation_range, 
            snow_depth_range, visibility_range, ice_accretion_1h_range, 
            is_thunderstorm::VARCHAR, is_rain::VARCHAR, is_freezing_precipitation::VARCHAR, 
            is_snow::VARCHAR, is_heavy_snow::VARCHAR, is_fog::VARCHAR, is_extreme_weather_hazard::VARCHAR
        )
    )::VARCHAR(32) as weather_id,
    *
from categorized_weather
