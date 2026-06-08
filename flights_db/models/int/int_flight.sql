{{ config(
    materialized='incremental',
    incremental_strategy='delete+insert',
    unique_key=['flight_number', 'scheduled_departure_timestamp'],
    schema='intermediate'
) }}

with flights as (
    select * from {{ ref('stg_flight') }}
    
    {% if is_incremental() %}
    where scheduled_arrival_timestamp >= (
        select max(scheduled_arrival_timestamp) - interval '14 day' 
        from {{ this }}
    )
    {% endif %}
),

bts_map as (
    select bts_airport_id, iata_code 
    from {{ ref('stg_bts_airport_map') }}
),

flights_with_statuses as (
    select
        f.*,
        case 
            when not coalesce(f.cancelled, false) then 'Not Cancelled'
            when f.cancellation_reason is null then 'Unknown'
            when f.cancellation_reason = 'A' then 'Airline/Carrier'
            when f.cancellation_reason = 'B' then 'Weather'
            when f.cancellation_reason = 'C' then 'National Air System'
            when f.cancellation_reason = 'D' then 'Security'
        end ::VARCHAR(19) as mapped_cancellation_reason,

        case
            when f.cancelled then 'Not applicable - cancelled'
            when f.diverted then 'Not applicable - diverted'
            when f.arr_delay_minutes is null then 'Unknown'
            when f.arr_delay_minutes >= 15 then 'Delayed 15 or more'
            else 'On Time'
        end ::VARCHAR(26) as mapped_arrival_delay_status
    from flights f
)

select
    f.flight_number,
    f.airline_iata_code,
    f.tail_number,
    f.origin_airport_code,
    f.destination_airport_code,
    f.scheduled_departure_time,
    f.scheduled_arrival_time,
    f.scheduled_departure_timestamp,
    f.scheduled_arrival_timestamp,
    f.cancellation_reason,
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
    f.cancelled,

    md5(
        concat_ws('|', 
            f.cancelled::text, 
            f.diverted::text, 
            f.mapped_cancellation_reason, 
            f.mapped_arrival_delay_status
        )
    )::VARCHAR(32) as flight_status_hash,

    coalesce(mo_iata.iata_code, mo_id.iata_code) as origin_airport_iata,
    coalesce(md_iata.iata_code, md_id.iata_code) as destination_airport_iata,
    coalesce(mo_iata.bts_airport_id, mo_id.bts_airport_id) as origin_bts_airport_id,
    coalesce(md_iata.bts_airport_id, md_id.bts_airport_id) as destination_bts_airport_id

from flights_with_statuses f

-- origins
left join bts_map mo_iata
    on f.origin_airport_code = mo_iata.iata_code

left join bts_map mo_id
    on try_cast(f.origin_airport_code as smallint) = mo_id.bts_airport_id

-- destinations
left join bts_map md_iata
    on f.destination_airport_code = md_iata.iata_code

left join bts_map md_id
    on try_cast(f.destination_airport_code as smallint) = md_id.bts_airport_id