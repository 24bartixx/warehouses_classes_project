{{ config(
    materialized='table',
    schema='marts'
) }}

with staging_airports as (
    select * from {{ ref('stg_airport') }} 
),

weather_elevation as (
    select 
        airport_iata,
        max(airport_elevation) as elevation
    from {{ ref('stg_weather') }}
    group by airport_iata
)

select
    md5(sa.iata_code) ::VARCHAR(32) as airport_id,
    sa.iata_code,
    bts.bts_airport_id,
    sa.airport_name,

    case upper(trim(state))
        when 'AK' then 'Alaska'
        when 'AL' then 'Alabama'
        when 'AR' then 'Arkansas'
        when 'AS' then 'American Samoa'
        when 'AZ' then 'Arizona'
        when 'CA' then 'California'
        when 'CO' then 'Colorado'
        when 'CT' then 'Connecticut'
        when 'DE' then 'Delaware'
        when 'FL' then 'Florida'
        when 'GA' then 'Georgia'
        when 'GU' then 'Guam'
        when 'HI' then 'Hawaii'
        when 'IA' then 'Iowa'
        when 'ID' then 'Idaho'
        when 'IL' then 'Illinois'
        when 'IN' then 'Indiana'
        when 'KS' then 'Kansas'
        when 'KY' then 'Kentucky'
        when 'LA' then 'Louisiana'
        when 'MA' then 'Massachusetts'
        when 'MD' then 'Maryland'
        when 'ME' then 'Maine'
        when 'MI' then 'Michigan'
        when 'MN' then 'Minnesota'
        when 'MO' then 'Missouri'
        when 'MS' then 'Mississippi'
        when 'MT' then 'Montana'
        when 'NC' then 'North Carolina'
        when 'ND' then 'North Dakota'
        when 'NE' then 'Nebraska'
        when 'NH' then 'New Hampshire'
        when 'NJ' then 'New Jersey'
        when 'NM' then 'New Mexico'
        when 'NV' then 'Nevada'
        when 'NY' then 'New York'
        when 'OH' then 'Ohio'
        when 'OK' then 'Oklahoma'
        when 'OR' then 'Oregon'
        when 'PA' then 'Pennsylvania'
        when 'PR' then 'Puerto Rico'
        when 'RI' then 'Rhode Island'
        when 'SC' then 'South Carolina'
        when 'SD' then 'South Dakota'
        when 'TN' then 'Tennessee'
        when 'TX' then 'Texas'
        when 'UT' then 'Utah'
        when 'VA' then 'Virginia'
        when 'VI' then 'U.S. Virgin Islands'
        when 'VT' then 'Vermont'
        when 'WA' then 'Washington'
        when 'WI' then 'Wisconsin'
        when 'WV' then 'West Virginia'
        when 'WY' then 'Wyoming'
    end::VARCHAR(25) as state_name,

    sa.city,
    we.elevation,

    case
        when sa.latitude < 25 then 'South to USA'
        when sa.latitude < 35 and sa.latitude >= 25 then 'Southern USA'
        when sa.latitude < 42 and sa.latitude >= 35 then 'Middle USA'
        when sa.latitude < 49 and sa.latitude >= 42 then 'Northern USA'
        when sa.latitude >= 49 then 'Far North'
        else 'Unknown'
    end ::VARCHAR(12) as latitude_zone,

    case
        when sa.longitude < -125 then 'Far West Coast'
        when sa.longitude < -115 and sa.longitude >= -125 then 'West Coast'
        when sa.longitude < -85 and sa.longitude >= -115 then 'Central USA'
        when sa.longitude >= -85 then 'East Coast'
        else 'Unknown'
    end ::VARCHAR(14) as longitude_zone

from staging_airports sa
left join weather_elevation we
    on sa.iata_code = we.airport_iata
left join {{ ref('stg_bts_airport_map') }} bts
    on sa.iata_code = bts.iata_code