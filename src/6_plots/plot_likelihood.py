import matplotlib
import pandas as pd
from matplotlib import pyplot as plt

matplotlib.use("TKAgg")

# Say, "the default sans-serif font is Arial"
matplotlib.rcParams["font.sans-serif"] = "Arial"
# Then, "ALWAYS use sans-serif fonts"
matplotlib.rcParams["font.family"] = "sans-serif"


def plot_results(filename, model_name):
    # load data from csv file into pandas dataframe
    data = pd.read_csv(f"results/models/{filename}.csv")

    # group data by treatment type
    filtered_data = data[data["treatment"] != "rrt_elig"]  # filter out rrt_elig
    treatment_groups = filtered_data.groupby("treatment")

    cancer_names = ["All Types", "Solid", "Hematological", "Metastasized"]

    # Set the figure and axes
    # fig, axes = plt.subplots(1, 3, sharex=True, sharey=True, figsize=(9, 3.5)) # for 3 subplots
    fig, axes = plt.subplots(
        2, 1, sharex=True, sharey=True, figsize=(6, 7)
    )  # for 2 subplots

    fig.suptitle(f"{model_name}: Likelihood of Treatment Initiation")

    # create dictionary of name for each treatment group
    treatment_names = {
        "mv_elig": "IMV",
        # "rrt_elig": "RRT",
        "vp_elig": "Vasopressor(s)",
    }

    # set common horizontal line at 1 for all subplots
    for i, ax in enumerate(axes):
        ax.axvline(x=1, linewidth=0.8, linestyle="--", color="black")

    # loop over treatment groups and create a subplot for each
    for (treatment, group), ax in zip(treatment_groups, axes):
        # plot odds ratios with confidence intervals as error bars
        ax.errorbar(
            group["OR"],
            group["cohort"] * 3,
            xerr=[group["OR"] - group["2.5%"], group["97.5%"] - group["OR"]],
            fmt="o",
            linewidth=0.5,
            capsize=3,
        )
        # set subplot title
        ax.set_title([treatment_names[treatment]][0])
        # set yrange to breath a bit
        # ax.set_ylim([1.5, 13.5])
        # set xrange to
        ax.set_xlim([0.75, 1.25])
        # set yticks in string format
        # ax.set_yticks([3,6,9,12])
        ax.set_yticklabels(cancer_names)
        ax.set_xlabel(
            "            Treatment less likely  |  No treatment more likely       ",
            fontsize=8,
            labelpad=5,
            color="gray",
        )

    fig.supxlabel("                                Odds Ratio (95% CI)")
    fig.supylabel("Cancer Type")
    plt.tight_layout()

    # Save the figure
    fig.savefig(f"results/plots/{filename}.png", dpi=1200, bbox_inches="tight")
    # fig.savefig(f"results/plots/{filename}.jpeg", dpi=600, bbox_inches="tight")


filenames = [
    # "logreg_cv_all_coh_all",
    # "logreg_cv_all_coh_mimic",
    # "logreg_cv_all_coh_eicu",
    "xgb_cv_all_coh_all",
    "xgb_cv_all_coh_mimic",
    "xgb_cv_all_coh_eicu",
]

model_names = [
    # "Logistic Regression All",
    # "Logistic Regression MIMIC-IV",
    # "Logistic Regression eICU-CRD",
    "XGBoost Models",
    "XGBoost Models",
    "XGBoost Models",
]

for f, m in zip(filenames, model_names):
    plot_results(f, m)
