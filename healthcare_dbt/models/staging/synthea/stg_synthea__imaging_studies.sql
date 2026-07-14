

with source as (

    select * from {{ source('synthea', 'IMAGING_STUDIES') }}

),

renamed as (

    select
        "Id" AS imaging_study_id,
        CAST ("DATE" AS TIMESTAMP_TZ) AS imaging_timestamp,
        patient AS patient_id,
        encounter AS encounter_id,
        series_uid,
        bodysite_code,
        bodysite_description,
        modality_code,
        modality_description,
        instance_uid,
        sop_code,
        sop_description,
        procedure_code

    from source

)

select * from renamed

