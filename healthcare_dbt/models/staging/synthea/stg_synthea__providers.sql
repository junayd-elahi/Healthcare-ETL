

with source as (

    select * from {{ source('synthea', 'PROVIDERS') }}

),

renamed as (

    select
        "Id" AS provider_id,
        organization AS organization_id,
        name AS provider_name,
        gender,
        speciality,
        address,
        city,
        state,
        zip,
        CAST ("LAT" AS FLOAT) AS latitude,
        CAST ("LON" AS FLOAT) AS longitude,
        CAST ("ENCOUNTERS" AS INT) AS encounters,
        CAST ("PROCEDURES" AS INT) AS procedures

    from source

)

select * from renamed

