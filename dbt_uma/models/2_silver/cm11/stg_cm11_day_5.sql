{{ config(materialized='table') }}

with raw_data as (
    select * from {{ source(env_var('GCP_BRONZE_DATASET_ID'),'raw_cm11_day_5') }}
),

-- Pulling data for Team Composition 1
team_finals as (
    select
        player_ign,
        device,
        league,
        coalesce(a_group_or_b_group_duplicated_0, a_group_or_b_group,'N/A') AS cm_group,
        5 as day,
        11 as cm_number,
        spend,
        player_type,
        weekly_career_count,
        a_or_b_finals as finals,
        finals_result,
        optional_careers_completed_on_the_account as total_careers,
        card_status_in_account_non_borrow_biko_pegasus_speed as count_biko_pegasus_ssr_speed,
        card_status_in_account_non_borrow_kitasan_black_speed as count_kitasan_black_ssr_speed,
        card_status_in_account_non_borrow_matikanefukukitaru_speed as count_matikanefukukitaru_ssr_speed,
        card_status_in_account_non_borrow_narita_top_road_speed as count_narita_top_road_ssr_speed,
        card_status_in_account_non_borrow_super_creek_stamina as count_super_creek_ssr_stamina,
        card_status_in_account_non_borrow_rice_shower_power as count_rice_shower_ssr_power,
        card_status_in_account_non_borrow_fine_motion_wit as count_fine_motion_ssr_wit,
        card_status_in_account_non_borrow_nice_nature_wit as count_nice_nature_ssr_wit,
        card_status_in_account_non_borrow_curren_chan_wit as count_curren_chan_ssr_wit,
        card_status_in_account_non_borrow_riko_kashimoto_pal_ssr as count_riko_kashimoto_ssr_pal,
        1 as team_id,
        finals_team_comp_uma_1_name as uma_1_name,
        finals_team_comp_uma_1_running_style as uma_1_style,
        finals_team_comp_uma_1_role as uma_1_role,
        finals_team_comp_uma_2_name as uma_2_name,
        finals_team_comp_uma_2_running_style as uma_2_style,
        finals_team_comp_uma_2_role as uma_2_role,
        finals_team_comp_uma_3_name as uma_3_name,
        finals_team_comp_uma_3_running_style as uma_3_style,
        finals_team_comp_uma_3_role as uma_3_role
        from raw_data
)

select * from team_finals