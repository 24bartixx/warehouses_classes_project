{{ config(
    materialized='table',
    schema='warehouse'
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
),

fuzzy_iata_matching as (
    select 
        sa.iata_code,
        we.elevation as fuzzy_elevation,
        levenshtein(sa.iata_code, we.airport_iata) as dist
    from staging_airports sa
    cross join weather_elevation we
    where levenshtein(sa.iata_code, we.airport_iata) = 1
    qualify row_number() over (
        partition by sa.iata_code 
        order by dist asc
    ) = 1
),

city_corrections as (
    select
        upper(trim(state))::VARCHAR(2) as state,
        trim(raw_city)::VARCHAR(50) as raw_city,
        trim(correct_city)::VARCHAR(50) as correct_city
    from {{ ref('city_corrections') }}
),

fuzzy_city_matching as (
    select
        sa.iata_code,
        cc.correct_city,
        levenshtein(lower(sa.city), lower(cc.raw_city)) as dist
    from staging_airports sa
    inner join city_corrections cc
        on sa.state = cc.state
        and levenshtein(lower(sa.city), lower(cc.raw_city)) <= 1
    qualify row_number() over (
        partition by sa.iata_code
        order by dist asc
    ) = 1
)

select
    -- md5(sa.iata_code || '|' || bts.bts_airport_id) ::VARCHAR(32) as airport_id,
    row_number() over (order by sa.iata_code) as airport_id,

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

    coalesce(fc.correct_city, sa.city)::VARCHAR(50) as city,

    case
        when coalesce(we.elevation, fz.fuzzy_elevation) is null then 'Unknown'
        when coalesce(we.elevation, fz.fuzzy_elevation) <= 1000 then 'Lowland (0-1000 ft)'
        when coalesce(we.elevation, fz.fuzzy_elevation) <= 3000 then 'Moderate (1000-3000 ft)'
        when coalesce(we.elevation, fz.fuzzy_elevation) <= 5000 then 'High (3000-5000 ft)'
        else 'Very High (5000+ ft)'
    end::VARCHAR(25) as elevation_range,

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

left join fuzzy_iata_matching fz
    on sa.iata_code = fz.iata_code

left join fuzzy_city_matching fc
    on sa.iata_code = fc.iata_code

left join {{ ref('stg_bts_airport_map') }} bts
    on sa.iata_code = bts.iata_code
