import pandas as pd
import numpy as np

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

    df = df.drop(["vent", "rrt", "vasopressor",
                  "vent_1", "vent_2", "vent_3", "vent_4", "vent_5", "vent_6",
                  "rrt_1", "pressor_1", "pressor_2", "pressor_3", "pressor_4"],
                  axis=1)

    return df
