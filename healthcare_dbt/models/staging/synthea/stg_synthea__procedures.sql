

with source as (

    select * from {{ source('synthea', 'PROCEDURES') }}

),

renamed as (

    select
        CAST ("START" AS TIMESTAMP_TZ) AS start_timestamp,
        CAST ("STOP" AS TIMESTAMP_TZ) AS stop_timestamp,
        patient AS patient_id,
        encounter AS encounter_id,
        system,
        code,
        description,
        CAST ("BASE_COST" AS DECIMAL(12, 2)) AS base_cost,
        reasoncode AS reason_code,
        reasondescription AS reason_description

    from source

)

select * from renamed

