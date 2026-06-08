{{ config(
    materialized='table',
    schema='warehouse'
) }}

with staging_flights as (
    select * from {{ ref('stg_flight') }}
),

mapped_statuses as (
    select
        cancelled ::BOOLEAN as cancelled,
        diverted ::BOOLEAN as diverted,
        
        case 
            when not coalesce(cancelled, false) then 'Not Cancelled'
            when cancellation_reason is null then 'Unknown'
            when cancellation_reason = 'A' then 'Airline/Carrier'
            when cancellation_reason = 'B' then 'Weather'
            when cancellation_reason = 'C' then 'National Air System'
            when cancellation_reason = 'D' then 'Security'
        end ::VARCHAR(19) as cancellation_reason,

        case
            when cancelled then 'Not applicable - cancelled'
            when diverted then 'Not applicable - diverted'
            when arr_delay_minutes is null then 'Unknown'
            when arr_delay_minutes >= 15 then 'Delayed 15 or more'
            else 'On Time'
        end ::VARCHAR(26) as arrival_delay_status

    from staging_flights
),

distinct_statuses as (
    select distinct
        cancelled,
        diverted,
        cancellation_reason,
        arrival_delay_status
    from mapped_statuses
)

select
    row_number() over (order by cancelled, diverted, cancellation_reason, arrival_delay_status) as flight_status_id,

    md5(
        concat_ws('|', 
            cancelled::text, 
            diverted::text, 
            cancellation_reason, 
            arrival_delay_status
        )
    )::VARCHAR(32) as flight_status_hash,

    cancelled ::BOOLEAN as cancelled,
    diverted ::BOOLEAN as diverted,
    cancellation_reason ::VARCHAR(19) as cancellation_reason,
    arrival_delay_status ::VARCHAR(26) as arrival_delay_status

from distinct_statuses
