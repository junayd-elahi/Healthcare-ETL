with encounters as (

    select * from {{ ref('stg_synthea__encounters') }}

),

patients as (

    select patient_sk, patient_id from {{ ref('dim_patients') }}

),

payers as (

    select payer_sk, payer_id from {{ ref('dim_payers') }}

),

providers as (

    select provider_sk, provider_id from {{ ref('dim_providers') }}

),

organizations as (

    select organization_sk, organization_id from {{ ref('dim_organizations') }}

),

encounter_codes as (

    select encounter_code_sk, encounter_code from {{ ref('dim_encounter_codes') }}

),

final as (

    select
        encounters.encounter_id,

        patients.patient_sk,
        payers.payer_sk,
        providers.provider_sk,
        organizations.organization_sk,
        encounter_codes.encounter_code_sk,

        encounters.start_timestamp,
        encounters.stop_timestamp,
        encounters.encounter_class,

        encounters.base_encounter_cost,
        encounters.total_claim_cost,
        encounters.payer_coverage

    from encounters

    left join patients
        on encounters.patient_id = patients.patient_id

    left join payers
        on encounters.payer_id = payers.payer_id

    left join providers
        on encounters.provider_id = providers.provider_id

    left join organizations
        on encounters.organization_id = organizations.organization_id

    left join encounter_codes
        on encounters.code = encounter_codes.encounter_code

)

select * from final