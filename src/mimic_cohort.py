import pandas as pd

df0 = pd.read_csv("data/MIMIC.csv")
print(f"{len(df0)} stays in the ICU")

df1 = df0[df0.has_cancer == 1]
print(f"Removed {len(df0) - len(df1)} stays without active cancer")
print(f"{len(df1)} stays with active cancer")

df2 = df1.drop_duplicates(subset=['subject_id'], keep='first')
print(f"Removed {len(df1) - len(df2)} non-first (relative) stays")
print(f"{len(df2)} patients with active cancer and on first stay")

df3 = df2[df2.sepsis3 == 1]
print(f"Removed {len(df2) - len(df3)} stays without sepsis")
print(f"{len(df3)} patients with active cancer, sepsis, and on first stay")

df3.to_csv('data/cohort_MIMIC.csv')