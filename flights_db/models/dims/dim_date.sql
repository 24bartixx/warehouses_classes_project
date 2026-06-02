{{ config(
    materialized='table',
    schema='marts'
) }}

with flight_data as (
    select scheduled_departure_date as date_day 
    from {{ ref('stg_flight') }} 
    where scheduled_departure_date is not null

    union

    select scheduled_arrival_date as date_day 
    from {{ ref('stg_flight') }} 
    where scheduled_arrival_date is not null
)

select
    (strftime(date_day, '%Y%m%d'))::int as date_id,
    
    extract(year from date_day)::smallint as year,
    extract(quarter from date_day)::smallint as quarter,
    extract(month from date_day)::smallint as month,
    
    strftime(date_day, '%B')::varchar(9) as month_name,
    
    extract(day from date_day)::smallint as day,
    
    extract(isodow from date_day)::smallint as day_of_week,
    
    strftime(date_day, '%A')::varchar(9) as day_of_week_name

from flight_data
order by date_day