import pandas as pd
import os
import numpy as np
from utils import get_demography, print_demo, get_treatment_groups

# eICU
df1 = pd.read_csv("data/eICU.csv")
df1['eng_prof'] = np.nan

# Get treatment groups
df1 = get_treatment_groups(df1)

df1.anchor_age = df1.anchor_age.apply(lambda x: 91 if x == "> 89" else x).astype(float)
print(f"{200859} stays in eICU-CRD")

# Get the counts for the removal of non-sepsis stays
print(f"Removed {200859 - len(df1)} stays without sepsis")
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

# Remove stay where apache_prob is NA or -1
df4 = df3[df3.apache_prob != -1]
df4 = df4[df4['apache_prob'].notna()]
print(f"Removed {len(df3) - len(df4)} stays with missing APACHE predictions")
demo4 = print_demo(get_demography(df4))
print(f"{len(df4)} stays with sepsis, LoS > 24h, adult patient, APACHE present \n({demo4})\n")

# Rename apache_prob column to match MIMIC IV
df4 = df4.rename(columns={'apache_prob': 'prob_mort'})

# Remove recurrent stays
df5 = df4.sort_values(by=["patienthealthsystemstayid", "unitvisitnumber"], ascending=True).groupby(
    'patienthealthsystemstayid').apply(lambda group: group.iloc[0, 1:])
print(f"Removed {len(df4) - len(df5)} recurrent stays")
demo5 = print_demo(get_demography(df5))
print(f"{len(df5)} stays with sepsis, LoS > 24h, adult stays, APACHE present, non-recurrent \n({demo5})\n")

# create 'data/cohorts/' folder if it does not exist
if not os.path.exists('data/cohorts/'):
    os.makedirs('data/cohorts/')

# Save full cohort
df5.to_csv('data/cohorts/eICU_all.csv', index=False)
print(f"Saving full cohort to data/cohorts/eICU_all.csv\n")

# Commented out survivor cohorts -> Tristan

# # Remove patients who died in the ICU
# df4s = df4[df4.mortality_in == 0]
# print(f"Removed {len(df4) - len(df4s)} non-surviving stays")
# demo4s = print_demo(get_demography(df4s))
# print(f"{len(df4s)} stays with sepsis, LoS > 24h, non-recurrent, adult, surviving stays \n({demo4s})\n")

# # Save full surviving cohort
# df4s.to_csv('data/cohorts/eICU_all_surviving.csv', index=False)
# print(f"Saving full cohort to data/cohorts/eICU_all_surviving.csv\n")

# Remove non-cancer patients, but we take recurrent stays too
df6 = df4[df4.has_cancer == 1]
print(f"\nRemoved {len(df4) - len(df6)} non-cancer stays")
demo6 = print_demo(get_demography(df6))
print(f"{len(df6)} stays with sepsis, LoS > 24h, adult stays, APACHE present, cancer \n({demo6})\n")

# Remove recurrent stays
df7 = df6.sort_values(by=["patienthealthsystemstayid", "unitvisitnumber"], ascending=True).groupby(
    'patienthealthsystemstayid').apply(lambda group: group.iloc[0, 1:])
print(f"Removed {len(df6) - len(df7)} recurrent stays")
demo7 = print_demo(get_demography(df7))
print(f"{len(df7)} stays with sepsis, LoS > 24h, adult, APACHE present, cancer, non-recurrent stays \n({demo6})\n")

# Save cancer cohort
df7.to_csv('data/cohorts/eICU_cancer.csv', index=False)
print(f"Saving cancer cohort to data/cohorts/eICU_cancer.csv\n")

# # Remove cancer patients who died in the ICU
# df6s = df6[df6.mortality_in == 0]
# print(f"Removed {len(df6) - len(df6s)} non-surviving stays")
# demo6s = print_demo(get_demography(df6s))
# print(f"{len(df6s)} stays with sepsis, LoS > 24h, non-recurrent, adult, surviving stays \n({demo6s})\n")

# # Save full surviving cohort
# df6s.to_csv('data/cohorts/eICU_cancer_surviving.csv', index=False)
# print(f"Saving full cohort to data/cohorts/eICU_cancer_surviving.csv\n")
