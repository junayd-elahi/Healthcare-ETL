with organizations as (

    select * from {{ ref('stg_synthea__organizations') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['organization_id']) }} as organization_sk,
        organization_id,
        organization_name,
        city,
        state,
        zip,
        latitude,
        longitude,
        phone

    from organizations

)

select * from final