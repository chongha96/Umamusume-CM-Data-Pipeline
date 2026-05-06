{{ config(materialized='table') }}

with cm_data as (
    select
        day,
        player_id,
        league,
        cm_group,
        cm_number,
        finals,
        finals_result,
        team_id,
        day_races,
        day_wins,
        uma.name,
        uma.role,
        uma.style
    from {{ref('int_all_cm_unified')}},
    unnest([
        STRUCT(uma_1_name AS name, uma_1_role AS role, uma_1_style AS style),
        STRUCT(uma_2_name AS name, uma_2_role AS role, uma_2_style AS style),
        STRUCT(uma_3_name AS name, uma_3_role AS role, uma_3_style AS style)
    ]) as uma
)


select
{{ dbt_utils.generate_surrogate_key(['player_id', 'c.name', 'c.day','c.cm_number']) }} as fact_race_results_id,
c.player_id,
c.day,
c.cm_number,
c.league,
coalesce(
    case
        when c.day = 1 or c.day = 2
        then "N/A"
        when cm_group = "A Group"
        then "Group A"
        when cm_group = "B Group"
        then "Group B"
    end,
    case
        when c.finals = "A Finals"
        then "Group A"
        when c.finals = "B Finals"
        then "Group B"
    end
)as cm_group,
coalesce(
    case
        when c.finals is not null
        then "Finals"
    end,
    case
        when c.day_races is not null
        then "Group Stage"
    end
    ) as cm_stage,
coalesce(
    case
        when c.finals is not null
        then 1
    end,
    case
        when c.day_races = "0 Attempts - 0 Races total"
        then 0
        when c.day_races = "1 Attempt - 5 Races total"
        then 5
        when c.day_races = "2 Attempts - 10 Races total"
        then 10
        when c.day_races = "3 Attempts - 15 Races total"
        then 15
        when c.day_races = "4 Attempts - 20 Races total"
        then 20
    end
    ) as num_races,
c.finals_result,
coalesce(
    case
        when c.finals_result = "1st"
        then 1
        when c.finals_result is not null
        then 0
    end,
    c.day_wins
    ) as race_wins,
coalesce(
    case
        when c.finals_result = "1st"
        then 100
        when c.finals_result is not null
        then 0
    end,
    case
        when c.day_races = "Group Stage - 0 Entries"
        then 0
        when c.day_races = "1 Attempt - 5 Races total"
        then round(((c.day_wins / 5.0)*100.),2)
        when c.day_races = "2 Attempts - 10 Races total"
        then round(((c.day_wins / 10.0)*100),2)
        when c.day_races = "3 Attempts - 15 Races total"
        then round(((c.day_wins / 15.0)*100),2)
        when c.day_races = "4 Attempts - 20 Races total"
        then round(((c.day_wins / 20.0)*100),2)
    end
    ) as race_winrate,
    c.team_id,
    n.uma_id,
    r.role_id,
    s.style_id
from cm_data c
left join {{ref('dim_uma_role')}} r on r.role_name = c.role
left join {{ref('dim_style')}} s on s.style_name = c.style
left join {{ref('dim_uma_name')}} n on n.uma_name = c.name
where c.name is not null
