{{ dbt_utils.union_relations(
    relations=[
        ref('stg_cm8_day_1'),
        ref('stg_cm8_day_2'),
        ref('stg_cm8_day_3'),
        ref('stg_cm8_day_4'),
        ref('stg_cm8_day_5')
    ],
    source_column_name="cm8_source"
) }}