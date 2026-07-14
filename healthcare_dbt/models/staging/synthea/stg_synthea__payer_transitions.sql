

with source as (

    select * from {{ source('synthea', 'PAYER_TRANSITIONS') }}

),

renamed as (

    select
        patient AS patient_id,
        memberid AS member_id,
        CAST ("START_DATE" AS TIMESTAMP_TZ) AS start_timestamp,
        CAST ("END_DATE" AS TIMESTAMP_TZ) AS end_timestamp,
        payer AS payer_id,
        secondary_payer AS secondary_payer_id,
        plan_ownership,
        owner_name

    from source

)

select * from renamed

