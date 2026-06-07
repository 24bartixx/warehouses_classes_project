{{ config(
    materialized='incremental',
    incremental_strategy='delete+insert',
    unique_key=['flight_number', 'scheduled_departure_timestamp'],
    schema='intermediate'
) }}

with flights as (
    select * from {{ ref('stg_flight') }}
    
    {% if is_incremental() %}
    where scheduled_arrival_timestamp >= (
        select max(scheduled_arrival_timestamp) - interval '14 day' 
        from {{ this }}
    )
    {% endif %}
),

bts_map as (
    select bts_airport_id, iata_code 
    from {{ ref('stg_bts_airport_map') }}
)

select
    f.*, 
    coalesce(mo_iata.iata_code, mo_id.iata_code) as origin_airport_iata,
    coalesce(md_iata.iata_code, md_id.iata_code) as destination_airport_iata,
    coalesce(mo_iata.bts_airport_id, mo_id.bts_airport_id) as origin_bts_airport_id,
    coalesce(md_iata.bts_airport_id, md_id.bts_airport_id) as destination_bts_airport_id

from flights f

-- origins
left join bts_map mo_iata
    on f.origin_airport_code = mo_iata.iata_code

left join bts_map mo_id
    on try_cast(f.origin_airport_code as smallint) = mo_id.bts_airport_id

-- destinations
left join bts_map md_iata
    on f.destination_airport_code = md_iata.iata_code

left join bts_map md_id
    on try_cast(f.destination_airport_code as smallint) = md_id.bts_airport_id