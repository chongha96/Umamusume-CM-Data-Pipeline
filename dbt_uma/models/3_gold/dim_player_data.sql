with get_player as (
    select
        player_id,
        clean_player_ign,
        player_type,
        total_careers,
        device,
        row_number() over (
            partition by clean_player_ign
            order by total_careers desc
            ) as row_num
    from {{ ref('int_all_cm_unified') }}
)

select
    player_id,
    clean_player_ign as player_ign,
    player_type,
    device
from get_player
where row_num = 1
