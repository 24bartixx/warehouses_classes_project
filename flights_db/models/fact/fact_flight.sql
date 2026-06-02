{{ config(
    materialized='table',
    schema='marts'
) }}

with staging_flights as (
    select * from {{ ref('int_flight') }} 
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
    md5(concat_ws('|', 
        sapo.airport_id, 
        sadd.airport_id, 
        f.scheduled_departure_timestamp, 
        f.scheduled_arrival_timestamp, 
        f.flight_number
    ))::VARCHAR(32) as flight_id,
    
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
    (strftime(f.scheduled_departure_date, '%Y%m%d'))::int as scheduled_departure_date_id,
    f.scheduled_departure_time as scheduled_departure_time_id,

    {# arrival #}
    (strftime(f.scheduled_arrival_date, '%Y%m%d'))::int as scheduled_arrival_date_id,
    f.scheduled_arrival_time as scheduled_arrival_time_id,

    {# departure weather lookup #}
    w_orig.weather_id as departure_weather_id,

    {# arrival weather lookup #}
    w_dest.weather_id as arrival_weather_id,

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
    on f.airline_iata_code = sal.iata_code
left join dim_aircrafts sac
    on f.tail_number = sac.tail_number
left join dim_airports sapo
    on f.origin_airport_iata = sapo.iata_code
left join dim_airports sadd
    on f.destination_airport_iata = sadd.iata_code
asof left join dim_weather_lookup w_orig
    on f.origin_airport_iata = w_orig.airport_iata
    and f.scheduled_departure_timestamp >= w_orig.valid_at
asof left join dim_weather_lookup w_dest
    on f.destination_airport_iata = w_dest.airport_iata
    and f.scheduled_arrival_timestamp >= w_dest.valid_at