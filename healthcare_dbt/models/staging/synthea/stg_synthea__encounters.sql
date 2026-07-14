

with source as (

    select * from {{ source('synthea', 'ENCOUNTERS') }}

),

renamed as (

    select
        "Id" AS encounter_id,
        CAST ("START" AS TIMESTAMP_TZ) AS start_timestamp,
        CAST ("STOP" AS TIMESTAMP_TZ) AS stop_timestamp,
        patient AS patient_id,
        organization AS organization_id,
        provider AS provider_id,
        payer AS payer_id,
        encounterclass AS encounter_class,
        code,
        description,
        CAST("BASE_ENCOUNTER_COST" AS DECIMAL(12, 2)) AS base_encounter_cost,
        CAST ("TOTAL_CLAIM_COST" AS DECIMAL(12, 2)) AS total_claim_cost,
        CAST ("PAYER_COVERAGE" AS DECIMAL(12, 2)) AS payer_coverage,
        reasoncode AS reason_code,
        reasondescription AS reason_description

    from source

)

select * from renamed

