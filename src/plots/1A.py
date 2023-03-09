import pandas as pd
from matplotlib import pyplot as plt
import numpy as np

import matplotlib
matplotlib.use('TKAgg')

treatments = {"mech_vent": "Mechanical Ventilation",
              "rrt": "RRT",
              "vasopressor": "Vasopressor(s)"}

sofas = {0: "0 - 3",
         4: "4 - 6",
         7: "7 - 10",
         11: "11 >"}


yy = range(4, 0, -1)


fig, ax = plt.subplots(1, 3, sharex=True, sharey=False, figsize=(10, 3))
                           

fig.suptitle(f"Likelihood of receiving an Intervention as Cancer Patient compared Non-Cancer")
        
df = pd.read_csv("results/glm/1A.csv")

for i, (t, t_name) in enumerate(treatments.items()):

    for (sofa_min, sofa), y in zip(sofas.items(), yy): 

        row = df[(df.treatment == t) & (df.sofa_min == sofa_min)]

        ci = [row['OR'] - row['CI_low'], row['CI_high'] - row['OR']]

        # if y == 6:
        #     lbl = d
        # else:
        #     lbl = None

        ax[i].errorbar(x=row['OR'], y=y, xerr=ci, \
                        ecolor="tab:red", color="tab:red", marker='o', \
                        capsize=3, \
                        #label = lbl, \
                        linewidth=1, \
                        markersize=5, mfc="tab:red", mec="tab:red")

    ax[i].set_title(t_name)
    ax[i].axvline(x=1, linewidth=0.8, linestyle='--', color='black')
    ax[i].set_xlabel('Odds Ratio (95% CI)')
    ax[i].set_xlim([0.2, 1.8])
    ax[0].set_ylabel(ylabel='SOFA Range')
    ax[i].set_yticks(ticks= yy, labels=sofas.values())

plt.tight_layout()

fig.savefig(f'results/glm/1A.png', dpi=300)