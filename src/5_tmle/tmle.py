import pandas as pd
import numpy as np
import os

from tmle import tmle
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from sklearn.neural_network import MLPClassifier
from xgboost import XGBClassifier


# Define the SL library
SL_library = [
    LogisticRegression(),
    RandomForestClassifier(),
    MLPClassifier(),
    XGBClassifier()
]


setting = "sens/xgb_cv_all_coh"

### Constants ###
# Number of folds used in cross-validation (also used as parallel processes)
N_FOLDS = 5
# Tests per cohort
NREP = 50

### Get the data ###
# now read treatment from txt
with open("config/treatments.txt", "r") as f:
    treatments = f.read().splitlines()
treatments.remove("treatment")

# read features from list in txt
with open("config/confounders.txt", "r") as f:
    confounders = f.read().splitlines()
confounders.remove("confounder")

# read the cofounders from list in txt
with open("config/outcomes.txt", "r") as f:
    outcomes = f.read().splitlines()
outcomes.remove("outcome")

# Get the cohorts
with open("config/cohorts.txt", "r") as f:
    cohorts = f.read().splitlines()
cohorts.remove("cohorts")

# Get cancer types:
with open("config/cancer_types.txt", "r") as f:
    cancer_types = f.read().splitlines()
cancer_types.remove("cancer_type")


def calculate_tmle(A, Y, W, SL_library, Q_SL_library=None):
    """
    Calculates the TMLE estimate for the average treatment effect (ATE).
    :param A: Treatment variable
    :param Y: Outcome variable
    :param W: Confounder variables
    :param SL_library: List of sklearn estimators for the Super Learner
    :param Q_SL_library: List of sklearn estimators for the Super Learner
    :return: TMLE estimate for the ATE
    """
    
    if not(Q_SL_library):
        Q_SL_library = SL_library

    # Define the TMLE model
    tmle_model = tmle(Y=Y, A=A, W=W, family="binomial", gbound=[0.05, 0.95], g_SL_library=SL_library, Q_SL_library=SL_library)

    # Run TMLE
    result = tmle_model.run()

    # Access the results
    print("ATE Estimate:", result.ATE)
    print("ATE Confidence Interval:", result.ATE_confidence_interval)
    print("p-value:", result.p_value)

    print('Result')

    return result


def calculate_tmle_per_cohort(data, groups, treatments, outcomes, confounders, cohort, results_df):
    for outcome in outcomes:
        # Get the treatments:
        for treatment in treatments:
            print(f"Doing the prediction for treatment: {treatment}")

            for group in groups:
                print(f"Group: {group}")
                data = data[data[group] == 1].drop(group, axis=1)

                # append treatments that are not the current one to confounders
                # select X, y
                conf = confounders + [t for t in treatments if t != treatment] 

                # compute OR based on all data
                W = data[conf]
                A = data[treatment]
                Y = data[outcome]

                results = calculate_tmle(A, Y, W, SL_library, Q_SL_library=None)

                results = {
                    'outcome': [outcome],
                    'treatment': [treatment],
                    'cohort': [group],
                    'race':np.nan,
                    # Add sev_min and sev_max
                    'prob_mort_start':np.nan,
                    'prob_mort_end':np.nan,
                    'psi': results.ATE.psi,
                    'i_ci': results.ATE.CI[0],
                    's_ci': results.ATE.CI[1],
                    'pvalue': results.ATE.pvalue,
                    'n': len(data),
                    'SL_libraries': " ".join(SL_library),
                    'Q_weights': " ".join(results.Qinit.coef),
                    'g_weights': " ".join(results.g.coef)
                }

                results = pd.DataFrame.from_dict(results)
                
                # append results to dataframe
                results_df = pd.concat([results_df, results], ignore_index=True)

        return results_df



def check_columns_in_df(df, columns):
    cols_not_in_df = []
    for col in columns:
        if col not in df.columns:
            cols_not_in_df.append(col)
            print(f"Column {col} not in df")
    if len(cols_not_in_df) > 0:
        print(f"This cofounders are not in the df: {cols_not_in_df}")
        return False
    else:
        return True


# create dataframes to store results
results_template = pd.DataFrame(columns=["outcome",
                                "treatment",
                                "cohort",
                                "race",
                                "prob_mort_start",
                                "prob_mort_end",
                                "psi",
                                "i_ci",
                                "s_ci",
                                "pvalue",
                                "n",
                                "SL_libraries",
                                "Q_weights",
                                "g_weights"])
results_df = results_template.copy()

group = ''
for cohort in cohorts:
    # Get the cohort data
    if cohort == 'cancer_vs_nocancer':
        # Get all data
        df = pd.read_csv(f"data/cohorts/merged_all.csv")
        group = 'has_cancer'
        cohort = 'cancer'

        """ Get provisional cofounders from the dataframe using the dtypes and excluding the treatments """
        confounders = [col for col in df.columns if df[col].dtype in ['float64', 'int64'] and col not in treatments]
        print(f"Confounders: {confounders}")
        check = check_columns_in_df(df, confounders)
        if check == False:
            continue

        results_df_aux = calculate_tmle_per_cohort(df, [group], treatments, confounders, outcomes, cohort+'_vs_others', results_template)
        results_df = pd.concat([results_df, results_df_aux], ignore_index=True)

    elif cohort == 'cancer_type':
        # Get the dataset for each cancer type
        for cancer_type in cancer_types:
            group = cancer_type
            print(f"Getting data for cancer type: {cancer_type}")
            df = pd.read_csv(f"data/cohorts/merged_cancer.csv")
            cohort = cancer_type

            """ Get provisional cofounders from the dataframe using the dtypes and excluding the treatments """
            confounders = [col for col in df.columns if df[col].dtype in ['float64', 'int64'] and col not in treatments]
            print(f"Confounders: {confounders}")
            check = check_columns_in_df(df, confounders)
            if check == False:
                continue
                
            results_df_aux = calculate_tmle_per_cohort(df, [group], treatments, confounders, outcomes, cohort+'_vs_others', results_template)
            results_df = pd.concat([results_df, results_df_aux], ignore_index=True)

    else:
        print(f"Error: {cohort} should be cancer_vs_nocancer or cancer_type or both of them")
        continue

# save results as we go
try:
    results_df.to_csv(f"results/models/{setting}.csv", index=False)
# if folder does not exist, create it and save results
except:
    try:
        os.mkdir("results/models")
        results_df.to_csv(f"results/models/{setting}.csv", index=False)
    except:
        # setting contains a slash, so we need to create the folder
        os.mkdir(f"results/models/{setting.split('/')[0]}")
        results_df.to_csv(f"results/models/{setting}.csv", index=False)
        