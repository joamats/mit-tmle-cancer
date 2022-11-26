import argparse
from tqdm import tqdm
import pandas as pd
import numpy as np
tqdm.pandas()

def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--original_file",
                        default="data\diagnoses_tables\icd_9_and_10.csv",
                        help="Insert your original file with ICD 9 and 10 codes")

    parser.add_argument("--result_file",
                        default="data\diagnoses_tables\icd_10_only.csv",
                        help="Insert your target path for the ICD 10 converted file ")

    return parser.parse_args()

def icd9_to_icd10(row, mapping):

    if row.icd_version == 9:
        try:
            return mapping[row.icd_code]
        except:
            return np.nan

    elif row.icd_version == 10:
        return row.icd_code
    
    else: 
        return np.nan


if __name__ == '__main__':

    args = parse_args()

    df = pd.read_csv(args.original_file)

    conversions = pd.read_csv("data\icd_codes\ICD10_Formatted.csv")[['ICD-9', 'ICD-10']]

    mapping = dict(zip(conversions['ICD-9'], conversions['ICD-10']))

    n = len(df)
    i = 0
    idxs_to_drop = list()

    df['icd_10'] = df.progress_apply(lambda row: icd9_to_icd10(row, mapping), axis=1)

    df.dropna(inplace=True)      
                
    print(f"Inital length: {n}\nFinal Length: {len(df)}")

    df.to_csv(args.result_file)