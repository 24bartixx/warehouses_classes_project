{{ config(
    materialized='view',
    schema='staging'
) }}

select
    row_number() over (order by iata_code) as airline_id,
    iata_code as iata_code,
    airline as airline_name
from {{ ref('airlines') }}