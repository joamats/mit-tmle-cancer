import pandas as pd
import os
from matplotlib import pyplot as plt
import seaborn as sb

import matplotlib
matplotlib.use('TKAgg')

databases = ["all", "eicu", "mimic"]

outcomes = ["free_days_hosp_28"]

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
        plot_name = f"tmle_{db}_{out}"
        title = f"TMLE for each treatment in {db}\n for outcome {out} "

        # only keep data from outcome = mortality_in
        df_out = df_out[df_out.outcome ==  out]

        # only keep data from cohort = cancer_vsnocancer
        df_out = df_out[df_out.cohort == "cancer_vs_nocancer"]

        # discard data from prob_mort range 0 to 1
        # concatenate prob_mort_start and prob_mort_end as string
        df_out['probconcat'] = df_out['prob_mort_start'].astype(str) + '-' + df_out['prob_mort_end'].astype(str)
        df_out = df_out.loc[(df_out.probconcat != "0.0-1.0")]

        conversion_dict = dict(zip(df_out.prob_mort_start.unique(), range(4)))
        df_out.prob_mort_start = df_out.prob_mort_start.apply(lambda x: conversion_dict[x])

        # Transform into percentages
        df_out.ATE = df_out.ATE
        df_out.i_ci = df_out.i_ci
        df_out.s_ci = df_out.s_ci

        treatments = df_out.treatment.unique()
        cancers = df_out.has_cancer.unique()

        t_dict = dict(zip(["mv_elig", "rrt_elig", "vp_elig"],
                        ["IMV", "RRT", "Vasopressor(s)"]))

        fig, axes = plt.subplots(1, len(treatments),
                                sharex=True, sharey=True,
                                figsize=(8.25,3),
                                constrained_layout=True)

        fig.suptitle(title)

        for i, t in enumerate(treatments):

            df_out_temp1 = df_out[(df_out.treatment == t) & (df_out.has_cancer == 0)]
            df_out_temp2 = df_out[(df_out.treatment == t) & (df_out.has_cancer == 1)]
            
            axes[i].set(xlabel=None)
            axes[i].set(ylabel=None)
            
            axes[i].errorbar(x=df_out_temp1.prob_mort_start,
                            y=df_out_temp1.ATE,
                            yerr=((df_out_temp1.ATE- df_out_temp1.i_ci), (df_out_temp1.s_ci-df_out_temp1.ATE)),
                            fmt='-o', c='dimgray', ecolor='dimgray',
                            elinewidth=.4, linewidth=1.5, capsize=4, markeredgewidth=.4,
                            label="Non-Cancer Patients")

            axes[i].errorbar(x=df_out_temp2.prob_mort_start,
                            y=df_out_temp2.ATE,
                            yerr=((df_out_temp2.ATE- df_out_temp2.i_ci), (df_out_temp2.s_ci-df_out_temp2.ATE)),
                            fmt='-o', c='firebrick', ecolor='firebrick', elinewidth=.4,
                            linewidth=1.5, capsize=4, markeredgewidth=.4,
                            label="Cancer Patients")

            axes[i].axhline(y=0, xmin=0, xmax=1, c="black", linewidth=.7, linestyle='--')
            axes[i].set_ylim([-15, 15])
            axes[i].set_title(t_dict[t])
            axes[0].set(ylabel="ATE (mean free days)\nTreated vs. Not Treated")
            axes[2].legend(bbox_to_anchor=(1.05, 0.7), loc='upper left')
            axes[i].set_xticklabels(["0-6", "7-11", "12-21", ">21"])
            axes[i].set_xticks(range(4))

        fig.supxlabel('\nPredicted in-hospital mortality')

        # create 'results/plots/' folder if it does not exist
        if not os.path.exists('results/plots/'):
            os.makedirs('results/plots/')

        fig.savefig(f"results/plots/tmle_{db}_{out}.png", dpi=600)