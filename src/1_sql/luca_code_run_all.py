import os
from dotenv import load_dotenv
from google.cloud import bigquery

# Load environment variables
load_dotenv()
project_id = os.getenv('PROJECT_ID')

# Set up BigQuery client using default SDK credentials
client = bigquery.Client(project=project_id)

# Create 'aux' dataset if it doesn't exist
dataset_id = f"{project_id}.inv_vent_thresholds"
dataset = bigquery.Dataset(dataset_id)
dataset.location = "US"
dataset = client.create_dataset(dataset, exists_ok=True)

# Run SQL scripts in order
script_filenames = ['1-o2delivery.sql',
                    '2-thresh_elig.sql',
                    '3-thresh_timevarying.sql',
                    '4-baseline.sql']

for script_filename in script_filenames:
    print(f"Executing {script_filename}...")
    with open(script_filename, 'r') as script_file:
        script = script_file.read().replace('PROJECT_ID', project_id)
        job = client.query(script)
        job.result()  # Wait for the query to complete

print("All scripts executed successfully.")
