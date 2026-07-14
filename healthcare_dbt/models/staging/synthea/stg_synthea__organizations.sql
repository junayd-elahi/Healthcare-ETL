

with source as (

    select * from {{ source('synthea', 'ORGANIZATIONS') }}

),

renamed as (

    select
        "Id" AS organization_id,
        name AS organization_name,
        address,
        city,
        state,
        zip,
        CAST ("LAT" AS FLOAT) AS latitude,
        CAST ("LON" AS FLOAT) AS longitude,
        phone,
        CAST ("REVENUE" AS DECIMAL(12, 2)) AS revenue,
        CAST ("UTILIZATION" AS int) AS utilization

    from source

)

select * from renamed

