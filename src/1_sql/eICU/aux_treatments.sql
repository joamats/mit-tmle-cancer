DROP TABLE IF EXISTS `db_name.my_eICU.aux_treatments`;
CREATE TABLE `db_name.my_eICU.aux_treatments` AS

SELECT 
  icu.patientunitstayid
  , vent_1
  , vent_2
  , vent_3
  , vent_4
  , rrt_overall_yes
  , rrt_start_delta
  , pressor_1
  , pressor_2
  , pressor_3
  , pressor_4

FROM `db_name.eicu_crd_derived.icustay_detail` as icu


-- ventilation events
LEFT JOIN(
    SELECT 
        patientunitstayid
      , COUNT(event) as vent_1
    FROM `physionet-data.eicu_crd_derived.ventilation_events` 
    WHERE (event = "mechvent start" OR event = "mechvent end")
    GROUP BY patientunitstayid
)
AS v1
ON v1.patientunitstayid= icu.patientunitstayid

-- apache aps vars
LEFT JOIN(
    SELECT 
      patientunitstayid
      , COUNT(intubated) as vent_2
    FROM `physionet-data.eicu_crd.apacheapsvar`
    WHERE intubated = 1
    GROUP BY patientunitstayid
)
AS v2
ON v2.patientunitstayid= icu.patientunitstayid

-- apache pred vars
LEFT JOIN(
    SELECT 
      patientunitstayid
    , COUNT(oobintubday1) as vent_3
    FROM `physionet-data.eicu_crd.apachepredvar`
    WHERE oobintubday1 = 1
    GROUP BY patientunitstayid
)
AS v3
ON v3.patientunitstayid= icu.patientunitstayid

-- respiratory care table
LEFT JOIN(
    SELECT 
      patientunitstayid
    , CASE
        WHEN COUNT(airwaytype) >= 1 THEN 1
        WHEN COUNT(airwaysize) >= 1 THEN 1
        WHEN COUNT(airwayposition) >= 1 THEN 1
        WHEN COUNT(cuffpressure) >= 1 THEN 1
        WHEN COUNT(setapneatv) >= 1 THEN 1
        ELSE NULL
      END AS vent_4

  FROM `physionet-data.eicu_crd.respiratorycare`
  GROUP BY patientunitstayid
)
AS v4
ON v4.patientunitstayid= icu.patientunitstayid

-- treatment table to get RRT
LEFT JOIN (

WITH rrt_temp AS (

   SELECT DISTINCT 
      patientunitstayid
      , 1 AS rrt_yes
      , MIN(treatmentOffset) AS rrt_start_delta
   FROM `physionet-data.eicu_crd.treatment`

   WHERE treatmentstring LIKE "renal|dialysis|C%"
      OR treatmentstring LIKE "renal|dialysis|hemodialysis|emergent%"
      OR treatmentstring LIKE "renal|dialysis|hemodialysis|for acute renal failure"
      OR treatmentstring LIKE "renal|dialysis|hemodialysis"
   AND treatmentOffset > -1440

   GROUP BY patientunitstayid

   UNION DISTINCT

   SELECT DISTINCT 
      patientunitstayid
      , 1 AS rrt_yes
      , MIN(intakeOutputOffset) AS rrt_start_delta
   FROM `physionet-data.eicu_crd.intakeoutput`

   WHERE dialysistotal <> 0
   AND intakeOutputOffset > -1440

   GROUP BY patientunitstayid

   UNION DISTINCT

   SELECT 
      patientunitstayid
      , 1 AS rrt_yes
      , MIN(noteoffset) as rrt_start_delta
   FROM `physionet-data.eicu_crd.note` 

   WHERE noteoffset > -1440 
   AND (notetype ="Dialysis Catheter" OR  notetype ="Dialysis Catheter Change")

   GROUP BY patientunitstayid

  UNION DISTINCT

   SELECT 
      patientunitstayid
      , 1 AS rrt_yes
      , MIN(startoffset) as rrt_start_delta
   FROM `physionet-data.eicu_crd_derived.crrt_dataset` 
   
   WHERE startoffset > -1440 
 
   GROUP BY patientunitstayid
)

  SELECT 
      patientunitstayid
    , MAX(rrt_yes) AS rrt_overall_yes
    , MIN(rrt_start_delta) AS rrt_start_delta

  FROM rrt_temp
  GROUP BY patientunitstayid

)
AS rrt_overall
ON rrt_overall.patientunitstayid = icu.patientunitstayid


-- pivoted infusions table to get vasopressors
LEFT JOIN(
    SELECT 
      patientunitstayid
    , CASE
        WHEN COUNT(norepinephrine) >= 1 THEN 1
        WHEN COUNT(phenylephrine) >= 1 THEN 1
        WHEN COUNT(epinephrine) >= 1 THEN 1
        WHEN COUNT(vasopressin) >= 1 THEN 1
        ELSE NULL
      END AS pressor_1  

  FROM `physionet-data.eicu_crd_derived.pivoted_infusion`
  GROUP BY patientunitstayid
)
AS vp1
ON vp1.patientunitstayid= icu.patientunitstayid

-- infusions table to get vasopressors
LEFT JOIN(
    SELECT 
        patientunitstayid
      , COUNT(drugname) as pressor_2
    FROM `physionet-data.eicu_crd.infusiondrug`
    WHERE(
      OR LOWER(drugname) LIKE '%norepinephrine%'
      OR LOWER(drugname) LIKE '%phenylephrine%'
      OR LOWER(drugname) LIKE '%epinephrine%'
      OR LOWER(drugname) LIKE '%vasopressin%'
      OR LOWER(drugname) LIKE '%neo synephrine%'
      OR LOWER(drugname) LIKE '%neo-synephrine%'
      OR LOWER(drugname) LIKE '%neosynephrine%' 
      OR LOWER(drugname) LIKE '%neosynsprine%'
    )
    GROUP BY patientunitstayid
)
AS vp2
ON vp2.patientunitstayid= icu.patientunitstayid

-- medication
LEFT JOIN(
    SELECT  
        patientunitstayid
      , COUNT(drugname) as pressor_3
    FROM `physionet-data.eicu_crd.medication`
    WHERE(
      OR LOWER(drugname) LIKE '%norepinephrine%' 
      OR LOWER(drugname) LIKE '%phenylephrine%'
      OR LOWER(drugname) LIKE '%epinephrine%'
      OR LOWER(drugname) LIKE '%vasopressin%'
      OR LOWER(drugname) LIKE '%neo synephrine%' 
      OR LOWER(drugname) LIKE '%neo-synephrine%' 
      OR LOWER(drugname) LIKE '%neosynephrine%'
      OR LOWER(drugname) LIKE '%neosynsprine%'
    )
    GROUP BY patientunitstayid
)
AS vp3
ON vp3.patientunitstayid= icu.patientunitstayid


-- pivoted med
LEFT JOIN(
    SELECT  
        patientunitstayid
      , CASE
          WHEN SUM(norepinephrine) >= 1 THEN 1
          WHEN SUM(phenylephrine) >= 1 THEN 1
          WHEN SUM(epinephrine) >= 1 THEN 1
          WHEN SUM(vasopressin) >= 1 THEN 1
          ELSE NULL
       END AS pressor_4

    FROM `physionet-data.eicu_crd_derived.pivoted_med`
    GROUP BY patientunitstayid
)
AS vp4
ON vp4.patientunitstayid= icu.patientunitstayid

ORDER BY patientunitstayid