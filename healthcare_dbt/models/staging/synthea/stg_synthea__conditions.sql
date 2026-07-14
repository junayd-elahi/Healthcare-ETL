

with source as (

    select * from {{ source('synthea', 'CONDITIONS') }}

),

renamed as (

    select
        CAST ("START" AS date) AS start_date,
        CAST("STOP" AS date) AS stop_date,
        patient AS patient_id,
        encounter AS encounter_id,
        system,
        code,
        description

    from source

)

select * from renamed

