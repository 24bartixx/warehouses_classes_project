{{ config(
    materialized='view',
    schema='staging'
) }}

select
    row_number() over (order by iata_code) as airport_id,
    iata_code as iata_code,
    airport as airport_name,
    city as city,
    state as state,
    country as country,
    latitude as latitude,
    longitude as longitude
from {{ ref('airports') }}
