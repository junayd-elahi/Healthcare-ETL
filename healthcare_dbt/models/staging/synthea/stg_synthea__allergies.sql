with source as (

    select * from {{ source('synthea', 'ALLERGIES') }}
),

renamed as (
    select
        cast("START" AS date) AS start_date,
        cast("STOP" AS date) AS stop_date,
        patient as patient_id,
        encounter as encounter_id,
        code,
        system,
        description,
        type,
        category,
        reaction1,
        description1,
        severity1,
        reaction2,
        description2,
        severity2
    from source

)

select * from renamed