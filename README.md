# Disparities in Use of Interventions across ICU Cancer Patients


(to be organized)

**Code to get sepsis patients' ICD-9 and ICD-10 diagnoses codes**

```py

python3 data\get_data.py --sql_query_path "data\sql\MIMIC_dx\diagnoses.sql" --destination_path "data\diagnoses_tables\icd_9_and_10.csv"

```


**Code to convert ICD-9 codes into ICD-10**

based on this [GitHub Repo](https://github.com/AtlasCUMC/ICD10-ICD9-codes-conversion)

```py

python3 data\icd_codes\ICD9_to_ICD10.py  --original_file "data\diagnoses_tables\icd_9_and_10.csv" --result_file "data\diagnoses_tables\icd_10_only.csv"

```

**Code to get ICD-10 cancer sepsis patients**

```py

python3 data\icd_codes\cancer_patients.py --original_file "data\diagnoses_tables\icd_10_only.csv" --result_file "data\diagnoses_tables\sepsis_cancer_only.csv"

```