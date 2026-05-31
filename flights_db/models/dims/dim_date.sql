{{ config(
    materialized='table',
    schema='marts'
) }}

with staging_flights as (
    select * from {{ ref('stg_flight') }} 
),

unique_dates as (
    select 
        year,
        month,
        day,
        day_of_week
    from staging_flights
    where year is not null and month is not null and day is not null
    group by 1, 2, 3, 4 
)

select
    concat(
        cast(year as varchar(4)), 
        lpad(cast(month as varchar(2)), 2, '0'), 
        lpad(cast(day as varchar(2)), 2, '0')
    ) ::varchar(8) as date_id,
    
    year,

    case 
        when month between 1 and 3 then 1
        when month between 4 and 6 then 2
        when month between 7 and 9 then 3
        else 4
    end as quarter,

    month,
    case
        when month = 1 then 'January'
        when month = 2 then 'February'
        when month = 3 then 'March'
        when month = 4 then 'April'
        when month = 5 then 'May'
        when month = 6 then 'June'
        when month = 7 then 'July'
        when month = 8 then 'August'
        when month = 9 then 'September'
        when month = 10 then 'October'
        when month = 11 then 'November'
        else 'December'
    end ::varchar(9) as month_name,

    day,

    day_of_week,
    case
        when day_of_week = 1 then 'Monday'
        when day_of_week = 2 then 'Tuesday'
        when day_of_week = 3 then 'Wednesday'
        when day_of_week = 4 then 'Thursday'
        when day_of_week = 5 then 'Friday'
        when day_of_week = 6 then 'Saturday'
        else 'Sunday'
    end ::varchar(9) as day_of_week_name

from unique_dates