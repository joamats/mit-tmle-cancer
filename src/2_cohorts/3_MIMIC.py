import pandas as pd
import os
import numpy as np
from utils import (
    get_demography,
    print_demo,
    get_treatment_groups,
    comparte_resulting_cohort_datasets,
)

# MIMIC
df0 = pd.read_csv("data/MIMIC.csv")
print(f"{len(df0)} stays in the ICU")

# Replace ENGLISH WITH 1 AND ? WITH 0
df0.language = df0.language.apply(lambda x: 1 if x == "ENGLISH" else 0)
df0.rename(columns={"language": "eng_prof"}, inplace=True)

# Get treatment groups
df0 = get_treatment_groups(df0)

demo0 = print_demo(get_demography(df0))
print(f"({demo0})\n")

# Remove non-sepsis stays
df1 = df0[df0.sepsis3 == 1]

print(f"Removed {len(df0) - len(df1)} stays without sepsis")
demo1 = print_demo(get_demography(df1))
print(f"{len(df1)} sepsis stays \n({demo1})\n")

# Remove stays with less than 24 hours
df2 = df1[df1.los_icu >= 1]
print(f"Removed {len(df1) - len(df2)} stays with less than 24 hours")
demo2 = print_demo(get_demography(df2))
print(f"{len(df2)} stays with sepsis and LoS > 24h \n({demo2})\n")

# Remove non-adult stays
df3 = df2[df2.anchor_age >= 18]
print(f"Removed {len(df2) - len(df3)} stays with non-adult patient")
demo3 = print_demo(get_demography(df3))
print(f"{len(df3)} stays with sepsis, LoS > 24h, adult patient \n({demo3})\n")

# Remove stay where oasis_prob is NA
df4 = df3[df3.oasis_prob != np.nan]
print(f"Removed {len(df3) - len(df4)} stays with missing OASIS predictions")
demo4 = print_demo(get_demography(df4))
print(
    f"{len(df4)} stays with sepsis, LoS > 24h, adult patient, OASIS present \n({demo4})\n"
)

# Rename oasis_prob column to match eICU
df4 = df4.rename(columns={"oasis_prob": "prob_mort"})

# Remove recurrent stays
df5 = (
    df4.sort_values(by=["subject_id", "hadm_id", "icustay_seq"], ascending=True)
    .groupby("subject_id")
    .apply(lambda group: group.iloc[0, 1:])
)
print(f"Removed {len(df4) - len(df5)} recurrent stays")
demo5 = print_demo(get_demography(df5))
print(
    f"{len(df5)} stays with sepsis, LoS > 24h, adult stays, OASIS present, non-recurrent \n({demo5})\n"
)

# create 'data/cohorts/' folder if it does not exist
if not os.path.exists("data/cohorts/"):
    os.makedirs("data/cohorts/")

# Save full cohort
df5.to_csv("data/cohorts/MIMIC_all.csv", index=False)
print(f"Saving full cohort to data/cohorts/MIMIC_all.csv\n")

# Remove non-cancer patients
df6 = df5[df5.has_cancer == 1]
print(f"\nRemoved {len(df5) - len(df6)} non-cancer stays")
demo6 = print_demo(get_demography(df6))
print(
    f"{len(df6)} stays with sepsis, LoS > 24h, adult stays, OASIS present, cancer \n({demo6})\n"
)

# Save cancer cohort
df6.to_csv("data/cohorts/MIMIC_cancer.csv", index=False)
print(f"Saving cancer cohort to data/cohorts/MIMIC_cancer.csv\n")
