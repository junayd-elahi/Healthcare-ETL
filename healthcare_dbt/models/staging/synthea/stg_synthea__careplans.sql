

with source as (

    select * from {{ source('synthea', 'CAREPLANS') }}

),

renamed as (

    select
        "Id" AS careplan_id,
        CAST ("START" AS DATE) AS start_date,
        Cast ("STOP" AS DATE) AS stop_date,
        patient AS patient_id,
        encounter AS encounter_id,
        code,
        description,
        reasoncode AS reason_code,
        reasondescription AS reason_description

    from source

)

select * from renamed

