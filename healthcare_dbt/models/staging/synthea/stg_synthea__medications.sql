

with source as (

    select * from {{ source('synthea', 'MEDICATIONS') }}

),

renamed as (

    select
        CAST ("START" AS TIMESTAMP_TZ) AS start_timestamp,
        CAST ("STOP" AS TIMESTAMP_TZ) AS stop_timestamp,
        patient AS patient_id,
        payer AS payer_id,
        encounter AS encounter_id,
        code,
        description,
        CAST ("BASE_COST" AS DECIMAL(12, 2)) AS base_cost,
        CAST ("PAYER_COVERAGE" AS DECIMAL(12, 2)) AS payer_coverage,
        CAST ("DISPENSES" AS INT) AS dispenses,
        CAST ("TOTALCOST" AS DECIMAL(12, 2)) AS total_cost,
        reasoncode AS reason_code,
        reasondescription AS reason_description

    from source

)

select * from renamed

