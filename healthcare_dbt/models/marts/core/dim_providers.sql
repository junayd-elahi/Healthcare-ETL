with providers as (

    select * from {{ ref('stg_synthea__providers') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['provider_id']) }} as provider_sk,
        provider_id,
        provider_name,
        gender,
        speciality,
        city,
        state,
        zip,
        latitude,
        longitude

    from providers

)

select * from final