{{ config(materialized='table') }}

with raw_data as (
    select * from {{ source('1_bronze_data','raw_cm6_day_1') }}
),

-- Pulling data for Team Composition 1
team_finals as (
    select
        player_ign,
        league,
        5 as day,
        6 as cm_number,
        a_or_b_finals as finals,
        finals_result,
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