import argparse
import pandas as pd
import numpy as np

def parse_args():
    parser = argparse.ArgumentParser()
    
    parser.add_argument("--result_file",
                        default="data\eICU_table.csv",
                        help="Insert your target path for joint dataset file")

    parser.add_argument("--dataset",
                    default="eICU",
                    help="Insert the dataset to work with")

    return parser.parse_args()

# Combine the info from multiple columns into 3 distinct columns for each of the 3 treatments in eICU data
def cat_rrt(rrt):  
    if rrt['rrt'] == True:
        return 1
    elif rrt['rrt_1'] > 0:
        return 1
    else: 
        return np.NaN

def cat_vent(vent): 
    if vent['vent'] == True:
        return 1
    elif vent['vent_1'] > 0:
        return 1
    elif vent['vent_2'] > 0:
        return 1
    elif vent['vent_3'] > 0:
        return 1
    elif vent['vent_4'] > 0:
        return 1
    elif vent['vent_5'] > 0:
        return 1
    elif vent['vent_6'] > 0:
        return 1
    else: 
        return np.NaN

def cat_pressor(pressor): 
    if pressor['vasopressor'] == True:
        return 1
    elif pressor['pressor_1'] > 0:
        return 1
    elif pressor['pressor_2'] > 0:
        return 1
    elif pressor['pressor_2'] > 0:
        return 1
    elif pressor['pressor_3'] > 0:
        return 1
    elif pressor['pressor_4'] > 0:
        return 1
    else: 
        return np.NaN

# Apply the functions and save the CSV
def combine_treatment_eICU(df):

    df['RRT_final'] = df.apply(lambda rrt: cat_rrt(rrt), axis=1)
    df['VENT_final'] = df.apply(lambda vent: cat_vent(vent), axis=1)
    df['PRESSOR_final'] = df.apply(lambda pressor: cat_pressor(pressor), axis=1)

    return df


if __name__ == '__main__':

    args = parse_args()

    if args.dataset == "MIMIC":
        df_sepsis = pd.read_csv("data\sepsis_MIMIC\sepsis_all.csv")
        df_cancer = pd.read_csv("data\dx_MIMIC\sepsis_cancer_only.csv")

        key = "subject_id"

    elif args.dataset == "eICU":
        df_sepsis = pd.read_csv("data\sepsis_eICU\sepsis_all.csv")
        # Combine vent, rrt, vasopressor columns into one of each only
        df_sepsis = combine_treatment_eICU(df_sepsis)
        df_cancer = pd.read_csv("data\dx_eICU\sepsis_cancer_only.csv") 

        key = "patientunitstayid"

    # Get together
    df_all = df_sepsis.set_index(key).join(df_cancer.set_index(key), how="inner", rsuffix="_")

    # Remove unnamed columns
    df_all = df_all.loc[:, ~df_all.columns.str.contains('^Unnamed')]

    print(f"Cancer patients: {len(df_cancer)}")
    print(f"Sepsis patients: {len(df_sepsis)}")
    print(f"Final patients: {len(df_all)}")

    # Save DataFrame
    df_all.to_csv(args.result_file)