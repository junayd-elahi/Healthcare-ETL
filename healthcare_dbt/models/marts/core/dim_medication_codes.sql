with medications as (

    select * from {{ ref('stg_synthea__medications') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['code']) }} as medication_code_sk,
        code as medication_code,
        description as medication_description

    from medications

    qualify row_number() over (
        partition by code
        order by description
    ) = 1

)

select * from final