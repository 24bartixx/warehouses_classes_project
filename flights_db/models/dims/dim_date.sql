{{ config(
    materialized='table',
    schema='warehouse'
) }}

with flight_data as (
    select scheduled_departure_timestamp::DATE as date_day 
    from {{ ref('stg_flight') }} 
    where scheduled_departure_timestamp is not null

    union

    select scheduled_arrival_timestamp::DATE as date_day 
    from {{ ref('stg_flight') }} 
    where scheduled_arrival_timestamp is not null
)

select
    (strftime(date_day, '%Y%m%d'))::int as date_id,
    
    extract(year from date_day)::smallint as year,
    extract(quarter from date_day)::smallint as quarter,
    extract(month from date_day)::smallint as month,
    
    strftime(date_day, '%B')::varchar(9) as month_name,
    
    extract(day from date_day)::smallint as day,
    
    extract(isodow from date_day)::smallint as day_of_week,
    
    strftime(date_day, '%A')::varchar(9) as day_of_week_name,

    case when extract(isodow from date_day) in (6, 7) then true else false end as is_weekend

from flight_data
order by date_day
