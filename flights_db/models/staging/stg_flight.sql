{{ config(
    materialized='view',
    schema='staging'
) }}

select
    upper(trim(flight_number :: VARCHAR(5))) ::VARCHAR(5) as flight_number,

    {# foreign keys #}
    trim(airline) ::VARCHAR(32) as airline_iata_code,
    coalesce(upper(trim(tail_number)), 'Unknown') ::VARCHAR(7) as tail_number,
    upper(trim(origin_airport)) ::VARCHAR(5) as origin_airport_code,
    upper(trim(destination_airport)) ::VARCHAR(5) as destination_airport_code,

    {# times #}
    scheduled_departure ::SMALLINT as scheduled_departure_time,
    scheduled_arrival ::SMALLINT as scheduled_arrival_time,

    {# departure timestamp #}
    (make_date(year::INT, month::INT, day::INT) + 
     make_time(
         (scheduled_departure::INT // 100)::BIGINT, 
         (scheduled_departure::INT % 100)::BIGINT,   
         0.0::DOUBLE
     )) ::TIMESTAMP as scheduled_departure_timestamp,

    {# arrival timestamp #}
    (
        make_date(year::INT, month::INT, day::INT) + 
        make_time(
            (scheduled_arrival::INT // 100)::BIGINT, 
            (scheduled_arrival::INT % 100)::BIGINT, 
            0.0::DOUBLE
        ) +
        case 
            when scheduled_arrival::INT < scheduled_departure::INT then INTERVAL '1 day' 
            else INTERVAL '0 day' 
        end
    ) ::TIMESTAMP as scheduled_arrival_timestamp,

    upper(trim(cancellation_reason)) ::VARCHAR(1) as cancellation_reason,

    {# metrics #}
    departure_delay ::SMALLINT as dept_delay_minutes,
    arrival_delay ::SMALLINT as arr_delay_minutes,
    air_system_delay ::SMALLINT as air_system_delay_minutes,
    security_delay ::SMALLINT as security_delay_minutes,
    airline_delay ::SMALLINT as airline_delay_minutes,
    late_aircraft_delay ::SMALLINT as late_aircraft_delay_minutes,
    weather_delay ::SMALLINT as weather_delay_minutes,
    scheduled_time ::SMALLINT as scheduled_time_minutes,
    elapsed_time ::SMALLINT as elapsed_time_minutes,
    air_time ::SMALLINT as air_time_minutes,
    distance ::SMALLINT as distance,
    diverted ::BOOLEAN as diverted,
    cancelled ::BOOLEAN as cancelled

from {{ source('raw_data', 'flights') }} 
