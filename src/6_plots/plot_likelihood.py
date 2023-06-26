import pandas as pd
from matplotlib import pyplot as plt

import matplotlib
matplotlib.use('TKAgg')


def plot_results(filename, model_name):

    # load data from csv file into pandas dataframe
    data = pd.read_csv(f"results/models/{filename}.csv")

    # group data by treatment type
    treatment_groups = data.groupby("treatment")

    cancer_names = ['All Types','Solid', 'Hematological', 'Metastasized']

    # Set the figure and axes
    fig, axes = plt.subplots(1, 3,
                            sharex=True, sharey=True,
                            figsize=(9, 3.5))

    fig.suptitle(f'{model_name}: Likelihood of Treatment Initiation')

    # create dictionary of name for each treatment group
    treatment_names = {"mv_elig": "IMV",
                       "rrt_elig": "RRT",
                       "vp_elig": "Vasopressor(s)"
    }

    # set common horizontal line at 1 for all subplots
    for i, ax in enumerate(axes):
        ax.axvline(x=1, linewidth=0.8, linestyle='--', color='black')

    # loop over treatment groups and create a subplot for each
    for (treatment, group), ax in zip(treatment_groups, axes):
        # plot odds ratios with confidence intervals as error bars
        ax.errorbar(group["OR"],
                    group["cohort"]*3,
                    xerr=[group["OR"] - group["2.5%"], group["97.5%"] - group["OR"]],
                    fmt='o',
                    linewidth=.5,
                    capsize=3)
        # set subplot title
        ax.set_title([treatment_names[treatment]][0])
        # set yrange to breath a bit
        # ax.set_ylim([1.5, 13.5])
        # set xrange to
        ax.set_xlim([.35, 1.65])
        # set yticks in string format
        # ax.set_yticks([3,6,9,12])
        ax.set_yticklabels(cancer_names)
        ax.set_xlabel("Favours Non-Cancer | Favours Cancer        ",
                    fontsize=8, labelpad=5, color='gray')
        

    fig.supxlabel('Odds Ratio (95% CI)')
    fig.supylabel('Cancer Type')
    plt.tight_layout()

    # Save the figure
    #fig.savefig(f"results/plots/{filename}.png", dpi=300, bbox_inches="tight")
    fig.savefig(f"results/plots/{filename}.jpeg", dpi=600, bbox_inches="tight")

filenames = ["logreg_cv_all_coh_all",
             "logreg_cv_all_coh_mimic",
             "logreg_cv_all_coh_eicu", 
             "xgb_cv_all_coh_all",
             "xgb_cv_all_coh_mimic",
             "xgb_cv_all_coh_eicu"]

model_names = ["Logistic Regression All",
               "Logistic Regression MIMIC-IV",
               "Logistic Regression eICU-CRD",
               "XGBoost All",
               "XGBoost MIMIC-IV",
               "XGBoost eICU-CRD"]

for f, m in zip(filenames, model_names):
    plot_results(f, m)