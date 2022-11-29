SELECT DISTINCT icd.*

FROM physionet-data.mimiciv_derived.icustay_detail AS icu 
INNER JOIN physionet-data.mimiciv_derived.sepsis3 AS s3
ON s3.stay_id = icu.stay_id
AND s3.sepsis3 IS TRUE

LEFT JOIN physionet-data.mimiciv_hosp.patients AS pat
ON icu.subject_id = pat.subject_id

INNER JOIN (
  SELECT subject_id, icd_code, icd_version
  FROM `physionet-data.mimiciv_hosp.diagnoses_icd`
  )
AS icd


ON icd.subject_id = icu.subject_id

where (icu.first_icu_stay is true and icu.first_hosp_stay is true)
