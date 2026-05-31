{{ config(
    materialized='view',
    schema='staging'
) }}

select
    upper(trim(flight_number :: VARCHAR(5))) ::VARCHAR(5) as flight_number,

    {# foreign keys #}
    year :: SMALLINT as year,
    month :: SMALLINT as month,
    day :: SMALLINT as day,
    day_of_week :: SMALLINT as day_of_week,
    trim(airline) ::VARCHAR(32) as airline_name,
    coalesce(upper(trim(tail_number)), 'Unknown') ::VARCHAR(7) as tail_number,
    upper(trim(origin_airport)) ::VARCHAR(3) as origin_airport_iata,
    upper(trim(destination_airport)) ::VARCHAR(3) as destination_airport_iata,
    scheduled_departure ::SMALLINT as scheduled_departure,
    scheduled_arrival ::SMALLINT as scheduled_arrival,

    case 
        when cancelled = 0 or cancellation_reason is null then 'Not Cancelled'
        when upper(trim(cancellation_reason)) = 'A' then 'Airline/Carrier'
        when upper(trim(cancellation_reason)) = 'B' then 'Weather'
        when upper(trim(cancellation_reason)) = 'C' then 'National Air System'
        when upper(trim(cancellation_reason)) = 'D' then 'Security'
    end ::VARCHAR(19) as cancellation_reason,

    case
        when cancelled = 1 then 'NOT APPLICABLE - CANCELLED'
        when diverted = 1 then 'NOT APPLICABLE - DIVERTED'
        when arrival_delay is null then 'UNKNOWN'
        when arrival_delay >= 15 then 'DELAYED_15_OR_MORE'
        else 'ON_TIME'
    end ::VARCHAR(26) as arrival_delay_status,

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
