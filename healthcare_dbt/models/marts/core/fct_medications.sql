with medications as (

    select * from {{ ref('stg_synthea__medications') }}

),

patients as (

    select patient_sk, patient_id from {{ ref('dim_patients') }}

),

payers as (

    select payer_sk, payer_id from {{ ref('dim_payers') }}

),

medication_codes as (

    select medication_code_sk, medication_code from {{ ref('dim_medication_codes') }}

),

final as (

    select
        medications.encounter_id,

        patients.patient_sk,
        payers.payer_sk,
        medication_codes.medication_code_sk,

        medications.start_timestamp,
        medications.stop_timestamp,
        medications.reason_code,
        medications.reason_description,

        medications.base_cost,
        medications.payer_coverage,
        medications.dispenses,
        medications.total_cost

    from medications

    left join patients
        on medications.patient_id = patients.patient_id

    left join payers
        on medications.payer_id = payers.payer_id

    left join medication_codes
        on medications.code = medication_codes.medication_code

)

select * from final