SELECT DISTINCT icd.patientUnitStayID, icd.ICD9Code

FROM `db_name.my_eICU.yugang` as yug

INNER JOIN (
  SELECT patientUnitStayID, ICD9Code
  FROM `db_name.eicu_crd.diagnosis`
  )
AS icd

ON icd.patientUnitStayID = yug.patientUnitStayID
