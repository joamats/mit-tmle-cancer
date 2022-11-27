import argparse
from tqdm import tqdm
import pandas as pd
import numpy as np
tqdm.pandas()

def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--original_file",
                        default="data\dx_eICU\icd_9_and_10.csv",
                        help="Insert your original file with ICD 9 and 10 codes")

    parser.add_argument("--result_file",
                        default="data\dx_eICU\icd_10_only.csv",
                        help="Insert your target path for the ICD 10 converted file")

    parser.add_argument("--dataset",
                        default="eICU",
                        help="Insert the dataset to work with")

    return parser.parse_args()


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


if __name__ == '__main__':

    args = parse_args()

    df = pd.read_csv(args.original_file)

    conversions = pd.read_csv("data\icd_codes\ICD10_Formatted.csv")[['ICD-9', 'ICD-10']]

    mapping = dict(zip(conversions['ICD-9'], conversions['ICD-10']))

    n = len(df)
    i = 0

    if args.dataset == "MIMIC":

        df['icd_10'] = df.progress_apply(lambda row: mimic_conversion(row, mapping), axis=1)
    
    elif args.dataset == "eICU":

        df = df[['patientunitstayid','ICD9Code']]
        df['icd_10'] = df.progress_apply(lambda row: eicu_conversion(row, mapping), axis=1)


    df.dropna(inplace=True)      
                
    print(f"Inital length: {n}\nFinal Length: {len(df)}")

    df.to_csv(args.result_file)