

with source as (

    select * from {{ source('synthea', 'IMMUNIZATIONS') }}

),

renamed as (

    select
        CAST ("DATE" AS TIMESTAMP_TZ) AS immunization_timestamp,
        patient AS patient_id,
        encounter AS encounter_id,
        code,
        description,
        CAST ("BASE_COST" AS DECIMAL(12, 2)) AS base_cost

    from source

)

select * from renamed

