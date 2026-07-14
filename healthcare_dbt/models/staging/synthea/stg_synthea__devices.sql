

with source as (

    select * from {{ source('synthea', 'DEVICES') }}

),

renamed as (

    select
        CAST ("START" AS TIMESTAMP_TZ) AS start_timestamp,
        CAST ("STOP" AS TIMESTAMP_TZ) AS stop_timestamp,
        patient AS patient_id,
        encounter AS encounter_id,
        code,
        description,
        udi

    from source

)

select * from renamed

