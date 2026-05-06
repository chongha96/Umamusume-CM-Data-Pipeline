import src.cleaners.clean_cm as cm
import src.utils.ingestion as bq
import os
from dotenv import load_dotenv, find_dotenv
os.environ["TRANSFORMERS_OFFLINE"] = "1"
os.environ["HF_HUB_OFFLINE"] = "1"
load_dotenv(find_dotenv())

class CleanerFactory:

    @classmethod
    #Obtains cleaned data from a CM dataset
    def get_cleaned_data(cls, cm_id: int):
        print(f"Cleaning data for CM{cm_id}...")
        return cm.run_clean_cm(cm_id)

    @staticmethod
    #Creating pipeline to insert data to bq table
    def run_pipeline(cm_id: int):

        cm_data = CleanerFactory.get_cleaned_data(cm_id)

        project_id = os.getenv("GCP_PROJECT_ID")
        dataset_id = os.getenv("GCP_BRONZE_DATASET_ID")

        #Loops through list of CM DFs, uploading each to BQ under their respective day and cm
        for i, df in enumerate(cm_data):
            table_id = f"{project_id}.{dataset_id}.raw_cm{cm_id}_day_{i + 1}"
            bq.upload_cm_to_bq(df, table_id)




