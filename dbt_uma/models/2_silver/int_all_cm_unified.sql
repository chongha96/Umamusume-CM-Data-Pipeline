with joined_data as (
    {{ dbt_utils.union_relations(
        relations=[
            ref('int_cm6'),
            ref('int_cm7_unified'),
            ref('int_cm8_unified'),
            ref('int_cm9_unified'),
            ref('int_cm10_unified'),
            ref('int_cm11_unified')
        ]
    ) }}
)

select FARM_FINGERPRINT(
    trim(lower(regexp_replace(player_ign, r'\s+', ' ')))) as player_id,
    trim(lower(regexp_replace(player_ign, r'\s+', ' '))) as clean_player_ign,
    {{ clean_uma_name('uma_1_name') }} as uma_1_name,
    {{ clean_uma_name('uma_2_name') }} as uma_2_name,
    {{ clean_uma_name('uma_3_name') }} as uma_3_name,
    * except(uma_1_name, uma_2_name, uma_3_name)
from joined_data
where player_ign is not null