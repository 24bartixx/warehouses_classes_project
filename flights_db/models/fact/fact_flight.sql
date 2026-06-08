{{ config(
    materialized='incremental',
    unique_key='flight_id',
    incremental_strategy='merge',
    schema='warehouse'
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

dim_dates as (
    select * from {{ ref('dim_date') }}
),

dim_times as (
    select * from {{ ref('dim_time') }}
),

dim_weather_lookup as (
    select * from {{ ref('dim_weather_lookup') }} 
),

int_weather_lookup as (
    select * from {{ ref('int_weather_lookup') }}
)

select
    -- md5(concat_ws('|', 
    --     f.origin_airport_iata, 
    --     f.destination_airport_iata, 
    --     f.scheduled_departure_timestamp, 
    --     f.scheduled_arrival_timestamp, 
    --     f.flight_number
    -- ))::VARCHAR(32) as flight_id,

    row_number() over(order by f.flight_number) as flight_id,
    
    f.flight_number,

    {# airline #}
    a.airline_id,

    {# aircraft #}
    ac.aircraft_id,
    
    {# origin airport #}
    origin_airport.airport_id as origin_airport_id,

    {# destination airport #}
    destination_airport.airport_id as destination_airport_id,

    {# departure #}
    departure_date.date_id as scheduled_departure_date_id,
    departure_time.time_id as scheduled_departure_time_id,

    {# arrival #}
    arrival_date.date_id as scheduled_arrival_date_id,
    arrival_time.time_id as scheduled_arrival_time_id,

    {# departure weather lookup #}
    departure_weather.weather_id as departure_weather_id,

    {# arrival weather lookup #}
    arrival_weather.weather_id as arrival_weather_id,

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
left join dim_airlines a
    on f.airline_iata_code = a.iata_code
left join dim_aircrafts ac
    on f.tail_number = ac.tail_number
left join dim_airports origin_airport
    on f.origin_airport_iata = origin_airport.iata_code
    and f.origin_bts_airport_id = origin_airport.bts_airport_id
left join dim_airports destination_airport
    on f.destination_airport_iata = destination_airport.iata_code
    and f.destination_bts_airport_id = destination_airport.bts_airport_id
left join dim_dates departure_date
    on (strftime(f.scheduled_departure_timestamp::DATE, '%Y%m%d'))::int = departure_date.date_id
left join dim_dates arrival_date
    on (strftime(f.scheduled_arrival_timestamp::DATE, '%Y%m%d'))::int = arrival_date.date_id
left join dim_times departure_time
    on f.scheduled_departure_time = departure_time.time_id
left join dim_times arrival_time
    on f.scheduled_arrival_time = arrival_time.time_id
asof left join int_weather_lookup w_orig
    on f.origin_airport_iata = w_orig.airport_iata
    and f.scheduled_departure_timestamp >= w_orig.valid_at
asof left join int_weather_lookup w_dest
    on f.destination_airport_iata = w_dest.airport_iata
    and f.scheduled_arrival_timestamp >= w_dest.valid_at
left join dim_weather_lookup departure_weather
    on w_orig.weather_hash = departure_weather.weather_hash
left join dim_weather_lookup arrival_weather
    on w_dest.weather_hash = arrival_weather.weather_hash
