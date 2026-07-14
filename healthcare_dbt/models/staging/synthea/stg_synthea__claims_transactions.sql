

with source as (

    select * from {{ source('synthea', 'CLAIMS_TRANSACTIONS') }}

),

renamed as (

    select
        "ID" AS claim_transaction_id,
        claimid AS claim_id,
        chargeid AS charge_id,
        patientid AS patient_id,
        type,
        CAST ("AMOUNT" AS DECIMAL(12, 2)) AS amount ,
        method,
        CAST ("FROMDATE"AS TIMESTAMP_TZ) AS from_timestamp,
        CAST ("TODATE" AS TIMESTAMP_TZ) AS to_timestamp,
        placeofservice AS place_of_service,
        procedurecode AS procedure_code,
        modifier1,
        modifier2,
        CAST ("DIAGNOSISREF1" AS INT) AS diagnosis_ref1,
        CAST ("DIAGNOSISREF2" AS INT) AS diagnosis_ref2,
        CAST ("DIAGNOSISREF3" AS INT) AS diagnosis_ref3,
        CAST ("DIAGNOSISREF4" AS INT) AS diagnosis_ref4,
        CAST ("UNITS" AS INT) AS units,
        departmentid AS department_id,
        notes,
        CAST ("UNITAMOUNT" AS DECIMAL(12, 2)) AS unit_amount,
        transferoutid AS transfer_out_id,
        transfertype AS transfer_type,
        CAST ("PAYMENTS" AS DECIMAL(12, 2)) AS payments,
        CAST ("ADJUSTMENTS" AS DECIMAL(12, 2)) AS adjustments,
        CAST ("TRANSFERS" AS DECIMAL(12, 2)) AS transfers,
        CAST ("OUTSTANDING" AS DECIMAL(12, 2)) AS outstanding,
        appointmentid AS appointment_id,
        linenote AS line_note,
        patientinsuranceid AS patient_insurance_id,
        feescheduleid AS fee_schedule_id,
        providerid AS provider_id,
        supervisingproviderid AS supervising_provider_id

    from source

)

select * from renamed

