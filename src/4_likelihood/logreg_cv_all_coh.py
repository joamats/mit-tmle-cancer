import pandas as pd
import numpy as np
from tqdm import tqdm
from xgboost import XGBClassifier
from sklearn.model_selection import StratifiedKFold
from sklearn.linear_model import LogisticRegressionCV as LogisticRegression
from joblib import Parallel, delayed
import os

# ignore shap warnings
import warnings
warnings.filterwarnings("ignore", message=".*The 'nopython' keyword.*")
warnings.filterwarnings("ignore")

### Constants ###
# Number of folds used in cross-validation (also used as parallel processes)
N_FOLDS = 5
# Tests per cohort
NREP = 20

### Get the data ###
# now read treatment from txt
with open("config/treatments.txt", "r") as f:
    treatments = f.read().splitlines()
treatments.remove("treatment")

# read features from list in txt
with open("config/confounders.txt", "r") as f:
    confounders = f.read().splitlines()
confounders.remove("confounder")

# Get the cohorts
with open("config/cohorts.txt", "r") as f:
    cohorts = f.read().splitlines()
cohorts.remove("cohorts")

# Get cancer types:
with open("config/cancer_types.txt", "r") as f:
    cancer_types = f.read().splitlines()
cancer_types.remove("cancer_type")


# # Function to train the Logistic Regression model, and calculate OR for a fold
def train_model(train_index, test_index, X, y, group):
    _, X_test = X.iloc[train_index,:], X.iloc[test_index,:]
    _, y_test = y.iloc[train_index], y.iloc[test_index]

    # # Fit logistic regression model
    model = LogisticRegression(max_iter=10000)
    model.fit(X_test, y_test)

    idx = X_test.columns.get_loc(group)
    param = model.coef_[0][idx]
    OR_inner = np.exp(param)

    return OR_inner

# function to calculate odds ratio
def calc_OR(shap_values, data, feature):
    control_group = shap_values[(data[feature] == 0)].mean()
    study_group = shap_values[(data[feature] == 1)].mean()

    return np.exp(study_group[feature]) / np.exp(control_group[feature])


def odds_ratio_per_cohort(data, groups, treatments, confounders, cohort, results_df):
    # Get the treatments:
    for treatment in treatments:
        print(f"Doing the prediction for treatment: {treatment}")

        for group in groups:
            print(f"Group: {group}")

            # append treatments that are not the current one to confounders
            # select X, y
            conf = confounders + [t for t in treatments if t != treatment] + [group]

            # compute OR based on all data
            X = data[conf]
            y = data[treatment]
            r = data[group]

            odds_ratios = []

            # outer loop
            for i in tqdm(range(NREP)):

                # list to append inner ORs
                ORs = []

                # normal k-fold cross validation
                kf = StratifiedKFold(n_splits=5, shuffle=True, random_state=i)

                # inner loop, in each fold
                for train_index, test_index in tqdm(kf.split(X, r)):
                    OR_inner = train_model(train_index, test_index, X, y, group)
                    ORs.append(OR_inner)
                
                odds_ratios.append(np.mean(ORs))

            # calculate confidence intervals
            CI_lower = np.percentile(odds_ratios, 2.5)
            O_R = np.percentile(odds_ratios, 50)
            CI_upper = np.percentile(odds_ratios, 97.5)

            print(f"OR (95% CI): {O_R:.3f} ({CI_lower:.3f} - {CI_upper:.3f})")

            results = { "cohort": [cohort],   
                        "group": [group],
                        "treatment": [treatment],
                        "OR": [O_R],
                        "2.5%": [CI_lower],
                        "97.5%": [CI_upper],
                        "N": [len(data)]}
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
    

def get_object_columns(df):
    return list(df.select_dtypes(include=['object']).columns)

def rename_columns(df, cofounders):
    # rename columns with ">" to "_gt_", "<" to "_lt_", "=" to "_eq_", ">=" to "_gte_", "<=" to "_lte_"
    df.columns = df.columns.str.replace('>', '_gt_')
    df.columns = df.columns.str.replace('<', '_lt_')
    df.columns = df.columns.str.replace('=', '_eq_')
    df.columns = df.columns.str.replace(' ', '')
    df.columns = df.columns.str.replace('__', '_')

    # do the changes for the confounders
    cofounders = [c.replace('>', '_gt_') for c in cofounders]
    cofounders = [c.replace('<', '_lt_') for c in cofounders]
    cofounders = [c.replace('=', '_eq_') for c in cofounders]
    cofounders = [c.replace(' ', '') for c in cofounders]
    cofounders = [c.replace('__', '_') for c in cofounders]
    return df, cofounders

databases = ["all", "eicu", "mimic"]

for db in databases:

    print('#'*30, f' {db} ' ,'#'*30)

    # create dataframes to store results
    results_template = pd.DataFrame(columns=["cohort", "group", "treatment", "OR", "2.5%", "97.5%"])
    results_df = results_template.copy()

    group = ''
    for cohort in cohorts:
        # Get the cohort data

        # Get all data
        if db == "all":
            df = pd.read_csv(f"data/cohorts/merged_all.csv")

        elif db == "eicu":
            df = pd.read_csv(f"data/cohorts/merged_eicu_all.csv")

        elif db == "mimic":
            df = pd.read_csv(f"data/cohorts/merged_mimic_all.csv")

        else:
            print(f"Error: {db}, should be all, eicu or mimic")
            break

        if cohort == 'cancer_vs_nocancer':

            group = 'has_cancer'
            cohort = 'cancer'

            check = check_columns_in_df(df, confounders)
            if check == False:
                continue

            initial_columns = confounders + treatments + [group]
            df = df[initial_columns]

            # Get categorical columns
            categorical_columns = get_object_columns(df)
            print(f"Converting categorical columns: {categorical_columns}")

            # convert categorical columns to dummies and get the new column names
            df = pd.get_dummies(df, columns=categorical_columns, drop_first=False)

            # remove categorical columns from confounders list and add the new columns in the dataset
            one_hot_columns = [c for c in df.columns if c not in initial_columns]

            # update confounders list:
            confounders_aux = [c for c in confounders if c not in categorical_columns] + one_hot_columns
            
            df, confounders_aux = rename_columns(df, confounders_aux)
            
            results_df_aux = odds_ratio_per_cohort(df, [group], treatments, confounders_aux, cohort+'_vs_noncancer', results_template)
            results_df = pd.concat([results_df, results_df_aux], ignore_index=True)

        elif cohort == 'cancer_type':
            # Get the dataset for each cancer type
            for cancer_type in cancer_types:
                
                print(f"Getting data for cancer type: {cancer_type}")

                group = cancer_type
                cohort = cancer_type

                # print patients with has_cancer = 0 and group_hematological = 1
                sub_df = df[(df['has_cancer'] == 0) | (df[group] == 1)]

                check = check_columns_in_df(sub_df, confounders)
                if check == False:
                    continue
                
                initial_columns = confounders + treatments + [group]
                sub_df = sub_df[initial_columns]

                # Get categorical columns
                categorical_columns = get_object_columns(sub_df)
                print(f"Converting categorical columns: {categorical_columns}")

                # convert categorical columns to dummies and get the new column names
                sub_df = pd.get_dummies(sub_df, columns=categorical_columns, drop_first=False)

                # remove categorical columns from confounders list and add the new columns in the dataset
                one_hot_columns = [c for c in sub_df.columns if c not in initial_columns]

                # update confounders list:
                confounders_aux = [c for c in confounders if c not in categorical_columns] + one_hot_columns

                sub_df, confounders_aux = rename_columns(sub_df, confounders_aux)

                results_df_aux = odds_ratio_per_cohort(sub_df, [group], treatments, confounders_aux, cohort+'_vs_others', results_template)
                results_df = pd.concat([results_df, results_df_aux], ignore_index=True)

        else:
            print(f"Error: {cohort} should be cancer_vs_nocancer or cancer_type or both of them")
            continue

    # save results as we go
    try:
        results = f"logreg_cv_all_coh_{db}"
        results_df.to_csv(f"results/models/{results}.csv", index=False)
    # if folder does not exist, create it and save results
    except:
        try:
            os.mkdir("results/models")
            results_df.to_csv(f"results/models/{results}.csv", index=False)
        except:
            # setting contains a slash, so we need to create the folder
            os.mkdir(f"results/models/{results.split('/')[0]}")
            results_df.to_csv(f"results/models/{results}.csv", index=False)
            