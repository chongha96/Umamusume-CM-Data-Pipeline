import polars as pl
from google.cloud import bigquery
import io
import os
from dotenv import load_dotenv, find_dotenv

load_dotenv(find_dotenv())

def upload_cm_to_bq(df: pl.DataFrame, table_id: str):
    client = bigquery.Client(project=os.getenv("GCP_PROJECT_ID"))

    with io.BytesIO() as stream:
        df.write_parquet(stream)
        stream.seek(0)

        job_config = bigquery.LoadJobConfig(
            source_format=bigquery.SourceFormat.PARQUET,
            write_disposition="WRITE_TRUNCATE"
        )
        job = client.load_table_from_file(
            stream,
            table_id,
            job_config=job_config
        )

        job.result()
    print(f"Successfully uploaded {df.height} rows to {table_id}")



