from src.cleaners.cleaning_orchestrator import CleanerFactory


def main():
    cm_versions = [6, 7, 8, 9, 10, 11]

    print(f"Starting ingestion for {len(cm_versions)} CM versions...")

    for cm_id in cm_versions:
        try:
            print(f"\nProcessing CM{cm_id}...")
            CleanerFactory.run_pipeline(cm_id)
            print(f"CM{cm_id} successfully uploaded.")
        except Exception as e:
            print(f"Error processing CM{cm_id}: {e}")


if __name__ == "__main__":
    main()
