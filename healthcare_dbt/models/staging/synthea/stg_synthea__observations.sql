

with source as (

    select * from {{ source('synthea', 'OBSERVATIONS') }}

),

renamed as (

    select
        CAST ("DATE" AS TIMESTAMP_TZ) AS observation_timestamp,
        patient AS patient_id,
        encounter AS encounter_id,
        category,
        code,
        description,
        value,
        units,
        type

    from source

)

select * from renamed

