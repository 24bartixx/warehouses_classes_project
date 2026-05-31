{{ config(
    materialized='table',
    schema='marts'
) }}

with staging_weather as (
    select * from {{ ref('stg_weather') }} 
),

stagin_flights as (
    select * from {{ ref('stg_flight') }}
),

flight_times as (
    select origin_airport_iata as airport_iata, scheduled_departure_timestamp as flight_time
    from stagin_flights
    union
    select destination_airport_iata as airport_iata, scheduled_arrival_timestamp as flight_time
    from stagin_flights
),

closest_weather as (
    select distinct
        w.airport_iata,
        w.valid_at
    from flight_times ft
    asof join staging_weather w
        on ft.airport_iata = w.airport_iata
        and ft.flight_time >= w.valid_at
)

select
    row_number() over (order by w.airport_iata, w.valid_at) as weather_id,

    w.airport_iata,
    w.valid_at,
    
    w.temp_range,
    w.wind_speed_range,
    w.gust_speed_range,
    w.precipitation_range,
    w.snow_depth_range,
    w.visibility_range,
    w.ice_accretion_1h_range,

    w.is_thunderstorm,
    w.is_rain,
    w.is_freezing_precipitation,
    w.is_snow,
    w.is_heavy_snow,
    w.is_fog,
    w.is_extreme_weather_hazard

from staging_weather w
inner join closest_weather cw
    on w.airport_iata = cw.airport_iata
    and w.valid_at = cw.valid_at