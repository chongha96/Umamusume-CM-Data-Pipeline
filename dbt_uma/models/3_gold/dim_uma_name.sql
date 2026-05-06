{{ config(materialized='table') }}

WITH all_names AS (
    SELECT uma_1_name AS uma_name FROM {{ ref('int_all_cm_unified') }}
    UNION DISTINCT
    SELECT uma_2_name AS uma_name FROM {{ ref('int_all_cm_unified') }}
    UNION DISTINCT
    SELECT uma_3_name AS uma_name FROM {{ ref('int_all_cm_unified') }}
),
filtered_names AS (
    SELECT TRIM(uma_name) AS uma_name
    FROM all_names
    WHERE uma_name IS NOT NULL
)

SELECT
    ROW_NUMBER() OVER (ORDER BY uma_name ASC) AS uma_id,
    uma_name
FROM filtered_names
