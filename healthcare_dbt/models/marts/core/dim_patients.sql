with patients as (

    select * from {{ ref('stg_synthea__patients') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['patient_id']) }} as patient_sk,
        patient_id,
        birth_date,
        death_date,
        first_name,
        last_name,
        marital_status,
        race,
        ethnicity,
        gender,
        city,
        state,
        county,
        zip,
        latitude,
        longitude,
        healthcare_expense,
        healthcare_coverage,
        income

    from patients

)

select * from final