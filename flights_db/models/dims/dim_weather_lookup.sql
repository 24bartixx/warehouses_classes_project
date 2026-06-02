{{ config(
    materialized='table',
    schema='marts'
) }}

with staging_weather as (
    select * from {{ ref('stg_weather') }} 
),

staging_flights as (
    select * from {{ ref('stg_flight') }}
),

flight_times as (
    select origin_airport_iata as airport_iata, scheduled_departure_timestamp as flight_time
    from staging_flights
    union
    select destination_airport_iata as airport_iata, scheduled_arrival_timestamp as flight_time
    from staging_flights
),

closest_weather as (
    select distinct
        w.airport_iata,
        w.valid_at
    from flight_times ft
    asof left join staging_weather w
        on ft.airport_iata = w.airport_iata
        and ft.flight_time >= w.valid_at
)

select
    md5(w.airport_iata || '|' || w.valid_at) ::VARCHAR(32) as weather_id,

    w.airport_iata,
    w.valid_at,
    
    case
        when temperature_celsius is null then 'Unknown'
        when temperature_celsius < 0 then 'below_zero'
        when temperature_celsius < 5 then '0_to_5'
        when temperature_celsius < 10 then '5_to_10'
        when temperature_celsius < 20 then '10_to_20'
        else 'above_20'
    end::VARCHAR(10) as temp_range,

    case
        when wind_speed_mph is null then 'Unknown'
        when wind_speed_mph < 10 then 'below_10'
        when wind_speed_mph < 25 then '10_to_25'
        when wind_speed_mph < 50 then '25_to_50'
        else 'above_50'
    end ::VARCHAR(8) as wind_speed_range,

    case
        when gust_speed_mph is null then 'Unknown'
        when gust_speed_mph < 30 then 'below_30'
        when gust_speed_mph < 80 then '30_to_80'
        else 'above_80'
    end ::VARCHAR(8) as gust_speed_range,

    case
        when precipitation_1h is null then 'Unknown'
        when precipitation_1h < 3 then 'below_3'
        when precipitation_1h < 8 then '3_to_8'
        when precipitation_1h < 20 then '8_to_20'
        else 'above_20'
    end ::VARCHAR(8) as precipitation_range,

    case
        when snowdepth is null then 'Unknown'
        when snowdepth ::NUMERIC < 0.5 then 'below_05'
        when snowdepth ::NUMERIC < 1 then '05_to_1'
        else 'above_1'
    end ::VARCHAR(8) as snow_depth_range,

    {# no need to map miles above 200 to 200 #}
    case
        when visibility_miles is null then 'Unknown'
        when visibility_miles < 0.4 then 'below_04'
        when visibility_miles < 1 then '04_to_1'
        when visibility_miles < 3 then '1_to_3'
        else 'above_3'
    end ::VARCHAR(8) as visibility_range,

    case
        when ice_accretion_1hr is null then 'Unknown'
        when ice_accretion_1hr ::NUMERIC is null then 'Unknown'
        when ice_accretion_1hr ::NUMERIC < 0.01 then 'below_001'
        when ice_accretion_1hr ::NUMERIC < 0.1 then '001_to_01'
        when ice_accretion_1hr ::NUMERIC < 0.25 then '01_to_025'
        else 'above_025'
    end ::VARCHAR(9) as ice_accretion_1h_range,


    {# thunderstorm / squall (nawałnica) #}
    case
        when upper(trim(weather_codes)) like '%TS%' or upper(trim(weather_codes)) like '%SQ%' then true
        else false
    end as is_thunderstorm,

    {# rain #}
    case when upper(trim(weather_codes)) like '%RA%' then true else false end as is_rain,

    {# freezing precipitation #}
    case
        when upper(trim(weather_codes)) like '%FZ%' or upper(trim(weather_codes)) like '%PL%' then true
        else false
    end as is_freezing_precipitation,

    {# snow #}
    case when upper(trim(weather_codes)) like '%SN%' then true else false end as is_snow,

    {# heavy snow #}
    case
        when upper(trim(weather_codes)) like '%+SN%' or upper(trim(weather_codes)) like '%BLSN%' then true
        else false
    end as is_heavy_snow,

    {# fog #}
    case
        when upper(trim(weather_codes)) like '%FG%' then true
        else false
    end as is_fog,

    {# extreme weather hazard #}
    case
        when upper(trim(weather_codes)) like '%VA%' or upper(trim(weather_codes)) like '%FC%' then true
        else false
    end as is_extreme_weather_hazard

from staging_weather w
inner join closest_weather cw
    on w.airport_iata = cw.airport_iata
    and w.valid_at = cw.valid_at