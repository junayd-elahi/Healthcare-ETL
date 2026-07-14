with payers as (

    select * from {{ ref('stg_synthea__payers') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['payer_id']) }} as payer_sk,
        payer_id,
        payer_name,
        ownership,
        city,
        state_headquartered,
        zip

    from payers

)

select * from final