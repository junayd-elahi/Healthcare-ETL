with encounters as (

    select * from {{ ref('stg_synthea__encounters') }}

),

final as (

    select distinct
        {{ dbt_utils.generate_surrogate_key(['code']) }} as encounter_code_sk,
        code as encounter_code,
        description as encounter_description

    from encounters

)

select * from final