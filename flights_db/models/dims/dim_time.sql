{{ config(
    materialized='table',
    schema='marts'
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
    time_id :: SMALLINT as time_id,
    (time_id / 100) :: SMALLINT as hour,
    (time_id % 100) :: SMALLINT as minute

from unique_times