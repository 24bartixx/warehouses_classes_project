{{ config(
    materialized='view',
    schema='staging'
) }}

select
    upper(trim(iata_code)) ::VARCHAR(2) as iata_code,
    trim(airline) ::VARCHAR(32) as airline_name
from {{ ref('airlines') }}
