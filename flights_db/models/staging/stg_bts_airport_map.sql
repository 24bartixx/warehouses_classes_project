{{ config(
    materialized='view',
    schema='staging'
) }}

select
    bts_airport_id ::smallint as bts_airport_id,
    bts_airport_code ::varchar(3) as iata_code

from {{ ref('bts_airports_map') }}
