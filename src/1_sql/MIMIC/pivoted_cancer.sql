DROP TABLE IF EXISTS `db_name.my_MIMIC.pivoted_cancer`;
CREATE TABLE `db_name.my_MIMIC.pivoted_cancer` AS

WITH cnc AS (

  SELECT 

  icu.hadm_id

  , CASE WHEN (
         icd_codes LIKE "%C0%" 
      OR icd_codes LIKE "%C1%"
      OR icd_codes LIKE "%C2%"
      OR icd_codes LIKE "%C3%" 
      OR icd_codes LIKE "%C40%"
      OR icd_codes LIKE "%C41%"
      OR icd_codes LIKE "%C43%" -- C42 does not exist, C44 excluded as never fatal (squamous cell carcinomas)
      OR icd_codes LIKE "%C45%"
      OR icd_codes LIKE "%C46%"
      OR icd_codes LIKE "%C47%"
      OR icd_codes LIKE "%C48%"
      OR icd_codes LIKE "%C49%"
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
         icd_codes LIKE "%C8%"  
      OR icd_codes LIKE "%C90%" 
      OR icd_codes LIKE "%C91%" 
      OR icd_codes LIKE "%C92%" 
      OR icd_codes LIKE "%C93%" 
      OR icd_codes LIKE "%C94%" 
      OR icd_codes LIKE "%C95%" 
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


FROM `physionet-data.mimiciv_derived.icustay_detail` AS icu

LEFT JOIN(
  SELECT hadm_id, STRING_AGG(icd_codes) AS icd_codes
  FROM `db_name.my_MIMIC.aux_icd10codes`
  GROUP BY hadm_id
)
AS diagnoses_icd10 
ON diagnoses_icd10.hadm_id = icu.hadm_id
)

SELECT 

    hadm_id
  , loc_colon_rectal
  , loc_liver_bd
  , loc_pancreatic
  , loc_lung_bronchus
  , loc_melanoma
  , loc_breast
  , loc_endometrial
  , loc_prostate
  , loc_kidney
  , loc_bladder
  , loc_thyroid
  , loc_nhl
  , loc_leukemia

  , CASE
      WHEN (cat_solid = 1 AND cat_hematological != 1 AND cat_metastasized != 1)
      THEN 1
      ELSE 0
    END AS group_solid

  , CASE
      WHEN (cat_hematological = 1 AND cat_metastasized != 1)
      THEN 1
      ELSE 0
    END AS group_hematological

  , CASE
      WHEN (cat_metastasized = 1)
      THEN 1
      ELSE 0
    END AS group_metastasized

  , CASE
      WHEN (cat_solid = 1 OR cat_metastasized = 1 OR cat_hematological = 1)
      THEN 1
      ELSE 0
    END AS has_cancer

FROM cnc
