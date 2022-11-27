# Disparities in Use of Interventions across ICU Cancer Patients


(to be organized)

**Code to get sepsis patients**

MIMIC-IV

```py

python3 data\get_gcp_data.py --sql_query_path "data\sql\mimic_table.sql" --destination_path "data\sepsis_MIMIC\sepsis_all.csv"

```

eICU

```py

python3 data\get_gcp_data.py --sql_query_path "data\sql\eicu_table.sql" --destination_path "data\sepsis_eICU\sepsis_all.csv"

```



**Code to get sepsis patients' ICD-9 and ICD-10 diagnoses codes**

MIMIC-IV

```py

python3 data\get_gcp_data.py --sql_query_path "data\sql\dx_MIMIC\diagnoses.sql" --destination_path "data\dx_MIMIC\icd_9_and_10.csv"

```

eICU

```py

python3 data\get_gcp_data.py --sql_query_path "data\sql\dx_eICU\diagnoses.sql" --destination_path "data\dx_eICU\icd_9_and_10.csv"

```


**Code to convert ICD-9 codes into ICD-10**

based on this [GitHub Repo](https://github.com/AtlasCUMC/ICD10-ICD9-codes-conversion)

MIMIC

```py

python3 data\icd_codes\icd_9_to_10.py  --original_file "data\dx_MIMIC\icd_9_and_10.csv" --result_file "data\dx_MIMIC\icd_10_only.csv" --dataset "MIMIC"

```

eICU

```py

python3 data\icd_codes\icd_9_to_10.py  --original_file "data\dx_eICU\icd_9_and_10.csv" --result_file "data\dx_eICU\icd_10_only.csv" --dataset "eICU"

```

**Code to get ICD-10 cancer sepsis patients**

MIMIC

```py

python3 data\icd_codes\cancer_patients.py --original_file "data\dx_MIMIC\icd_10_only.csv" --result_file "data\dx_MIMIC\sepsis_cancer_only.csv" --dataset "MIMIC"

```

eICU

```py

python3 data\icd_codes\cancer_patients.py --original_file "data\dx_eICU\icd_10_only.csv" --result_file "data\dx_eICU\sepsis_cancer_only.csv" --dataset "eICU"

```


**Combine Sepsis and Cancer dataframes**

MIMIC

```py

python3 data\combine_data.py --dataset "MIMIC" --result_file "data\MIMIC_table.csv"

```

eICU

```py

python3 data\combine_data.py --dataset "eICU" --result_file "data\eICU_table.csv"

```