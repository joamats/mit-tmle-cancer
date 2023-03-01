import pandas as pd
from utils import get_demography, print_demo

# eICU
df1 = pd.read_csv("data/eICU.csv")
df1.anchor_age = df1.anchor_age.apply(lambda x: 91.4 if x == "> 89" else x).astype(float)
print(f"{200859} stays in the ICU")

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

# Remove recurrent stays
df4 = df3.sort_values(by=["patienthealthsystemstayid", "unitvisitnumber"], ascending=True).groupby(
    'patienthealthsystemstayid').apply(lambda group: group.iloc[0, 1:])
print(f"Removed {len(df3) - len(df4)} recurrent stays")
demo4 = print_demo(get_demography(df4))
print(f"{len(df4)} stays with sepsis, LoS > 24h, non-recurrent, adult stays \n({demo4})\n")

# Save full cohort
df4.to_csv('data/cohorts/MIMIC_all.csv')
print(f"Saving full cohort to data/cohorts/eICU_all.csv\n")


# Remove non-cancer patients, but we take recurrent stays too
df5 = df3[df3.has_cancer == 1]
print(f"\nRemoved {len(df3) - len(df5)} non-cancer stays")
demo5 = print_demo(get_demography(df5))
print(f"{len(df5)} stays with sepsis, LoS > 24h, adult stays, cancer \n({demo5})\n")

# Remove recurrent stays
df6 = df5.sort_values(by=["patienthealthsystemstayid", "unitvisitnumber"], ascending=True).groupby(
    'patienthealthsystemstayid').apply(lambda group: group.iloc[0, 1:])
print(f"Removed {len(df5) - len(df6)} recurrent stays")
demo6 = print_demo(get_demography(df6))
print(f"{len(df6)} stays with sepsis, cancer, LoS > 24h, non-recurrent, adult stays \n({demo6})\n")

# Save cancer cohort
df5.to_csv('data/cohorts/MIMIC_cancer.csv')
print(f"Saving cancer cohort to data/cohorts/eICU_cancer.csv\n")

