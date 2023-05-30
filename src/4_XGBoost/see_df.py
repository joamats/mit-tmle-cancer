""" This file should be removed. It is only for testing purposes. """

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

def get_cohort(i):
    return {"cohort": [i],
            "group": [i],
            "treatment": [i],
            "OR": [i],
            "2.5%": [i],
            "97.5%": [i]}

results_df = pd.DataFrame(columns=["cohort", "group", "treatment", "OR", "2.5%", "97.5%"])

for i in range(10):
    new_row = pd.DataFrame.from_dict(get_cohort())
    
    results_df = pd.concat([results_df, new_row], ignore_index=True)
    
#print(results_df.head())

# print(f"Race cohort: {pd.unique(cancer_df['race_group'])}")

# print('')
# eicu = pd.read_csv('data/cohorts/eicu_all.csv')
# print(eicu.columns)
# print(f"Length of eICU: {len(eicu)}, unique patients: {len(pd.unique(eicu['patientunitstayid']))}")

# print('')
# mimic_all = pd.read_csv('data/cohorts/mimic_all.csv')
# print(mimic_all.columns)
# print(f"Length of mimic: {len(mimic_all)}, unique patients: {len(pd.unique(mimic_all['stay_id']))}")


