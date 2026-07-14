

with source as (

    select * from {{ source('synthea', 'SUPPLIES') }}

),

renamed as (

    select
        CAST ("DATE" AS date) AS supply_date,
        patient AS patient_id,
        encounter AS encounter_id,
        code,
        description,
        CAST ("QUANTITY" AS int) AS quantity

    from source

)

select * from renamed

