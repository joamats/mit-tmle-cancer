import os

import matplotlib
import pandas as pd
import seaborn as sb
from matplotlib import pyplot as plt

matplotlib.use("TKAgg")
# Say, "the default sans-serif font is Arial"
matplotlib.rcParams["font.sans-serif"] = "Arial"
# Then, "ALWAYS use sans-serif fonts"
matplotlib.rcParams["font.family"] = "sans-serif"

databases = ["all", "eicu", "mimic"]

outcomes = ["mortality_in"]  # "mortality_in", "odd_hour", "comb_noso"

for db in databases:
    # Get all data
    if db == "all":
        df = pd.read_csv(f"results/tmle/tmle_results_all.csv")
    elif db == "eicu":
        df = pd.read_csv(f"results/tmle/tmle_results_eicu.csv")
    elif db == "mimic":
        df = pd.read_csv(f"results/tmle/tmle_results_mimic.csv")
    else:
        print(f"Error: {db}, should be all, eicu or mimic")
        break

    for out in outcomes:
        df_out = df
        # plot_name = f"tmle_{db}_{out}"
        title = f"TMLE Models: Average Treatment Effect (ATE)\n"

        # only keep data from outcome = mortality_in
        df_out = df_out[df_out.outcome == out]

        # only keep data from cohort = cancer_vsnocancer
        df_out = df_out[df_out.cohort != "cancer_vs_nocancer"]

        # discard data from prob_mort range 0 to 1
        # concatenate prob_mort_start and prob_mort_end as string
        df_out["probconcat"] = (
            df_out["prob_mort_start"].astype(str)
            + "-"
            + df_out["prob_mort_end"].astype(str)
        )
        df_out = df_out.loc[(df_out.probconcat == "0.0-1.0")]

        conversion_dict = dict(zip(df_out.prob_mort_start.unique(), range(4)))
        df_out.prob_mort_start = df_out.prob_mort_start.apply(
            lambda x: conversion_dict[x]
        )

        # Transform into percentages
        df_out.ATE = df_out.ATE * 100
        df_out.i_ci = df_out.i_ci * 100
        df_out.s_ci = df_out.s_ci * 100

        # treatments = df_out.treatment.unique() # with rrt_elig
        df_out = df_out[df_out["treatment"] != "rrt_elig"]  # filter out rrt_elig
        treatments = df_out.treatment.unique()  # without rrt_elig
        cancers = df_out.has_cancer.unique()

        t_dict = dict(
            zip(["mv_elig", "vp_elig"], ["IMV", "Vasopressor(s)"])
            # zip(["mv_elig", "rrt_elig", "vp_elig"], ["IMV", "RRT", "Vasopressor(s)"])
        )

        fig, axes = plt.subplots(
            len(treatments),
            1,
            sharex=True,
            sharey=True,
            figsize=(4, 6),
            constrained_layout=True,
        )

        fig.suptitle(title)

        for i, t in enumerate(treatments):
            # df_out_temp1 = df_out[(df_out.treatment == t) & (df_out.has_cancer == 0)]
            df_out_temp2 = df_out[(df_out.treatment == t) & (df_out.has_cancer == 1)]

            axes[i].set(xlabel=None)
            axes[i].set(ylabel=None)

            axes[i].errorbar(
                x=df_out_temp2.cohort,
                y=df_out_temp2.ATE,
                yerr=(
                    (df_out_temp2.ATE - df_out_temp2.i_ci),
                    (df_out_temp2.s_ci - df_out_temp2.ATE),
                ),
                fmt="o",  # Changed 'fmt' parameter to from '-o' to 'o' to remove the lines
                c="firebrick",
                ecolor="firebrick",
                elinewidth=0.4,
                linewidth=1.5,
                capsize=4,
                markeredgewidth=0.4,
                label="Cancer Patients",
            )

            axes[i].axhline(
                y=0, xmin=0, xmax=1, c="black", linewidth=0.7, linestyle="--"
            )
            axes[i].set_ylim([-20, 20])
            axes[i].set_title(t_dict[t])
            # axes[0].set(ylabel="ATE change in outcome (%)\n Treated vs. Not Treated")
            # for 3 subplots
            # axes[2].legend(bbox_to_anchor=(1.05, 0.7), loc="upper left")
            axes[i].set_xticklabels(["Solid", "Hematologic", "Metast."])
            axes[i].set_xticks(range(3))

        fig.supxlabel("\n              Cancer type")
        fig.supylabel("\nATE change in outcome (%)\n    Treated vs. Not Treated")

        # create 'results/plots/' folder if it does not exist
        if not os.path.exists("results/plots/"):
            os.makedirs("results/plots/")

        fig.savefig(f"results/plots/tmle_types_{db}_{out}.png", dpi=1200)
