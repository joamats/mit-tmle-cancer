import pandas as pd
from matplotlib import pyplot as plt
import numpy as np

import matplotlib
matplotlib.use('TKAgg')

treatments = {"mech_vent": "Mechanical Ventilation",
              "rrt": "RRT",
              "vasopressor": "Vasopressor(s)"}

cancers = {'solid': "Solid",
           'hematological': "Hem.",
           'metastasized': "Met."
          }
 
yy = range(3, 0, -1)

fig, ax = plt.subplots(1, 3, sharex=False, sharey=False, figsize=(10, 3))                           

fig.suptitle(f"Likelihood of receiving an Intervention as Cancer Patient of a certain Type compared to Non-Cancer")

df = pd.read_csv("results/glm/1B.csv")
df = df.rename(columns={'Unnamed: 0': 'Cancer'})

df = df.replace(regex={r'(^.*solid.*$)': 'solid',
                       r'^(^.*hematological.*$)': 'hematological',
                       r'^(^.*metastasized.*$)': 'metastasized'})

for i, (t, t_name) in enumerate(treatments.items()):

    for (cancer, cancer_name), y in zip(cancers.items(), yy): 

        row = df[(df.treatment == t) & (df.Cancer == cancer)]

        ci = [row['OR'] - row['CI_low'], row['CI_high'] - row['OR']]

        ax[i].errorbar(x=row['OR'], y=y, xerr=ci, \
                        ecolor="tab:red", color="tab:red", marker='o', \
                        capsize=3, \
                        linewidth=1, \
                        markersize=5, mfc="tab:red", mec="tab:red")
        
    ax[i].set_title(t_name)
    ax[i].axvline(x=1, linewidth=0.8, linestyle='--', color='black')
    ax[i].set_xlabel('Odds Ratio (95% CI)')
    ax[i].set_xlim([0.1, 1.9])
    ax[0].set_ylabel(ylabel='Cancer Type')
    ax[i].set_yticks(ticks= yy, labels=cancers.values())

plt.tight_layout()

fig.savefig(f'results/glm/1B.png', dpi=300)