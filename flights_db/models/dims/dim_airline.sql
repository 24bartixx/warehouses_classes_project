{{ config(
    materialized='table',
    schema='warehouse'
) }}

with staging_airlines as (
    select * from {{ ref('stg_airline') }} 
)

select
    -- md5(iata_code) ::VARCHAR(32) as airline_id,
    row_number() over (order by iata_code) as airline_id,
    iata_code,
    airline_name
from staging_airlines
