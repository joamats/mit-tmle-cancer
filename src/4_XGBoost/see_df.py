import pandas as pd
import numpy as np 
import os 

path = 'data/cohorts/'

# prinf files in path
print(os.listdir(path))

all_df = pd.read_csv('data/cohorts/merged_all.csv')
print('#'*50)
print(all_df.head())
print('Columns: ', all_df.columns)
print('#'*50)

cancer_df = pd.read_csv('data/cohorts/merged_cancer.csv')
print('#'*50)
print(cancer_df.head())
print('Columns: ', cancer_df.columns)
print('#'*50)



# print(f"Race cohort: {pd.unique(cancer_df['race_group'])}")

# print('')
# eicu = pd.read_csv('data/cohorts/eicu_all.csv')
# print(eicu.columns)
# print(f"Length of eICU: {len(eicu)}, unique patients: {len(pd.unique(eicu['patientunitstayid']))}")

# print('')
# mimic_all = pd.read_csv('data/cohorts/mimic_all.csv')
# print(mimic_all.columns)
# print(f"Length of mimic: {len(mimic_all)}, unique patients: {len(pd.unique(mimic_all['stay_id']))}")


