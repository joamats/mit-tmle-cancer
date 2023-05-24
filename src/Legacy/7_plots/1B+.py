import pandas as pd
from matplotlib import pyplot as plt
import numpy as np

import matplotlib
matplotlib.use('TKAgg')

treatments = {"mech_vent": "Mechanical Ventilation",
              "rrt": "RRT",
              "vasopressor": "Vasopressor(s)"}

cancers = {'solid': "Solid",
           'hematological': "Hematological",
           'metastasized': "Metastasized"
          }
 
yy = range(3, 0, -1)

fig, ax = plt.subplots(2, 3, sharex=False, sharey=False, figsize=(10, 5))                           

fig.suptitle(f"Likelihood of receiving an Intervention as Cancer Patient of a certain Type compared to Non-Cancer Patients")

df_hist = pd.read_csv("data/cohorts/merged_all.csv")

df = pd.read_csv("results/glm/1B.csv")
df = df.rename(columns={'Unnamed: 0': 'Cancer'})

df = df.replace(regex={r'(^.*solid.*$)': 'solid',
                       r'^(^.*hematological.*$)': 'hematological',
                       r'^(^.*metastasized.*$)': 'metastasized'})

for i, (t, t_name) in enumerate(treatments.items()):

    for (cancer, cancer_name), y in zip(cancers.items(), yy): 

        row = df[(df.treatment == t) & (df.Cancer == cancer)]

        ci = [row['OR'] - row['CI_low'], row['CI_high'] - row['OR']]

        ax[0,i].errorbar(x=row['OR'], y=y, xerr=ci, \
                        ecolor="tab:red", color="tab:red", marker='o', \
                        capsize=3, \
                        linewidth=1, \
                        markersize=5, mfc="tab:red", mec="tab:red")
        
        ax[1,i].barh(y,
                     width = df_hist[df_hist[t] == 1][["group_" + cancer]].sum()/df_hist[["group_" + cancer]].sum()*100,
                     color="dimgray", height=.2)

    ax[0,i].set_title(t_name)
    ax[0,i].axvline(x=1, linewidth=0.8, linestyle='--', color='black')
    ax[0,i].set_xlabel('Odds Ratio (95% CI)')
    ax[1,i].set_xlabel('% of Treated Patients')
    ax[0,i].set_xlim([0.1, 1.9])
    ax[1,i].set_xlim([0, 100])
    ax[0,0].set_ylabel(ylabel='Cancer Type')
    ax[0,i].set_yticks(ticks= yy, labels=cancers.values())
    ax[1,i].set_yticks(ticks= yy, labels=cancers.values())

plt.tight_layout()

fig.savefig(f'results/glm/1B+.png', dpi=300)