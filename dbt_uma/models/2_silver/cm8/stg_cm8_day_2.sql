{{ config(materialized='table') }}

with raw_data as (
    select * from {{ source(env_var('GCP_BRONZE_DATASET_ID'),'raw_cm8_day_2') }}
),

-- Pulling data for Team Composition 1
team_1 as (
    select
        player_ign,
        league,
        coalesce(a_group_or_b_group_duplicated_0, a_group_or_b_group,'N/A') AS cm_group,
        2 as day,
        8 as cm_number,
        spend,
        player_type,
        weekly_career_count,
        optional_careers_completed_on_the_account as total_careers,
        card_status_in_account_non_borrow_biko_pegasus_speed as count_biko_pegasus_ssr_speed,
        card_status_in_account_non_borrow_kitasan_black_speed as count_kitasan_black_ssr_speed,
        card_status_in_account_non_borrow_super_creek_stamina as count_super_creek_ssr_stamina,
        card_status_in_account_non_borrow_rice_shower_power as count_rice_shower_ssr_power,
        card_status_in_account_non_borrow_fine_motion_wit as count_fine_motion_ssr_wit,
        card_status_in_account_non_borrow_nice_nature_wit as count_nice_nature_ssr_wit,
        card_status_in_account_non_borrow_riko_kashimoto_pal_ssr as count_riko_kashimoto_ssr_pal,
        1 as team_id,
        day_2_team_comp_1_uma_1_name as uma_1_name,
        day_2_team_comp_1_uma_1_running_style as uma_1_style,
        day_2_team_comp_1_uma_1_role as uma_1_role,
        day_2_team_comp_1_uma_2_name as uma_2_name,
        day_2_team_comp_1_uma_2_running_style as uma_2_style,
        day_2_team_comp_1_uma_2_role as uma_2_role,
        day_2_team_comp_1_uma_3_name as uma_3_name,
        day_2_team_comp_1_uma_3_running_style as uma_3_style,
        day_2_team_comp_1_uma_3_role as uma_3_role,
        day_2_team_comp_1_number_of_attempts_races_played as day_races,
        day_2_team_comp_1_number_of_wins as day_wins
    from raw_data
),

-- Pulling data for Team Composition 2
team_2 as (
    select
        player_ign,
        league,
        coalesce(a_group_or_b_group_duplicated_0, a_group_or_b_group,'N/A') AS cm_group,
        2 as day,
        8 as cm_number,
        spend,
        player_type,
        weekly_career_count,
        optional_careers_completed_on_the_account as total_careers,
        card_status_in_account_non_borrow_biko_pegasus_speed as count_biko_pegasus_ssr_speed,
        card_status_in_account_non_borrow_kitasan_black_speed as count_kitasan_black_ssr_speed,
        card_status_in_account_non_borrow_super_creek_stamina as count_super_creek_ssr_stamina,
        card_status_in_account_non_borrow_rice_shower_power as count_rice_shower_ssr_power,
        card_status_in_account_non_borrow_fine_motion_wit as count_fine_motion_ssr_wit,
        card_status_in_account_non_borrow_nice_nature_wit as count_nice_nature_ssr_wit,
        card_status_in_account_non_borrow_riko_kashimoto_pal_ssr as count_riko_kashimoto_ssr_pal,
        2 as team_id,
        day_2_team_comp_2_uma_1_name as uma_1_name,
        day_2_team_comp_2_uma_1_running_style as uma_1_style,
        day_2_team_comp_2_uma_1_role as uma_1_role,
        day_2_team_comp_2_uma_2_name as uma_2_name,
        day_2_team_comp_2_uma_2_running_style as uma_2_style,
        day_2_team_comp_2_uma_2_role as uma_2_role,
        day_2_team_comp_2_uma_3_name as uma_3_name,
        day_2_team_comp_2_uma_3_running_style as uma_3_style,
        day_2_team_comp_2_uma_3_role as uma_3_role,
        day_2_team_comp_2_number_of_attempts_races as day_races,
        day_2_team_comp_2_number_of_wins as day_wins
    from raw_data
)


select * from team_1
union all
select * from team_2

