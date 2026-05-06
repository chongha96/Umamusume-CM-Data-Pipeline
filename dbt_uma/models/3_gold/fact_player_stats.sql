{{ config(materialized='table') }}

with cm_data as (select
                player_id,
                weekly_career_count,
                spend,
                total_careers
from {{ref('int_all_cm_unified')}}
)

select distinct
{{ dbt_utils.generate_surrogate_key(['player_id', 'c.weekly_career_count','c.total_careers']) }} as fact_player_stats_id,
player_id,
c.weekly_career_count,
c.spend,
c.total_careers
from cm_data c
where c.spend is not null