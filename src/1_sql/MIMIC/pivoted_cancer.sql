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
      OR icd_codes LIKE "%C96%" 
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
       icd_codes LIKE "%C0%"
    OR icd_codes LIKE "%C14%"
    OR icd_codes LIKE "%C15%"
    OR icd_codes LIKE "%C16%"
  ) THEN 1
    ELSE 0
  END AS loc_other_digestive

  , CASE WHEN (
       icd_codes LIKE "%C34%"
  ) THEN 1
    ELSE 0
  END AS loc_lung_bronchus

  , CASE WHEN (
       icd_codes LIKE "%C30%"
    OR icd_codes LIKE "%C31%"
    OR icd_codes LIKE "%C32%"
    OR icd_codes LIKE "%C33%"
    OR icd_codes LIKE "%C37%"
    OR icd_codes LIKE "%C38%"
    OR icd_codes LIKE "%C39%"
  ) THEN 1
    ELSE 0
  END AS loc_other_respiratory

  , CASE WHEN (
       icd_codes LIKE "%C40%"
    OR icd_codes LIKE "%C41%"
    OR icd_codes LIKE "%C45%"
    OR icd_codes LIKE "%C46%"
    OR icd_codes LIKE "%C47%"
    OR icd_codes LIKE "%C48%"
    OR icd_codes LIKE "%C49%"
  ) THEN 1
    ELSE 0
  END AS loc_other_mesothelial

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
    OR  icd_codes LIKE "%C56%"
    OR  icd_codes LIKE "%C57%"
    OR  icd_codes LIKE "%C58%"
  ) THEN 1
    ELSE 0
  END AS loc_female_genital

  , CASE WHEN (
       icd_codes LIKE "%C61%"
    OR icd_codes LIKE "%C62%"
    OR icd_codes LIKE "%C63%"
  ) THEN 1
    ELSE 0
  END AS loc_male_genital

  , CASE WHEN (
       icd_codes LIKE "%C64%"
    OR icd_codes LIKE "%C65%"
    OR icd_codes LIKE "%C66%"
    OR icd_codes LIKE "%C67%"
    OR icd_codes LIKE "%C68%"
  ) THEN 1
    ELSE 0
  END AS loc_renal_urinary

    , CASE WHEN (
       icd_codes LIKE "%C69%"
    OR icd_codes LIKE "%C70%"
    OR icd_codes LIKE "%C71%"
    OR icd_codes LIKE "%C72%"
  ) THEN 1
    ELSE 0
  END AS loc_cns

  , CASE WHEN (
       icd_codes LIKE "%C73%"
    OR icd_codes LIKE "%C74%"
    OR icd_codes LIKE "%C75%"
    OR icd_codes LIKE "%C7B%"
  ) THEN 1
    ELSE 0
  END AS loc_endocrine

  , CASE WHEN (
       icd_codes LIKE "%C81%"
    OR icd_codes LIKE "%C82%"
    OR icd_codes LIKE "%C83%"
    OR icd_codes LIKE "%C84%"
    OR icd_codes LIKE "%C85%"
    OR icd_codes LIKE "%C86%"
    OR icd_codes LIKE "%C88%"
  ) THEN 1
    ELSE 0
  END AS loc_lymphomas

  , CASE WHEN (
       icd_codes LIKE "%C90%"
    OR icd_codes LIKE "%C91%"
    OR icd_codes LIKE "%C92%"
    OR icd_codes LIKE "%C93%"
    OR icd_codes LIKE "%C94%"
    OR icd_codes LIKE "%C95%"
  ) THEN 1
    ELSE 0
  END AS loc_leukemia

  , CASE WHEN (
       icd_codes LIKE "%C76%"
    OR icd_codes LIKE "%C77%"
    OR icd_codes LIKE "%C78%"
    OR icd_codes LIKE "%C79%"
    OR icd_codes LIKE "%C80%"
  ) THEN 1
    ELSE 0
  END AS loc_others

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
  , loc_other_digestive
  , loc_lung_bronchus
  , loc_other_respiratory
  , loc_other_mesothelial
  , loc_melanoma
  , loc_breast
  , loc_female_genital
  , loc_male_genital
  , loc_renal_urinary
  , loc_endocrine
  , loc_cns
  , loc_lymphomas
  , loc_leukemia
  , loc_other_hematological
  , loc_others

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
