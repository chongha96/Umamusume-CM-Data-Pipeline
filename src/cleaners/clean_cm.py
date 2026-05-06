"""
----Cleaning CM7 Data----

Investigating the columns that are within each dataset, and what will be necessary for analysis.

Cleaning operations include fixing column names, categorizing certain responses, and simplifying values
"""
#Imports and Settings
import polars as pl
from src.utils import global_cleaning_operations as gco


def run_clean_cm(cm_num: int) -> list[pl.DataFrame]:
    print(f"Cleaning data for CM{cm_num}")
    return gco.clean_cm(cm_num)

if __name__ == "__main__":
    run_clean_cm()