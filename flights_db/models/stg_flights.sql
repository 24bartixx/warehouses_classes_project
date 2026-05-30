{{ config(
    materialized='view',
    schema='staging'
) }}

select
    row_number() over (
        order by year, month, day, airline, flight_number, origin_airport, destination_airport
    ) as flight_id,
    year as year,
    month as month,
    day as day,
    day_of_week as day_of_week,
    airline as airline_name,
    flight_number as flight_number,
    tail_number as tail_number,
    origin_airport as origin_airport_iata,
    destination_airport as destination_airport_iata,
    scheduled_departure as scheduled_departure,
    scheduled_arrival as scheduled_arrival,
    departure_delay as departure_delay,
    arrival_delay as arrival_delay,
    scheduled_time as scheduled_time,
    elapsed_time as elapsed_time,
    air_time as air_time,
    distance as distance,
    diverted as diverted,
    cancelled as cancelled,
    cancellation_reason as cancellation_reason,
    air_system_delay as air_system_delay,
    security_delay as security_delay,
    airline_delay as airline_delay,
    late_aircraft_delay as late_aircraft_delay,
    weather_delay as weather_delay
from {{ source('raw_data', 'flights') }}
