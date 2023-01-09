import pandas as pd
import numpy as np

df0 = pd.read_csv("data/eICU.csv")
print(f"200859 stays in the ICU")
print(f"Removed {200859 - len(df0)} stays without sepsis")
print(f"{len(df0)} sepsis stays")

df1 = df0[df0.has_cancer == 1]
print(f"Removed {len(df0) - len(df1)} stays without active cancer")
print(f"{len(df1)} patients with active cancer and sepsis")

df2 = df1[df1.unitvisitnumber == 1]
print(f"Removed {len(df1) - len(df2)} non-first (relative) stays")
print(f"{len(df2)} patients with active cancer, sepsis, and on first stay")

df2.to_csv('data/cohort_eICU.csv')
