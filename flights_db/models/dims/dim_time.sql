{{ config(
    materialized='table',
    schema='warehouse'
) }}

with staging_flights as (
    select * from {{ ref('stg_flight') }} 
),

unique_times as (
    select scheduled_departure_time as time_id from staging_flights where scheduled_departure_time is not null
    union 
    select scheduled_arrival_time as time_id from staging_flights where scheduled_arrival_time is not null
)

select
    time_id as time_id,
    (time_id // 100) :: SMALLINT as hour,
    (time_id % 100) :: SMALLINT as minute,
    case 
        when time_id is null then 'Unknown'
        when time_id >= 600 and time_id < 900 then 'Morning (06-09)'
        when time_id >= 900 and time_id < 1700 then 'Midday (09-17)'
        when time_id < 2200 then 'Evening (17-22)'
        else 'Night (22-06)'
    end ::VARCHAR(15) as time_of_day

from unique_times
