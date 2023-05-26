import pandas as pd
import numpy as np

# Get treatment groups
def get_treatment_groups(df):
    """
    Get the treatment groups for the cohort.
    input: 
        df (pd.DataFrame): The cohort.
    output: 
        df (pd.DataFrame): The cohort with treatment groups.
    columns: mv_elig, rrt_elig, vp_elig
        1 if the patient is eligible for the treatment, 0 otherwise.
    """
    
    # Get the treatment groups for the cohort if less than 1 day
    df['mv_elig'] = df['MV_init_offset_d_abs'].apply(lambda x: 1 if x <= 1 else 0)
    df['rrt_elig'] = df['RRT_init_offset_d_abs'].apply(lambda x: 1 if x <= 1 else 0)
    df['vp_elig'] = df['VP_init_offset_d_abs'].apply(lambda x: 1 if x <= 1 else 0)
    
    return df

def get_demography(df):
    """Get the demography of the cohort.

    Args:
        df (pd.DataFrame): The cohort.
    """
    demo = {}
    demo["race"] = {race: df[df["race_group"] == race].shape[0] /
                         df.shape[0] for race in df["race_group"].unique() if race != "Other"}
    demo["sex"] = {
        "Male": df[df["sex_female"] == 0].shape[0] / df.shape[0],
        "Female": df[df["sex_female"] == 1].shape[0] / df.shape[0]}
    demo["eng_prof"] = {
        "Limited Proficiency": df[df["eng_prof"] == 0].shape[0] / df.shape[0],
        "Proficient": df[df["eng_prof"] == 1].shape[0] / df.shape[0]}
    # Ignore by now
    # demo["private_insurance"] = {
    #    "Medicare/Medicaid": df[df["private_insurance"] == 0].shape[0] / df.shape[0],
    #    "Other": df[df["private_insurance"] == 1].shape[0] / df.shape[0]}
    return demo


def print_demo(demo):
    demo_str = ""
    for key, value in demo.items():
        if isinstance(value, dict):
            demo_str += f"{key}: ["
            for key2, value2 in value.items():
                demo_str += f"{key2}: {round(value2*100,1)}%, "
            demo_str = demo_str[:-2] + "], "
        else:
            demo_str += f"{key}: {round(value*100,1)}%, "
    demo_str = demo_str[:-2]
    return demo_str

import pandas as pd

def read_file(path):
    df = pd.read_csv('data/cohorts/' + path + '.csv')
    return df

# Check if columns in a dataframe are the same
def columns_in_df1_not_in_df2(file1, file2):
    df1 = read_file(file1)
    df2 = read_file(file2)

    print('*'*100)
    print(f'*  Columns in {file1} not in {file2}:')
    columns_in_df1_not_in_df2 = [col for col in df1.columns if col not in df2.columns]
    print(columns_in_df1_not_in_df2)
    print('')
    print(f'*  Columns in {file2} not in {file1}:')
    columns_in_df2_not_in_df1 = [col for col in df2.columns if col not in df1.columns]
    print(columns_in_df2_not_in_df1)
    print('*'*100)

def comparte_resulting_cohort_datasets(names = ['MIMIC_all', 'eICU_all', 'MIMIC_cancer', 'eICU_cancer']):

    columns_in_df1_not_in_df2(names[0], names[1])

    columns_in_df1_not_in_df2(names[2], names[3])
