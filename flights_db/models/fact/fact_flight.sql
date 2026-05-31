{{ config(
    materialized='table',
    schema='marts'
) }}

with staging_flights as (
    select * from {{ ref('stg_flight') }} 
),

dim_airlines as (
    select * from {{ ref('dim_airline') }} 
),

dim_aircrafts as (
    select * from {{ ref('dim_aircraft') }} 
),

dim_airports as (
    select * from {{ ref('dim_airport') }} 
),

dim_weather_lookup as (
    select * from {{ ref('dim_weather_lookup') }} 
)

select
    row_number() over (order by origin_airport_iata) as origin_airport_id,
    f.flight_number,

    {# airline #}
    sal.airline_id,

    {# aircraft #}
    sac.aircraft_id,
    
    {# origin airport #}
    sapo.airport_id as origin_airport_id,

    {# destination airport #}
    sadd.airport_id as destination_airport_id,

    {# departure #}
    f.scheduled_departure_date,
    f.scheduled_departure_time,

    {# arrival #}
    f.scheduled_arrival_date,
    f.scheduled_arrival_time,

    {# departure weather lookup #}
    w_orig.weather_id as departure_weather_id,

    {# destination weather lookup #}
    w_dest.weather_id as destination_weather_id,

    {# metrics #}
    f.dept_delay_minutes,
    f.arr_delay_minutes,
    f.air_system_delay_minutes,
    f.security_delay_minutes,
    f.airline_delay_minutes,
    f.late_aircraft_delay_minutes,
    f.weather_delay_minutes,
    f.scheduled_time_minutes,
    f.elapsed_time_minutes,
    f.air_time_minutes,
    f.distance,
    f.diverted,
    f.cancelled

from staging_flights f
left join dim_airlines sal
    on f.airline_name = sal.airline_name
left join dim_aircrafts sac
    on f.tail_number = sac.tail_number
left join dim_airports sapo
    on f.origin_airport_iata = sapo.iata_code
left join dim_airports sadd
    on f.destination_airport_iata = sadd.iata_code
asof join dim_weather_lookup w_orig
    on f.destination_airport_iata = w_orig.airport_iata
    and f.scheduled_departure_timestamp >= w_orig.valid_at
asof join dim_weather_lookup w_dest
    on f.destination_airport_iata = w_dest.airport_iata
    and f.scheduled_arrival_timestamp >= w_dest.valid_at