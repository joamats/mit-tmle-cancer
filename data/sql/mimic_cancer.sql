SELECT DISTINCT
    icu.subject_id
  , icu.hadm_id
  , icu.stay_id
  , icu.gender
  , pat.anchor_age
  , icu.race
  , CASE 
      WHEN (
         LOWER(icu.race) LIKE "%white%"
      OR LOWER(icu.race) LIKE "%portuguese%" 
      OR LOWER(icu.race) LIKE "%caucasian%" 
      ) THEN "White"
      WHEN (
         LOWER(icu.race) LIKE "%black%"
      OR LOWER(icu.race) LIKE "%african american%"
      ) THEN "Black"
      WHEN (
         LOWER(icu.race) LIKE "%hispanic%"
      OR LOWER(icu.race) LIKE "%south american%" 
      ) THEN "Hispanic"
      WHEN (
         LOWER(icu.race) LIKE "%asian%"
      ) THEN "Asian"
      ELSE "Other"
    END AS race_group
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
  , CASE WHEN s3.sepsis3 IS TRUE THEN 1 ELSE 0 END AS sepsis3
  , charlson.charlson_comorbidity_index
  , sf.SOFA
  , oa.oasis AS OASIS
  , CASE
      WHEN InvasiveVent.InvasiveVent_hr IS NOT NULL
      THEN 1
      ELSE 0
    END AS mech_vent

  , CASE
      WHEN rrt.rrt IS NOT NULL
      THEN 1
      ELSE 0
    END AS rrt

  , CASE 
      WHEN (pressor.stay_id = icu.stay_id) IS NOT NULL
      THEN 1
      ELSE 0
    END AS vasopressor

  , CASE WHEN 
      icd_codes LIKE "%C__%"
      THEN 1
      ELSE 0
    END AS has_cancer

  , CASE WHEN (
         icd_codes LIKE "%C0%" 
      OR icd_codes LIKE "%C1%"
      OR icd_codes LIKE "%C2%"
      OR icd_codes LIKE "%C3%" 
      OR icd_codes LIKE "%C4%"
      OR icd_codes LIKE "%C5%"
      OR icd_codes LIKE "%C6%"
      OR icd_codes LIKE "%C70%"
      OR icd_codes LIKE "%C71%"
      OR icd_codes LIKE "%C72%"
      OR icd_codes LIKE "%C73%"
      OR icd_codes LIKE "%C74%"
      OR icd_codes LIKE "%C75%"
      OR icd_codes LIKE "%C76%"
  ) THEN 1
    ELSE 0
  END AS cat_solid

  , CASE WHEN (
         icd_codes LIKE "%C77%" 
      OR icd_codes LIKE "%C7B%"
      OR icd_codes LIKE "%C78%"
      OR icd_codes LIKE "%C79%" 
      OR icd_codes LIKE "%C79%"
  ) THEN 1
    ELSE 0
  END AS cat_metastasized

  , CASE WHEN (
         icd_codes LIKE "%C8"  
      OR icd_codes LIKE "%C90" 
      OR icd_codes LIKE "%C91" 
      OR icd_codes LIKE "%C92" 
      OR icd_codes LIKE "%C93" 
      OR icd_codes LIKE "%C94" 
      OR icd_codes LIKE "%C95" 
  ) THEN 1
    ELSE 0
  END AS cat_hematological

  , CASE WHEN (
       icd_codes LIKE "%C17%"
    OR icd_codes LIKE "%C18%"
    OR icd_codes LIKE "%C19%"
    OR icd_codes LIKE "%C20%"
    OR icd_codes LIKE "%C21%"
  ) THEN 1
    ELSE 0
  END AS loc_colon_rectal

  , CASE WHEN (
       icd_codes LIKE "%C22%"
  ) THEN 1
    ELSE 0
  END AS loc_liver_bd

  , CASE WHEN (
       icd_codes LIKE "%C25%"
  ) THEN 1
    ELSE 0
  END AS loc_pancreatic

  , CASE WHEN (
       icd_codes LIKE "%C34%"
  ) THEN 1
    ELSE 0
  END AS loc_lung_bronchus

  , CASE WHEN (
       icd_codes LIKE "%C43%"
  ) THEN 1
    ELSE 0
  END AS loc_melanoma

  , CASE WHEN (
       icd_codes LIKE "%C50%"
  ) THEN 1
    ELSE 0
  END AS loc_breast

  , CASE WHEN (
        icd_codes LIKE "%C53%"
    OR  icd_codes LIKE "%C54%"
    OR  icd_codes LIKE "%C55%"
  ) THEN 1
    ELSE 0
  END AS loc_endometrial

  , CASE WHEN (
       icd_codes LIKE "%C61%"
  ) THEN 1
    ELSE 0
  END AS loc_prostate

  , CASE WHEN (
       icd_codes LIKE "%C64%"
    OR icd_codes LIKE "%C65%"
  ) THEN 1
    ELSE 0
  END AS loc_kidney

  , CASE WHEN (
       icd_codes LIKE "%C67%"
  ) THEN 1
    ELSE 0
  END AS loc_bladder

  , CASE WHEN (
       icd_codes LIKE "%C73%"
  ) THEN 1
    ELSE 0
  END AS loc_thyroid

  , CASE WHEN (
       icd_codes LIKE "%C82%"
    OR icd_codes LIKE "%C83%"
    OR icd_codes LIKE "%C84%"
    OR icd_codes LIKE "%C85%"
    OR icd_codes LIKE "%C86%"
  ) THEN 1
    ELSE 0
  END AS loc_nhl

  , CASE WHEN (
       icd_codes LIKE "%C91%"
    OR icd_codes LIKE "%C92%"
    OR icd_codes LIKE "%C93%"
    OR icd_codes LIKE "%C94%"
    OR icd_codes LIKE "%C95%"
  ) THEN 1
    ELSE 0
  END AS loc_leukemia

  , CASE WHEN (
       icd_codes LIKE "%I10%"
    OR icd_codes LIKE "%I11%"
    OR icd_codes LIKE "%I12%"
    OR icd_codes LIKE "%I13%"
    OR icd_codes LIKE "%I14%"
    OR icd_codes LIKE "%I15%"
    OR icd_codes LIKE "%I16%"
    OR icd_codes LIKE "%I70%"
  ) THEN 1
    ELSE 0
  END AS comm_hypertension

  , CASE WHEN (
       icd_codes LIKE "%I50%"
    OR icd_codes LIKE "%I110%"
    OR icd_codes LIKE "%I27%"
    OR icd_codes LIKE "%I42%"
    OR icd_codes LIKE "%I43%"
    OR icd_codes LIKE "%I517%"
  ) THEN 1
    ELSE 0
  END AS comm_heart_failure

  , CASE 
      WHEN icd_codes LIKE "%N181%" THEN 1
      WHEN icd_codes LIKE "%N182%" THEN 2
      WHEN icd_codes LIKE "%N183%" THEN 3
      WHEN icd_codes LIKE "%N184%" THEN 4
      WHEN (
           icd_codes LIKE "%N185%" 
        OR icd_codes LIKE "%N186%"
      )
      THEN 5
    ELSE 0
  
  END AS comm_ckd

  , CASE WHEN (
       icd_codes LIKE "%J41%"
    OR icd_codes LIKE "%J42%"
    OR icd_codes LIKE "%J43%"
    OR icd_codes LIKE "%J44%"
    OR icd_codes LIKE "%J45%"
    OR icd_codes LIKE "%J46%"
    OR icd_codes LIKE "%J47%"
  ) THEN 1
    ELSE 0
  END AS comm_copd

  , CASE WHEN 
      icd_codes LIKE "%J841%"
      THEN 1
      ELSE 0
  END AS comm_asthma

  , CASE WHEN (
         discharge_location = "DIED"
      OR discharge_location = "HOSPICE"
  ) THEN 1
    ELSE 0
  END AS mortality_in

  , CASE WHEN (
         discharge_location = "DIED"
      OR discharge_location = "HOSPICE"
      OR ABS(TIMESTAMP_DIFF(pat.dod,icu.icu_outtime,DAY)) <= 90
  ) THEN 1
    ELSE 0
  END AS mortality_90
  

-- ICU stays
FROM physionet-data.mimiciv_derived.icustay_detail
AS icu 

-- Sepsis Patients
LEFT JOIN physionet-data.mimiciv_derived.sepsis3
AS s3
ON s3.stay_id = icu.stay_id

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

-- ICD codes
LEFT JOIN(
  SELECT
      hadm_id
    , STRING_AGG(icd_final) AS icd_codes
  FROM `protean-chassis-368116.icd_codes.diagnoses_icd10`
  GROUP BY hadm_id
)
AS icd
ON icd.hadm_id = icu.hadm_id

--WHERE has_cancer = TRUE

ORDER BY icu.subject_id