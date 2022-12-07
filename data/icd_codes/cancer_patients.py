import argparse
from tqdm import tqdm
import pandas as pd
import numpy as np
import sys
tqdm.pandas()

sys.path.append("data\sepsis_eICU")
sys.path.append("data\icd_codes")
from combine_treatment import combine_treatment_eICU
from icd_9_to_10 import icd_9_to_10

def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--original_file",
                        default="data\dx_eICU\icd_9_and_10.csv",
                        help="Insert your original file with all ICD (9 & 10) codes")

    parser.add_argument("--result_file",
                        default="data/table_eICU.csv",
                        help="Insert your target path for the final table")

    parser.add_argument("--dataset",
                    default="eICU",
                    help="Insert the dataset to work with")

    return parser.parse_args()



if __name__ == '__main__':

    args = parse_args()

    # 1. Convert ICD-9 to ICD-10 codes
    # Read the file to process with disease patients
    print("Converting ICD-9 to ICD-10 codes")
    df = icd_9_to_10(args.original_file, args.dataset)

    # Narrow down to cancer ICD codes
    df = df[df.icd_10.str.contains("C")]


    # 2. Encode ICD codes into columns
    # Get the mapping ICD codes - disease type
    disease_map = pd.read_csv("data\icd_codes\disease_types.csv")

    # First let's create a column for each disease
    for index, row in disease_map.iterrows():
        df[row.disease_type] = np.nan
    

    print("Encoding disease types from ICD-10 codes")
    # Go over each ICD code for disease type, make true if our code matches
    for index, row in tqdm(disease_map.iterrows(), total=len(disease_map)):

        df[row.disease_type] = df.apply(lambda x: 1 if row.icd_10 in x.icd_10 else x[row.disease_type], axis=1)

    # Get unique disease types names
    unique_disease_types = disease_map.disease_type.unique()

    print(f"Before groupping by patient, N = {len(df)}")

    # Group by patient
    if args.dataset == "MIMIC":
        df = df.groupby("subject_id").sum()

    elif args.dataset == "eICU":
        df = df.groupby("patientunitstayid").sum()

    # Convert these sums into 0 or 1 (anything >= 1)
    for index, row in disease_map.iterrows():

        df[row.disease_type] = df[row.disease_type].apply(lambda x: 1 if x >= 1 else np.nan)
    
    # Encode as other if no cancer types have been detected, within our list
    df['other'] = ~df[unique_disease_types].any(axis=1)
    df.other = df.other.apply(lambda x: np.nan if x == 0 else 1)

    print(f"After groupping by patient, N = {len(df)}")

    df = df.loc[:, ~df.columns.str.contains('^Unnamed')]
    
    if args.dataset == "MIMIC":
        df.drop(["icd_version"], axis=1, inplace=True)

    # 3. Combine existing dataset with ICD codes
    if args.dataset == "MIMIC":
        df_sepsis = pd.read_csv("data\sepsis_MIMIC\sepsis_all.csv")

        df.to_csv("data\dx_MIMIC\processed_icd_codes.csv")
        df = pd.read_csv("data\dx_MIMIC\processed_icd_codes.csv")

        key = "subject_id"

        df_all = df.set_index(key).join(df_sepsis.set_index(key), rsuffix="_")


    elif args.dataset == "eICU":
        df_sepsis = pd.read_csv("data\sepsis_eICU\sepsis_all.csv")
        # Combine vent, rrt, vasopressor columns into one of each only
        df_sepsis = combine_treatment_eICU(df_sepsis)

        key = "patientunitstayid"

        df.to_csv("data\dx_eICU\processed_icd_codes.csv")
        df = pd.read_csv("data\dx_eICU\processed_icd_codes.csv")

        # Get together
        df_all = df.set_index(key).join(df_sepsis.set_index(key), rsuffix="_")

    print(f"Patients with Disease of interest: {len(df)}")
    print(f"Sepsis patients: {len(df_sepsis)}")
    print(f"Final patients: {len(df_all)}")

    df_all = df_all.loc[:, ~df_all.columns.str.contains('^Unnamed')]


    # Save DataFrame
    df_all.to_csv(args.result_file)
