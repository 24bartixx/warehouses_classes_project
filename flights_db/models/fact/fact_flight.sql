{{ config(
    materialized='incremental',
    unique_key='flight_id',
    incremental_strategy='merge',
    schema='marts'
) }}

with staging_flights as (
    select * from {{ ref('int_flight') }} 

    {% if is_incremental() %}
    where scheduled_arrival_timestamp >= (
        select max(scheduled_arrival_timestamp) - interval '14 day' 
        from {{ this }}
    )
    {% endif %}
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
        f.origin_airport_iata, 
        f.destination_airport_iata, 
        f.scheduled_departure_timestamp, 
        f.scheduled_arrival_timestamp, 
        f.flight_number
    ))::VARCHAR(32) as flight_id,
    
    f.flight_number,
    f.scheduled_arrival_timestamp,

    {# airline #}
    md5(f.airline_iata_code) ::VARCHAR(32) as airline_id,

    {# aircraft #}
    md5(f.tail_number) ::VARCHAR(32) as aircraft_id,
    
    {# origin airport #}
    md5(f.origin_airport_iata || '|' || f.origin_bts_airport_id) ::VARCHAR(32) as origin_airport_id,

    {# destination airport #}
    md5(f.destination_airport_iata || '|' || f.destination_bts_airport_id) ::VARCHAR(32) as destination_airport_id,

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
asof left join dim_weather_lookup w_orig
    on f.origin_airport_iata = w_orig.airport_iata
    and f.scheduled_departure_timestamp >= w_orig.valid_at
asof left join dim_weather_lookup w_dest
    on f.destination_airport_iata = w_dest.airport_iata
    and f.scheduled_arrival_timestamp >= w_dest.valid_at