{{ config(
    materialized='view',
    schema='staging'
) }}

select
    upper(trim(airport)) ::VARCHAR(3) as airport_iata,
    valid::TIMESTAMP as valid_at,
    elevation::SMALLINT as airport_elevation,

    case
        when tmpc is null then 'Unknown'
        when tmpc < 0 then 'below_zero'
        when tmpc < 5 then '0_to_5'
        when tmpc < 10 then '5_to_10'
        when tmpc < 20 then '10_to_20'
        else 'above_20'
    end::VARCHAR(10) as temp_range,

    case
        when sped is null then 'Unknown'
        when sped < 10 then 'below_10'
        when sped < 25 then '10_to_25'
        when sped < 50 then '25_to_50'
        else 'above_50'
    end ::VARCHAR(8) as wind_speed_range,

    case
        when gust_mph is null then 'Unknown'
        when gust_mph < 30 then 'below_30'
        when gust_mph < 80 then '30_to_80'
        else 'above_80'
    end ::VARCHAR(8) as gust_speed_range,

    case
        when p01m is null then 'Unknown'
        when p01m < 3 then 'below_3'
        when p01m < 8 then '3_to_8'
        when p01m < 20 then '8_to_20'
        else 'above_20'
    end ::VARCHAR(8) as precipitation_range,

    case
        when snowdepth is null or trim(snowdepth) = '' or trim(snowdepth) ilike 'nan' then 'Unknown'
        when snowdepth ::NUMERIC < 0.5 then 'below_05'
        when snowdepth ::NUMERIC < 1 then '05_to_1'
        else 'above_1'
    end ::VARCHAR(8) as snow_depth_range,

    {# no need to map miles above 200 to 200 #}
    case
        when vsby is null then 'Unknown'
        when vsby < 0.4 then 'below_04'
        when vsby < 1 then '04_to_1'
        when vsby < 3 then '1_to_3'
        else 'above_3'
    end ::VARCHAR(8) as visibility_range,

    case
        when ice_accretion_1hr is null or trim(ice_accretion_1hr) = '' 
            or trim(ice_accretion_1hr) ilike 'nan' then 'Unknown'
        when ice_accretion_1hr ::NUMERIC is null then 'Unknown'
        when ice_accretion_1hr ::NUMERIC < 0.01 then 'below_001'
        when ice_accretion_1hr ::NUMERIC < 0.1 then '001_to_01'
        when ice_accretion_1hr ::NUMERIC < 0.25 then '01_to_025'
        else 'above_025'
    end ::VARCHAR(9) as ice_accretion_1h_range,

    {# thunderstorm / squall (nawałnica) #}
    case
        when upper(trim(wxcodes)) like '%TS%' or upper(trim(wxcodes)) like '%SQ%' then true
        else false
    end as is_thunderstorm,

    {# rain #}
    case when upper(trim(wxcodes)) like '%RA%' then true else false end as is_rain,

    {# freezing precipitation #}
    case
        when upper(trim(wxcodes)) like '%FZ%' or upper(trim(wxcodes)) like '%PL%' then true
        else false
    end as is_freezing_precipitation,

    {# snow #}
    case when upper(trim(wxcodes)) like '%SN%' then true else false end as is_snow,

    {# heavy snow #}
    case
        when upper(trim(wxcodes)) like '%+SN%' or upper(trim(wxcodes)) like '%BLSN%' then true
        else false
    end as is_heavy_snow,

    {# fog #}
    case
        when upper(trim(wxcodes)) like '%FG%' then true
        else false
    end as is_fog,

    {# extreme weather hazard #}
    case
        when upper(trim(wxcodes)) like '%VA%' or upper(trim(wxcodes)) like '%FC%' then true
        else false
    end as is_extreme_weather_hazard

from {{ source('raw_data', 'weather') }}
