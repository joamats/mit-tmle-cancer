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