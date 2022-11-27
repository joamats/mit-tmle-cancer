SELECT DISTINCT icd.patientunitstayid, icd.ICD9Code

FROM `db_name.my_eICU.yugang` as yug

INNER JOIN (
  SELECT patientunitstayid, ICD9Code
  FROM `db_name.eicu_crd.diagnosis`
  )
AS icd

ON icd.patientunitstayid = yug.patientunitstayid