{{ config(materialized='table') }}

with latest_snapshots as (
    -- 1. Get the latest record per player first
    select *
    from {{ ref('int_all_cm_unified') }}
    qualify row_number() over (
        partition by clean_player_ign
        order by cm_number desc
    ) = 1
),

unpivoted_data as (
    -- 2. Unpivot the already filtered results
    select
        player_id,
        card_source_name,
        card_count
    from latest_snapshots
    unpivot (
        card_count for card_source_name in (
            count_kitasan_black_ssr_speed,
            count_biko_pegasus_ssr_speed,
            count_matikanefukukitaru_ssr_speed,
            count_super_creek_ssr_stamina,
            count_rice_shower_ssr_power,
            count_fine_motion_ssr_wit,
            count_nice_nature_ssr_wit,
            count_curren_chan_ssr_wit,
            count_riko_kashimoto_ssr_pal,
            count_riko_kashimoto_r_pal
        )
    )
)

select
    {{ dbt_utils.generate_surrogate_key(['player_id', 'm.card_id']) }} as fact_player_card_id,
    m.card_id,
    u.card_count,
    u.player_id
from unpivoted_data u
left join {{ ref('map_cards') }} m
    on u.card_source_name = m.source_column_name