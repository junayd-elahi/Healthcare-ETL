

with source as (

    select * from {{ source('synthea', 'PAYERS') }}

),

renamed as (

    select
        "Id" AS payer_id,
        name AS payer_name,
        ownership,
        address,
        city,
        state_headquartered,
        zip,
        phone,
        CAST ("AMOUNT_COVERED" AS DECIMAL(12, 2)) AS amount_covered,
        CAST ("AMOUNT_UNCOVERED" AS DECIMAL(12, 2)) AS amount_uncovered,
        CAST ("REVENUE" AS DECIMAL(12, 2)) AS revenue,
        CAST ("COVERED_ENCOUNTERS" AS INT) AS covered_encounters,
        CAST ("UNCOVERED_ENCOUNTERS" AS INT) AS uncovered_encounters,
        CAST ("COVERED_MEDICATIONS" AS INT) AS covered_medications,
        CAST ("UNCOVERED_MEDICATIONS" AS INT) AS uncovered_medications,
        CAST ("COVERED_PROCEDURES" AS INT) AS covered_procedures,
        CAST ("UNCOVERED_PROCEDURES" AS INT) AS uncovered_procedures,
        CAST ("COVERED_IMMUNIZATIONS" AS INT) AS covered_immunizations,
        CAST ("UNCOVERED_IMMUNIZATIONS" AS INT) AS uncovered_immunizations,
        CAST("UNIQUE_CUSTOMERS" AS INT) AS unique_customers,
        CAST ("QOLS_AVG" AS FLOAT) AS qols_avg,
        CAST ("MEMBER_MONTHS" AS INT) AS member_months

    from source

)

select * from renamed

