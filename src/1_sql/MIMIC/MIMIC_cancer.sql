SELECT DISTINCT
    icu.subject_id
  , icu.hadm_id
  , icu.stay_id
  , icu.gender
  , CASE WHEN icu.gender = "F" THEN 1 ELSE 0 END AS sex_female
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
  , ad.language
  , ad.discharge_location AS discharge_location
  , icu.dod
  , ABS(TIMESTAMP_DIFF(pat.dod,icu.icu_outtime,DAY)) AS dod_icuout_offset_days
  , pat.anchor_year_group
  , icu.los_hospital
  , icu.los_icu
  , icu.hospstay_seq
  , icu.first_hosp_stay
  , icu.icustay_seq
  , icu.first_icu_stay
  , CASE WHEN s3.sepsis3 IS TRUE THEN 1 ELSE 0 END AS sepsis3
  , charlson.charlson_comorbidity_index AS CCI
  , CASE 
      WHEN ( charlson.charlson_comorbidity_index >= 0 AND charlson.charlson_comorbidity_index <= 3) THEN "0-3"
      WHEN ( charlson.charlson_comorbidity_index >= 4 AND charlson.charlson_comorbidity_index <= 6) THEN "4-6" 
      WHEN ( charlson.charlson_comorbidity_index >= 7 AND charlson.charlson_comorbidity_index <= 10) THEN "7-10" 
      WHEN ( charlson.charlson_comorbidity_index > 10) THEN ">10" 
    END AS CCI_ranges
    
  , sf.SOFA
  , CASE 
      WHEN ( SOFA >= 0 AND SOFA <= 3) THEN "0-3"
      WHEN ( SOFA >= 4 AND SOFA <= 6) THEN "4-6" 
      WHEN ( SOFA >= 7 AND SOFA <= 10) THEN "7-10" 
      WHEN ( SOFA > 10) THEN ">10" 
    END AS SOFA_ranges

  , oa.oasis AS OASIS
  , CASE 
      WHEN ( OASIS >= 0 AND OASIS <= 37) THEN "0-37"
      WHEN ( OASIS >= 38 AND OASIS <= 45) THEN "38-45" 
      WHEN ( OASIS >= 46 AND OASIS <= 51) THEN "46-51" 
      WHEN ( OASIS > 51) THEN ">51" 
    END AS OASIS_ranges

-- Treatments and their durations
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

, SAFE_DIVIDE(MV_time_hr,24) AS mv_time_d
, SAFE_DIVIDE(vp_time_hr,24) AS vp_time_d
, SAFE_DIVIDE(rrt_time_hr,24) AS rrt_time_d
, SAFE_DIVIDE(SAFE_DIVIDE(MV_time_hr,24),icu.los_icu) AS MV_time_perc_of_stay
, SAFE_DIVIDE(SAFE_DIVIDE(vp_time_hr,24),icu.los_icu) AS VP_time_perc_of_stay,

-- MV as offset as fraction of LOS
CASE
  WHEN TIMESTAMP_DIFF(mv_mtime.starttime, icu.icu_intime, HOUR) >= 0.01
  THEN TIMESTAMP_DIFF(mv_mtime.starttime, icu.icu_intime, HOUR)/24/icu.los_icu
  WHEN TIMESTAMP_DIFF(mv_mtime.starttime, icu.icu_intime, HOUR) <= 0
  THEN 0
  ELSE NULL
END AS MV_init_offset_perc,

-- MV as offset absolut in days
CASE
  WHEN TIMESTAMP_DIFF(mv_mtime.starttime, icu.icu_intime, HOUR) >= 0.01
  THEN TIMESTAMP_DIFF(mv_mtime.starttime, icu.icu_intime, HOUR)/24
  WHEN TIMESTAMP_DIFF(mv_mtime.starttime, icu.icu_intime, HOUR) <= 0
  THEN 0
  ELSE NULL
END AS MV_init_offset_d_abs,

-- RRT as offset as fraction of LOS
CASE
  WHEN TIMESTAMP_DIFF(rrt_time.charttime, icu.icu_intime, HOUR) >= 0.01
  THEN TIMESTAMP_DIFF(rrt_time.charttime, icu.icu_intime, HOUR)/24/icu.los_icu
  WHEN TIMESTAMP_DIFF(rrt_time.charttime, icu.icu_intime, HOUR) <= 0
  THEN 0
  ELSE NULL
END AS RRT_init_offset_perc,

-- RRT as offset absolut in days
CASE
  WHEN TIMESTAMP_DIFF(rrt_time.charttime, icu.icu_intime, HOUR) >= 0.01
  THEN TIMESTAMP_DIFF(rrt_time.charttime, icu.icu_intime, HOUR)/24
  WHEN TIMESTAMP_DIFF(rrt_time.charttime, icu.icu_intime, HOUR) <= 0
  THEN 0
  ELSE NULL
END AS RRT_init_offset_d_abs,

-- VP as offset as fraction of LOS
CASE
  WHEN TIMESTAMP_DIFF(vp_mtime.starttime, icu.icu_intime, HOUR) >= 0.01
  THEN TIMESTAMP_DIFF(vp_mtime.starttime, icu.icu_intime, HOUR)/24/icu.los_icu
  WHEN TIMESTAMP_DIFF(vp_mtime.starttime, icu.icu_intime, HOUR) <= 0
  THEN 0
  ELSE NULL
END AS VP_init_offset_perc,

-- VP as offset absolut in days
CASE
  WHEN TIMESTAMP_DIFF(vp_mtime.starttime, icu.icu_intime, HOUR) >= 0.01
  THEN TIMESTAMP_DIFF(vp_mtime.starttime, icu.icu_intime, HOUR)/24
  WHEN TIMESTAMP_DIFF(vp_mtime.starttime, icu.icu_intime, HOUR) <= 0
  THEN 0
  ELSE NULL
END AS VP_init_offset_d_abs,

-- Dummy variables to match for eICU
001 AS hospitalid, -- dummy variable for hospitalid in eICU
">= 500" AS numbedscategory, -- dummy variable for numbedscategory in eICU
"true" AS teachingstatus, -- is boolean in eICU
"Northeast" AS region -- dummy variable for US census region in eICU

  , cancer.has_cancer
  , cancer.group_solid
  , cancer.group_metastasized
  , cancer.group_hematological
  , cancer.loc_colon_rectal
  , cancer.loc_liver_bd
  , cancer.loc_pancreatic
  , cancer.loc_lung_bronchus
  , cancer.loc_melanoma
  , cancer.loc_breast
  , cancer.loc_endometrial
  , cancer.loc_prostate
  , cancer.loc_kidney
  , cancer.loc_bladder
  , cancer.loc_thyroid
  , cancer.loc_nhl
  , cancer.loc_leukemia
  , coms.hypertension_present AS com_hypertension_present
  , coms.heart_failure_present AS com_heart_failure_present
  , coms.copd_present AS com_copd_present
  , coms.asthma_present AS com_asthma_present
  , coms.ckd_stages AS com_ckd_stages

  , CASE
      WHEN codes.first_code IS NULL
        OR codes.first_code = "Full code" 
      THEN 1
      ELSE 0
    END AS is_full_code_admission
  
  , CASE
      WHEN codes.last_code IS NULL
        OR codes.last_code = "Full code" 
      THEN 1
      ELSE 0
    END AS is_full_code_discharge


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

-- for MV perc of stay
left join (
  SELECT vent.stay_id,
  SUM(TIMESTAMP_DIFF(endtime,starttime,HOUR)) as MV_time_hr
  FROM `physionet-data.mimiciv_derived.ventilation` vent
  LEFT JOIN `physionet-data.mimiciv_derived.icustay_detail` icu
  ON icu.stay_id = vent.stay_id
  AND TIMESTAMP_DIFF(icu.icu_outtime, endtime, HOUR) > 0
  AND TIMESTAMP_DIFF(starttime, icu.icu_intime, HOUR) > 0
  WHERE (ventilation_status = "Trach" OR ventilation_status = "InvasiveVent")
  GROUP BY stay_id
) AS mv_time
ON mv_time.stay_id = icu.stay_id

-- for MV initation offset 
LEFT JOIN (
  SELECT vent.stay_id, MIN(starttime) as starttime
  FROM `physionet-data.mimiciv_derived.ventilation` vent
  LEFT JOIN `physionet-data.mimiciv_derived.icustay_detail` icu
  ON icu.stay_id = vent.stay_id
  AND TIMESTAMP_DIFF(icu.icu_outtime, endtime, HOUR) > 0
  AND TIMESTAMP_DIFF(starttime, icu.icu_intime, HOUR) > 0
  WHERE (ventilation_status = "Trach" OR ventilation_status = "InvasiveVent")
  GROUP BY stay_id
)
AS mv_mtime
ON mv_mtime.stay_id = icu.stay_id

-- RRT
LEFT JOIN (
  SELECT DISTINCT stay_id, dialysis_present AS rrt 
  FROM physionet-data.mimiciv_derived.rrt
  WHERE dialysis_present = 1
)
AS rrt
ON icu.stay_id = rrt.stay_id 

-- RRT initiation offset
LEFT JOIN (
  SELECT dia.stay_id,
  MAX(dialysis_present) AS rrt,
  MIN(charttime) AS charttime,
  TIMESTAMP_DIFF(MAX(charttime), MIN(charttime), HOUR) AS rrt_time_hr
  FROM `physionet-data.mimiciv_derived.rrt` dia

  LEFT JOIN `physionet-data.mimiciv_derived.icustay_detail` icu
  ON icu.stay_id = dia.stay_id
  AND TIMESTAMP_DIFF(icu.icu_outtime, charttime, HOUR) > 0 -- to make sure it's within the ICU stay
  AND TIMESTAMP_DIFF(charttime, icu.icu_intime, HOUR) > 0
  WHERE dialysis_type like "C%" OR dialysis_type like "IHD" -- only consider hemodialyisis
  GROUP BY stay_id
) AS rrt_time
ON icu.stay_id = rrt_time.stay_id 


-- Vasopressors
LEFT JOIN (
  SELECT DISTINCT stay_id
  FROM  `physionet-data.mimiciv_derived.epinephrine`
  UNION DISTINCT 

  SELECT DISTINCT stay_id
  FROM `physionet-data.mimiciv_derived.norepinephrine`
  UNION DISTINCT 

  SELECT DISTINCT stay_id
  FROM `physionet-data.mimiciv_derived.phenylephrine`
  UNION DISTINCT

  SELECT DISTINCT stay_id
  FROM `physionet-data.mimiciv_derived.vasopressin`
  )
AS pressor
ON icu.stay_id = pressor.stay_id 

-- for VP percentage of stay
LEFT JOIN(
  SELECT
    nor.stay_id
    , SUM(TIMESTAMP_DIFF(endtime, starttime, HOUR)) AS vp_time_hr
  FROM `physionet-data.mimiciv_derived.norepinephrine_equivalent_dose` nor
  LEFT JOIN `physionet-data.mimiciv_derived.icustay_detail` icu
  ON icu.stay_id = nor.stay_id
  AND TIMESTAMP_DIFF(icu.icu_outtime, endtime, HOUR) > 0
  AND TIMESTAMP_DIFF(starttime, icu.icu_intime, HOUR) > 0
  GROUP BY stay_id
) AS vp_time
ON vp_time.stay_id = icu.stay_id

-- VPs offset initiation
LEFT JOIN(
  SELECT
    nor.stay_id
    , MIN(starttime) AS starttime
  FROM `physionet-data.mimiciv_derived.norepinephrine_equivalent_dose` nor
  LEFT JOIN `physionet-data.mimiciv_derived.icustay_detail` icu
  ON icu.stay_id = nor.stay_id
  AND TIMESTAMP_DIFF(icu.icu_outtime, endtime, HOUR) > 0
  AND TIMESTAMP_DIFF(starttime, icu.icu_intime, HOUR) > 0
  GROUP BY stay_id
) AS vp_mtime
ON vp_mtime.stay_id = icu.stay_id


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

-- Active Cancer in the ICU
LEFT JOIN(
  SELECT *
  FROM `db_name.my_MIMIC.pivoted_cancer`
)
AS cancer
ON cancer.hadm_id = icu.hadm_id

-- Key Comorbidities
LEFT JOIN(
  SELECT *
  FROM `db_name.my_MIMIC.pivoted_comorbidities`
)
AS coms
ON coms.hadm_id = icu.hadm_id

-- Full code vs. DNI/NDR
LEFT JOIN(
  SELECT *
  FROM `db_name.my_MIMIC.pivoted_codes`
)
AS codes
ON codes.stay_id = icu.stay_id

ORDER BY icu.subject_id, icu.hadm_id, icu.stay_id