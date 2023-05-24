import pandas as pd
from tableone import TableOne

data = pd.read_csv('data/cohorts/merged_all.csv')

data['los_icu_dead']     = data[data.mortality_in == 1]['los_icu']
data['los_icu_survived'] = data[data.mortality_in == 0]['los_icu']

decimals = {"anchor_age": 0, "los_icu_dead": 2, "los_icu_survived": 2, "SOFA": 0, "CCI": 0}
groupby = ["has_cancer"]
nonnormal = ["anchor_age", "los_icu_dead", "los_icu_survived", "SOFA", "CCI"]

table1 = TableOne(data, columns=["anchor_age", "los_icu_dead", "los_icu_survived", "SOFA", "CCI"],
                  categorical=[], decimals=decimals,
                  groupby=["has_cancer"],nonnormal=nonnormal,
                  pval=True, dip_test=True, normal_test=True, tukey_test=True)

print(table1)

table2 = TableOne(data, columns=["anchor_age", "los_icu_dead", "los_icu_survived", "SOFA", "CCI"],
                  categorical=[], decimals=decimals,
                  groupby=["source"],nonnormal=nonnormal,
                  pval=True, dip_test=True, normal_test=True, tukey_test=True)

print(table2)