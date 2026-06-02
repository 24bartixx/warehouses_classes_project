{{ config(
    materialized='view',
    schema='staging'
) }}

select
    upper(trim(iata_code)) ::VARCHAR(3) as iata_code,
    trim(airport) ::VARCHAR(100) as airport_name,
    trim(city) ::VARCHAR(50) as city,
    upper(trim(state)) ::VARCHAR(2) as state,

    latitude ::DECIMAL(8,5) as latitude,
    longitude ::DECIMAL(8,5) as longitude

from {{ ref('airports') }}
