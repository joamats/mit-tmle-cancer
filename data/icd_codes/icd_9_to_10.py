import argparse
from tqdm import tqdm
import pandas as pd
import numpy as np
tqdm.pandas()

# Conversion using MIMIC's format
def mimic_conversion(row, mapping):

    if row.icd_version == 9:
        try:
            return mapping[row.icd_code]
        except:
            return np.nan

    elif row.icd_version == 10:
        return row.icd_code
    
    else: 
        return np.nan


# Conversion using eICU's data format
def eicu_conversion(row, mapping):

    if isinstance(row.ICD9Code, str):
        codes = row.ICD9Code.split(", ")
    else: # empty
        return np.nan

    # first column is ICD-9 and second is ICD-10, let's keep the second
    if len(codes) == 2:
        return codes[1]
    
    # only one code is present
    elif len(codes) == 1:
        # if the code is ICD-9, let's convert it
        try:
            return mapping[codes[0]]
        
        except:
            # if it fails, code can be ICD-10 
            if codes[0] in mapping.values():
                return codes[0]
            # or a mismatch
            else: 
                return np.nan


def icd_9_to_10(original_file, dataset):

    df = pd.read_csv(original_file)

    conversions = pd.read_csv("data/icd_codes/ICD10_Formatted.csv")[['ICD-9', 'ICD-10']]

    mapping = dict(zip(conversions['ICD-9'], conversions['ICD-10']))

    n = len(df)
    i = 0

    if dataset == "MIMIC":

        df['icd_10'] = df.progress_apply(lambda row: mimic_conversion(row, mapping), axis=1)
    
    elif dataset == "eICU":

        df = df[['patientunitstayid','ICD9Code']]
        df['icd_10'] = df.progress_apply(lambda row: eicu_conversion(row, mapping), axis=1)


    df.dropna(inplace=True)      
                
    print(f"Inital length: {n}\nFinal Length: {len(df)}")

    return df