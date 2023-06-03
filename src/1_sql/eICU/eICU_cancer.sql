SELECT DISTINCT
    yug.patienthealthsystemstayid 
  , yug.patientunitstayid
  , yug.gender
  , CASE WHEN yug.gender = 'Female' THEN 1 ELSE 0 END AS sex_female
  , yug.age as anchor_age
  , yug.ethnicity as race
  , CASE 
      WHEN (
        LOWER(yug.ethnicity) LIKE "%caucasian%" 
      ) THEN "White"
      WHEN (
        LOWER(yug.ethnicity) LIKE "%african american%"
      ) THEN "Black"
      WHEN (
         LOWER(yug.ethnicity) LIKE "%hispanic%"
      ) THEN "Hispanic"
      WHEN (
         LOWER(yug.ethnicity) LIKE "%asian%"
      ) THEN "Asian"
      ELSE "Other"
    END AS race_group
  , yug.admissionweight AS weight_admit
  , yug.hospitaladmitsource AS adm_type
  , yug.hospitaldischargeyear AS anchor_year_group
  , yug.hospitaldischargetime24 AS dischtime
  , yug.los_icu
  , icustay_detail.unitvisitnumber

  , yug.Charlson as charlson_cont
  , CASE 
      WHEN (yug.Charlson >= 0 AND yug.Charlson <= 3) THEN "0-3"
      WHEN (yug.Charlson >= 4 AND yug.Charlson <= 6) THEN "4-6" 
      WHEN (yug.Charlson >= 7 AND yug.Charlson <= 10) THEN "7-10" 
      WHEN (yug.Charlson > 10) THEN ">10" 
    END AS CCI_ranges

  , yug.sofa_admit as SOFA 
  , yug.respiration
  , yug.coagulation
  , yug.liver
  , yug.cardiovascular
  , yug.cns
  , yug.renal

-- Treatments and their offsets
  , CASE 
      WHEN 
           yug.vent IS TRUE
        OR vent_yes > 0
      THEN 1
      ELSE 0
    END AS mech_vent

  , CASE 
      WHEN 
           yug.rrt IS TRUE
        OR rrt_yes > 0
      THEN 1
      ELSE 0
    END AS rrt

  , CASE 
      WHEN 
           yug.vasopressor IS TRUE
        OR vp_yes > 0
      THEN 1
      ELSE 0
    END AS vasopressor
  
  -- , vent_start_offset
  -- , rrt_start_offset
  -- , vp_start_offset

-- Convert offset from minutes to fraction of day
  , SAFE_DIVIDE(vent_start_offset,(24*60)) AS MV_init_offset_d_abs -- convert from minutes to days, in MIMIC it's from hours to days
  , SAFE_DIVIDE(rrt_start_offset,(24*60)) AS RRT_init_offset_d_abs
  , SAFE_DIVIDE(vp_start_offset,(24*60)) AS VP_init_offset_d_abs
 -- , SAFE_DIVIDE(SAFE_DIVIDE(vent_duration,(24*60)),yug.los_icu) AS MV_time_perc_of_stay
 -- , SAFE_DIVIDE(SAFE_DIVIDE(vp_time_d,(24*60)),yug.los_icu) AS VP_time_perc_of_stay -- omitted as not easily feasible in eICU

-- comorbidities
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
  , coms.hypertension_present
  , coms.heart_failure_present
  , coms.copd_present
  , coms.asthma_present
  , coms.ckd_stages
  , coms.cad_present
  , coms.diabetes_types
  , coms.connective_disease
  , coms.pneumonia
  , coms.uti
  , coms.biliary
  , coms.skin
  , coms.clabsi
  , coms.cauti
  , coms.ssi
  , coms.vap

  , CASE
      WHEN codes.first_code IS NULL
        OR codes.first_code = "No blood draws" 
        OR codes.first_code = "No blood products"
        OR codes.first_code = "Full therapy"
      THEN 1
      ELSE 0
    END AS is_full_code_admission
  
  , CASE
      WHEN codes.last_code IS NULL
        OR codes.last_code = "No blood draws" 
        OR codes.last_code = "No blood products"
        OR codes.last_code = "Full therapy"
      THEN 1
      ELSE 0
    END AS is_full_code_discharge

  , CASE 
      WHEN yug.unitdischargelocation = "Death"
        OR yug.unitdischargestatus = "Expired"
        OR yug.hospitaldischargestatus = "Expired"
      THEN 1
      ELSE 0
    END AS mortality_in 

-- hospital characteristics
  , hospital.hospitalid AS hospitalid
  , hospital.numbedscategory AS numbedscategory
  , hospital.teachingstatus AS teachingstatus
  , hospital.region AS region

  , pe.adm_elective
  , pe.major_surgery
  , apache.apache_prob
  , apache.apachescore
  
-- vital signs
 , vitals.heart_rate_mean
 , vitals.resp_rate_mean
 , vitals.spo2_mean
 , vitals.temperature_mean
 , vitals.mbp_mean

-- lab values
  , lab.glucose_max
  , lab.ph_min
  , lab.lactate_max
  , lab.sodium_min
  , lab.potassium_max
  , lab.cortisol_min
  , lab.hemoglobin_min
  , lab.fibrinogen_min  
  , lab.inr_max
  , lab.po2_min
  , lab.pco2_max
  , lab.fio2_avg


FROM `db_name.my_eICU.yugang` AS yug


LEFT JOIN(
  SELECT patientunitstayid, unitvisitnumber
  FROM `physionet-data.eicu_crd_derived.icustay_detail`
) 
AS icustay_detail
ON icustay_detail.patientunitstayid = yug.patientunitstayid

LEFT JOIN(
  SELECT *
  FROM `db_name.my_eICU.aux_treatments`
)
AS treatments
ON treatments.patientunitstayid = yug.patientunitstayid


LEFT JOIN(
  SELECT *
  FROM `db_name.my_eICU.pivoted_cancer`
)
AS cancer
ON cancer.patientunitstayid = yug.patientunitstayid

LEFT JOIN(
  SELECT *
  FROM `db_name.my_eICU.pivoted_comorbidities`
)
AS coms
ON coms.patientunitstayid = yug.patientunitstayid

LEFT JOIN(
  SELECT *
  FROM `db_name.my_eICU.pivoted_codes`
)
AS codes
ON codes.patientunitstayid = yug.patientunitstayid 

-- Left join hospitalid in yugang table with hospitalid in hospital table
LEFT JOIN(
  SELECT *
  FROM `physionet-data.eicu_crd.hospital`
)
AS hospital
ON hospital.hospitalid = yug.hospitalid

-- Elective surgery and admissions -> Mapping according to OASIS
LEFT JOIN(
  SELECT patientunitstayid, adm_elective
  , CASE
    WHEN new_elective_surgery = 1 THEN 0
    WHEN new_elective_surgery = 0 THEN 6
    ELSE 0
    -- Analysed admission table -> In most cases -> if elective surgery is NULL -> there was no surgery or emergency surgery
    END AS electivesurgery_OASIS
  
  , CASE
    WHEN new_elective_surgery = 1 THEN 1
    WHEN new_elective_surgery = 0 THEN 0
    WHEN adm_elective = 1 THEN 1
    ELSE 0
    END AS major_surgery

  FROM `db_name.my_eICU.pivoted_elective` as pe
)
AS pe
ON pe.patientunitstayid = yug.patientunitstayid

-- APACHE IV
LEFT JOIN(
  SELECT patientunitstayid, 
  apachescore,
  predictedhospitalmortality as apache_prob
  FROM `physionet-data.eicu_crd.apachepatientresult`
  WHERE apacheversion = "IVa"
)
AS apache
ON apache.patientunitstayid = yug.patientunitstayid

-- vital signs
LEFT JOIN (
SELECT patientunitstayid,

AVG(heartrate) AS heart_rate_mean,
AVG(respiratoryrate) AS resp_rate_mean,
AVG(spo2) AS spo2_mean,
AVG(temperature) AS temperature_mean,

CASE WHEN MIN(ibp_mean) IS NOT NULL THEN AVG(ibp_mean)
WHEN MIN(ibp_mean) IS NULL THEN AVG(nibp_mean) 
END AS mbp_mean

FROM `physionet-data.eicu_crd_derived.pivoted_vital` 

WHERE chartoffset < 1440
AND heartrate IS NOT NULL
OR respiratoryrate IS NOT NULL
OR spo2 IS NOT NULL
OR temperature IS NOT NULL

GROUP BY patientunitstayid
)
AS vitals
ON vitals.patientunitstayid = yug.patientunitstayid

-- pivoted lab for usual blood tests
LEFT JOIN(
  SELECT patientunitstayid,
  
  MAX(CASE WHEN 
  chartoffset < 1440 THEN glucose
  END) AS glucose_max,

  MAX(CASE WHEN 
  chartoffset < 1440 THEN INR
  END) AS inr_max,

  MAX(CASE WHEN 
  chartoffset < 1440 THEN lactate
  END) AS lactate_max,

  MAX(CASE WHEN 
  chartoffset < 1440 THEN potassium
  END) AS potassium_max,

  CASE WHEN 
  MAX(chartoffset < 1440) THEN MIN(sodium)
  END AS sodium_min,

  CASE WHEN 
  MAX(chartoffset) < 1440 THEN MIN(fibrinogen)
  END AS fibrinogen_min,

  CASE WHEN 
  MAX(chartoffset) < 1440 THEN AVG(fio2)
  END AS fio2_avg,

  CASE WHEN 
  MAX(chartoffset) < 1440 THEN MAX(pco2)
  END AS pco2_max,

  CASE WHEN 
  MAX(chartoffset) < 1440 THEN MIN(pao2)
  END AS po2_min,

  CASE WHEN 
  MAX(chartoffset) < 1440 THEN MIN(pH)
  END AS ph_min,

  MIN(hemoglobin) AS hemoglobin_min,
  MIN(cortisol) AS cortisol_min,

  FROM `db_name.my_eICU.pivoted_lab`

  GROUP BY patientunitstayid
  ORDER BY patientunitstayid
)
AS lab
ON lab.patientunitstayid = yug.patientunitstayid


ORDER BY yug.patienthealthsystemstayid, yug.patientunitstayid
;