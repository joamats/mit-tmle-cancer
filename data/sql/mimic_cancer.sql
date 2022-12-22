SELECT DISTINCT
    icu.subject_id
  , icu.hadm_id
  , icu.stay_id
  , icu.gender
  , pat.anchor_age
  , icu.race
  , weight.weight_admit
  , adm.adm_type
  , adm.adm_elective
  , ad.discharge_location AS discharge_location
  , icu.dod
  , ABS(TIMESTAMP_DIFF(pat.dod,icu.icu_outtime,DAY)) AS dod_icuout_offset_days
  , pat.anchor_year_group
  , icu.los_hospital
  , icu.los_icu
  , icu.first_hosp_stay
  , icu.icustay_seq
  , icu.first_icu_stay
  , s3.sepsis3 AS sepsis3
  , charlson.charlson_comorbidity_index
  , sf.SOFA
  , oa.oasis AS OASIS
  , InvasiveVent.InvasiveVent_hr AS mech_vent
  , rrt.rrt
  , (pressor.stay_id = icu.stay_id) AS vasopressor
  , cancer.cancer_types

-- ICU stays
FROM physionet-data.mimiciv_derived.icustay_detail
AS icu 

-- Sepsis Patients
INNER JOIN physionet-data.mimiciv_derived.sepsis3
AS s3
ON s3.stay_id = icu.stay_id
AND s3.sepsis3 = TRUE

-- Age
LEFT JOIN physionet-data.mimiciv_hosp.patients
AS pat
ON icu.subject_id = pat.subject_id

-- SOFA
LEFT JOIN physionet-data.mimiciv_derived.first_day_sofa
AS sf
ON icu.stay_id = sf.stay_id 

-- Weight
LEFT JOIN physionet-data.mimiciv_derived.first_day_weight
AS weight
ON icu.stay_id = weight.stay_id 

-- Admissions
LEFT JOIN physionet-data.mimiciv_hosp.admissions
AS ad
ON icu.hadm_id = ad.hadm_id

-- Charlson 
LEFT JOIN physionet-data.mimiciv_derived.charlson
AS charlson
ON icu.hadm_id = charlson.hadm_id 

LEFT JOIN `physionet-data.mimiciv_derived.first_day_urine_output` AS fd_uo
ON icu.stay_id = fd_uo.stay_id 

-- Mechanical Ventilation
LEFT JOIN (
    SELECT stay_id
  , SUM(TIMESTAMP_DIFF(endtime,starttime,HOUR)) AS InvasiveVent_hr
  FROM `physionet-data.mimiciv_derived.ventilation`
  WHERE ventilation_status = "InvasiveVent"
  GROUP BY stay_id
)
AS InvasiveVent
ON InvasiveVent.stay_id = icu.stay_id

-- RRT
LEFT JOIN (
  SELECT DISTINCT stay_id, dialysis_present AS rrt 
  FROM physionet-data.mimiciv_derived.rrt
  WHERE dialysis_present = 1
)
AS rrt
ON icu.stay_id = rrt.stay_id 

-- Vasopressors
LEFT JOIN (
  SELECT DISTINCT stay_id
  FROM  physionet-data.mimiciv_derived.epinephrine
  UNION DISTINCT 

  SELECT DISTINCT stay_id
  FROM  physionet-data.mimiciv_derived.dobutamine
  UNION DISTINCT 

  SELECT DISTINCT stay_id
  FROM physionet-data.mimiciv_derived.dopamine
  UNION DISTINCT 

  SELECT DISTINCT stay_id
  FROM physionet-data.mimiciv_derived.norepinephrine
  UNION DISTINCT 

  SELECT DISTINCT stay_id
  FROM physionet-data.mimiciv_derived.phenylephrine
  UNION DISTINCT

  SELECT DISTINCT stay_id
  FROM physionet-data.mimiciv_derived.vasopressin
  )
AS pressor
ON icu.stay_id = pressor.stay_id 

-- Elective Admission
LEFT JOIN (
  SELECT
      hadm_id
    , admission_type as adm_type
    , CASE WHEN (
        admission_type LIKE "%ELECTIVE%" OR
      admission_type LIKE "%SURGICAL SAME DAY ADMISSION%"
    ) 
    THEN 1
    ELSE 0
    END AS adm_elective
  FROM `physionet-data.mimiciv_hosp.admissions`
)
AS adm
ON adm.hadm_id = icu.hadm_id

-- OASIS 
LEFT JOIN (
  SELECT 
    stay_id
  , oasis
  FROM `physionet-data.mimiciv_derived.oasis`
)
AS oa
ON oa.stay_id = icu.stay_id

-- Cancer
LEFT JOIN(
  SELECT
      hadm_id
    , STRING_AGG(icd_final) AS cancer_types
  FROM `protean-chassis-368116.icd_codes.diagnoses_icd10`
  WHERE icd_final LIKE "C%"
  GROUP BY hadm_id
)
AS cancer
ON cancer.hadm_id = icu.hadm_id

WHERE cancer.cancer_types IS NOT NULL
ORDER BY icu.subject_id