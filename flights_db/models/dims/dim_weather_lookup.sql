{{ config(
    materialized='incremental',
    unique_key='weather_id',
    incremental_strategy='merge',
    schema='marts'
) }}

with staging_weather as (
    select * from {{ ref('stg_weather') }} 
    
    {% if is_incremental() %}
    where valid_at >= (
        select max(valid_at) - interval '14 day' 
        from {{ this }}
    )
    {% endif %}
),

staging_flights as (
    select * from {{ ref('int_flight') }}
    
    {% if is_incremental() %}
    where scheduled_arrival_timestamp >= (
        select max(valid_at) - interval '14 day' 
        from {{ this }}
    )
    {% endif %}
),

deduped_weather as (
    select *
    from staging_weather
    qualify row_number() over (
        partition by airport_iata, valid_at
        order by valid_at
    ) = 1
),

flight_times as (
    select distinct airport_iata, flight_time
    from (
        select origin_airport_iata as airport_iata, scheduled_departure_timestamp as flight_time from staging_flights
        union all
        select destination_airport_iata as airport_iata, scheduled_arrival_timestamp as flight_time from staging_flights
    )
),

closest_weather as (
    select distinct
        w.airport_iata,
        w.valid_at
    from flight_times ft
    asof left join deduped_weather w
        on ft.airport_iata = w.airport_iata
        and ft.flight_time >= w.valid_at
    where w.valid_at is not null
)

select
    md5(w.airport_iata || '|' || w.valid_at) ::VARCHAR(32) as weather_id,

    w.airport_iata,
    w.valid_at,
    
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
        when snowdepth ::NUMERIC < 0.5 then 'Below 0.5 inch'
        when snowdepth ::NUMERIC < 1 then '0.5 to 1 inch'
        else 'Above 1 inch'
    end ::VARCHAR(14) as snow_depth_range,

    {# no need to map miles above 200 to 200 #}
    case
        when visibility_miles is null then 'Unknown'
        when visibility_miles < 0.4 then 'Below 0.4 miles'
        when visibility_miles < 1 then '0.4 to 1 mile'
        when visibility_miles < 3 then '1 to 3 miles'
        else 'Above 3 miles'
    end ::VARCHAR(15) as visibility_range,

    case
        when ice_accretion_1hr is null then 'Unknown'
        when ice_accretion_1hr ::NUMERIC is null then 'Unknown'
        when ice_accretion_1hr ::NUMERIC < 0.01 then 'Below 0.01 inch'
        when ice_accretion_1hr ::NUMERIC < 0.1 then '0.01 inch to 0.1 inch'
        when ice_accretion_1hr ::NUMERIC < 0.25 then '0.1 inch to 0.25 inch'
        else 'Above 0.25 inch'
    end ::VARCHAR(21) as ice_accretion_1h_range,


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

from deduped_weather w
inner join closest_weather cw
    on w.airport_iata = cw.airport_iata
    and w.valid_at = cw.valid_at
