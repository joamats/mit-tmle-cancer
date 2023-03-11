import pandas as pd
from matplotlib import pyplot as plt
import seaborn as sb

import matplotlib
matplotlib.use('TKAgg')

df_raw = pd.read_csv("results/tmle/SAs/2B_SA.csv")

# Transform into percentages
df_raw.psi = df_raw.psi * 100
df_raw.i_ci = df_raw.i_ci * 100
df_raw.s_ci = df_raw.s_ci * 100

t_dict = dict(zip(["mech_vent", "rrt", "vasopressor"],
                ["Mechanical Ventilation", "RRT", "Vasopressor(s)"]))

s_dict = {"mech_vent": "no COPD, no Asthma Patients",
          "rrt": "no CKD > Stage 2",
          "vasopressor": "no CHF, no Hypertension"
         }

for s, s_name in s_dict.items():

    # Limit to our sensitivity analysis
    df = df_raw[df_raw.sens == s]

    fig, axes = plt.subplots(1, len(t_dict.keys()), sharex=True,  figsize=(8.5,2.6), constrained_layout=True)

    fig.suptitle(f'Effect of Invasive Interventions on Mortality, Cancer vs. Non-Cancer Patients,\n{s_name}')

    for i, t in enumerate(t_dict.keys()):

        df_temp1 = df[(df.treatment == t) ]

        axes[i].set(xlabel=None)
        axes[i].set(ylabel=None)

        axes[i].errorbar(x=df_temp1.cancer_type, y=df_temp1.psi, 
                        yerr=((df_temp1.psi- df_temp1.i_ci), (df_temp1.s_ci-df_temp1.psi)),
                        fmt='-o', c='tab:red', ecolor='tab:red',
                        elinewidth=.4, linewidth=1.5, capsize=4, markeredgewidth=.4,
                        label="Cancer\nPatients")

        axes[i].axhline(y=0, xmin=0, xmax=1, c="black", linewidth=.7, linestyle='--')
        axes[i].set_ylim([-30, 30])
        axes[i].set_title(t_dict[t])
        axes[0].set(ylabel="ATE (%)\nTreated vs. Not Treated")
        axes[2].legend(bbox_to_anchor=(1.05, 0.7), loc='upper left')

        axes[i].set_xticklabels(["Solid", "Hem.", "Met."])

    fig.supxlabel(  'Cancer Type          ')


    fig.savefig(f"results/tmle/SAs/2B_{s}.png", dpi=300)

