# Disparities in Use of Interventions across ICU Cancer Patients


(to be organized)

## Code to get sepsis patients with sepsis and cancer

### MIMIC-IV

#### Get Septic Patients from GCP

```py

python3 data\get_gcp_data.py --sql_query_path "data\sql\mimic_table.sql" --destination_path "data\sepsis_MIMIC\sepsis_all.csv"

```

#### Get Cancer ICD codes from GCP

```py

python3 data\get_gcp_data.py --sql_query_path "data\sql\dx_MIMIC\diagnoses.sql" --destination_path "data\dx_MIMIC\icd_9_and_10.csv"

```

#### Translate, Map, Encode and Join Cancer ICD-10 codes

``` py
python3 data\icd_codes\cancer_patients.py --original_file data\dx_MIMIC\icd_9_and_10.csv --result_file data\table_MIMIC.csv --dataset "MIMIC"

```




### eICU


#### Get Septic Patients from GCP

```py

python3 data\get_gcp_data.py --sql_query_path "data\sql\eicu_table.sql" --destination_path "data\sepsis_eICU\sepsis_all.csv"

```

#### Get Cancer ICD codes from GCP

```py

python3 data\get_gcp_data.py --sql_query_path "data\sql\dx_eICU\diagnoses.sql" --destination_path "data\dx_eICU\icd_9_and_10.csv"

```

#### Translate, Map, Encode and Join Cancer ICD-10 codes

``` py
python3 data\icd_codes\cancer_patients.py --original_file data\dx_eICU\icd_9_and_10.csv --result_file data\table_eICU.csv --dataset "eICU"

```



ICD-9 to ICD-10 translation based on this [GitHub Repo](https://github.com/AtlasCUMC/ICD10-ICD9-codes-conversion)