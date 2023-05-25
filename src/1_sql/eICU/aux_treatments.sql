DROP TABLE IF EXISTS `db_name.my_eICU.aux_treatments`;
CREATE TABLE `db_name.my_eICU.aux_treatments` AS

SELECT 
  icu.patientunitstayid
  , vent_yes
  , vent_start_delta AS vent_start_offset
  , vent_duration
  , rrt_yes
  , rrt_start_delta AS rrt_start_offset
  , vp_yes
  , vp_start_offset

FROM `db_name.eicu_crd_derived.icustay_detail` as icu


-- ventilation events

-- Data from nursecare and respiratorycharting have no clear stop offset, but clear identifier for start of vent
-- used last occurrence of vent identifier as proxy for stop
-- careplangeneral has not clear identifier for stop offset -> all rows in vent_stop_delta set to NULL

-- Tables accessed
-- derived -> ventilation_events
-- original --> respiratorycharting, nursecare, note, respiratorycare, careplangeneral 

LEFT JOIN(

WITH resp_chart AS (

  SELECT 
  patientunitstayid, 
  1 AS vent_yes,
  MIN(respchartvaluelabel) AS event,
  
  MIN(CASE 
  WHEN LOWER(respchartvaluelabel) LIKE "%endotracheal%"
  OR LOWER(respchartvaluelabel) LIKE "%ett%"
  OR LOWER(respchartvaluelabel) LIKE "%ET Tube%"
  THEN respchartoffset
 ELSE 0
  END) AS vent_start_delta,

  MAX(CASE 
  WHEN LOWER(respchartvaluelabel) LIKE "%endotracheal%" 
  OR LOWER(respchartvaluelabel) LIKE "%ett%" 
  OR LOWER(respchartvaluelabel) LIKE "%ET Tube%"
  THEN respchartoffset
 ELSE 0
  END) AS vent_stop_delta,

  MAX(offset_discharge) AS offset_discharge

  FROM `physionet-data.eicu_crd.respiratorycharting` AS rc

  LEFT JOIN(
  SELECT patientunitstayid AS pat_pid, unitdischargeoffset AS offset_discharge
  FROM `physionet-data.eicu_crd.patient`
  )
  AS pat
  ON pat.pat_pid = rc.patientunitstayid

  WHERE LOWER(respchartvaluelabel) LIKE "%endotracheal%" 
  OR LOWER(respchartvaluelabel) LIKE "%ett%" 
  OR LOWER(respchartvaluelabel) LIKE "%ET Tube%"

  GROUP BY patientunitstayid
)

, vent_nc AS (

  SELECT nc.patientunitstayid AS nc_pid, 
  1 AS vent_yes,
  MIN(cellattribute) AS event,
  
  MIN(CASE 
  WHEN (cellattribute = "Airway Size" OR cellattribute = "Airway Type") THEN nursecareentryoffset
 ELSE 0
  END) AS vent_start_delta,

  MAX(CASE 
  WHEN (cellattribute = "Airway Size" OR cellattribute = "Airway Type") THEN nursecareentryoffset
 ELSE 0
  END) AS vent_stop_delta,

  MAX(offset_discharge) AS offset_discharge

  FROM `physionet-data.eicu_crd.nursecare` AS nc

  LEFT JOIN(
  SELECT patientunitstayid AS pat_pid, unitdischargeoffset AS offset_discharge
  FROM `physionet-data.eicu_crd.patient`
  )
  AS pat
  ON pat.pat_pid = nc.patientunitstayid

  WHERE cellattribute = "Airway Size" 
  OR cellattribute = "Airway Type"

  GROUP BY patientunitstayid
)

, vent_note AS (

  SELECT patientunitstayid AS note_pid,
  1 AS vent_yes,
  MIN(notetype) AS event,

  MIN(CASE 
  WHEN notetype = "Intubation" THEN noteoffset
 ELSE 0
  END) AS vent_start_delta,

  MIN(CASE 
  WHEN notetype = "Extubation" THEN noteoffset
 ELSE 0
  END) AS vent_stop_delta,

  MAX(offset_discharge) AS offset_discharge

  FROM `physionet-data.eicu_crd.note` AS note

  LEFT JOIN(
  SELECT patientunitstayid AS pat_pid, unitdischargeoffset AS offset_discharge
  FROM `physionet-data.eicu_crd.patient`
  )
  AS pat
  ON pat.pat_pid = note.patientunitstayid

  WHERE notetype = "Intubation" OR notetype = "Extubation"

  GROUP BY patientunitstayid

) 

, vent_vente AS (

  SELECT patientunitstayid AS vent_pid, 
  1 AS vent_yes,
  MIN(event), 

  MIN(CASE 
  WHEN (event = "mechvent start" ) THEN (hrs*60)
 ELSE 0
  END) AS vent_start_delta,

  MAX(CASE 
  WHEN (event = "mechvent end" ) THEN (hrs*60)
 ELSE 0
  END) AS vent_stop_delta,

  MAX(CASE 
  WHEN (event = "ICU Discharge" ) THEN (hrs*60)
 ELSE 0
  END) AS offset_discharge

  FROM `physionet-data.eicu_crd_derived.ventilation_events`

  WHERE event = "ICU Discharge" 
  OR event = "mechvent start"
  OR event = "mechvent end"

  GROUP BY patientunitstayid
) 

/*
airwaytype -> Oral ETT, Nasal ETT, Tracheostomy, Double-Lumen Tube (do not use -> Cricothyrotomy)
airwaysize -> all unless ""
airwayposition -> all unless: Other (Comment), deflated, mlt, Documentation undone

Heuristic for times 
use ventstartoffset for start of ventilation
use priorventendoffset for end of ventilation
*/

, resp_care AS (

  SELECT 
  patientunitstayid, 
  1 AS vent_yes,
  MIN(airwaytype) AS event,
  
  MIN(CASE 
  WHEN LOWER(airwaytype) LIKE "%ETT%"
  OR LOWER(airwaytype) LIKE "%Tracheostomy%"
  OR LOWER(airwaytype) LIKE "%Tube%"
  OR LOWER(airwaysize) NOT LIKE ""
  OR LOWER(airwayposition) NOT LIKE "Other (Comment)"
  OR LOWER(airwayposition) NOT LIKE "deflated"
  OR LOWER(airwayposition) NOT LIKE "mlt"
  OR LOWER(airwayposition) NOT LIKE "Documentation undone"
  THEN ventstartoffset
  ELSE NULL
  END) AS vent_start_delta,

  MAX(CASE 
  WHEN LOWER(airwaytype) LIKE "%ETT%" 
  OR LOWER(airwaytype) LIKE "%Tracheostomy%" 
  OR LOWER(airwaytype) LIKE "%Tube%"
  OR LOWER(airwaysize) NOT LIKE ""
  OR LOWER(airwayposition) NOT LIKE "Other (Comment)"
  OR LOWER(airwayposition) NOT LIKE "deflated"
  OR LOWER(airwayposition) NOT LIKE "mlt"
  OR LOWER(airwayposition) NOT LIKE "Documentation undone"
  THEN priorventendoffset
  ELSE NULL
  END) AS vent_stop_delta,

  MAX(offset_discharge) AS offset_discharge

  FROM `physionet-data.eicu_crd.respiratorycare` AS rcare

  LEFT JOIN(
  SELECT patientunitstayid AS pat_pid, unitdischargeoffset AS offset_discharge
  FROM `physionet-data.eicu_crd.patient`
  )
  AS pat
  ON pat.pat_pid = rcare.patientunitstayid

  WHERE LOWER(airwaytype) LIKE "%ETT%" 
  OR LOWER(airwaytype) LIKE "%Tracheostomy%" 
  OR LOWER(airwaytype) LIKE "%Tube%"
  OR LOWER(airwaysize) NOT LIKE ""
  OR LOWER(airwayposition) NOT LIKE "Other (Comment)"
  OR LOWER(airwayposition) NOT LIKE "deflated"
  OR LOWER(airwayposition) NOT LIKE "mlt"
  OR LOWER(airwayposition) NOT LIKE " Documentation undone"

  GROUP BY patientunitstayid
)

, care_plan AS (

  SELECT 
  patientunitstayid, 
  1 AS vent_yes,
  STRING_AGG(cplitemvalue) AS event,

  MIN(CASE 
  WHEN cplitemvalue LIKE "Intubated%"
  OR cplitemvalue LIKE "Ventilated%"
  THEN cplitemoffset
  ELSE NULL
  END) AS vent_start_delta,

  NULL AS vent_stopp_delta, -- empty column as data is not reliable enough

  MAX(offset_discharge) AS offset_discharge

  FROM `physionet-data.eicu_crd.careplangeneral` AS cpg

  LEFT JOIN(
  SELECT patientunitstayid AS pat_pid, unitdischargeoffset AS offset_discharge
  FROM `physionet-data.eicu_crd.patient`
  )
  AS pat
  ON pat.pat_pid = cpg.patientunitstayid

  WHERE cplgroup = "Airway" 
  OR cplgroup = "Ventilation"
  AND cplitemvalue NOT LIKE ""

  GROUP BY patientunitstayid

)

, union_table AS (

  SELECT * FROM resp_chart

  UNION DISTINCT

  SELECT * FROM vent_nc

  UNION DISTINCT

  SELECT * FROM vent_note

  UNION DISTINCT

  SELECT * FROM vent_vente
  
  UNION DISTINCT

  SELECT * FROM resp_care

  UNION DISTINCT

  SELECT * FROM care_plan
)

SELECT 
patientunitstayid,
MAX(vent_yes) AS vent_yes,
STRING_AGG(event) AS event,
MIN(vent_start_delta) AS vent_start_delta,
MAX(vent_stop_delta) AS vent_stop_delta,
MAX(offset_discharge) AS offset_discharge,

CASE 
WHEN (MAX(vent_stop_delta != 0) OR MAX(vent_stop_delta IS NOT NULL))
THEN (MAX(vent_stop_delta) - MIN(vent_start_delta))
ELSE (MAX(offset_discharge) - MIN(vent_start_delta))
END AS vent_duration

FROM union_table 

WHERE vent_start_delta IS NOT NULL

GROUP BY patientunitstayid
ORDER BY patientunitstayid, event

)
AS v1
ON v1.patientunitstayid= icu.patientunitstayid

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
    , MAX(rrt_yes) AS rrt_yes
    , MIN(rrt_start_delta) AS rrt_start_delta

  FROM rrt_temp
  GROUP BY patientunitstayid

)
AS rrt_overall
ON rrt_overall.patientunitstayid = icu.patientunitstayid


--  Query to get vasopressors
LEFT JOIN(

  -- Get a vasopressors offset table first
  WITH vp_offest_table AS (

    -- pivoted infusions table to get vasopressors
    SELECT 
      patientunitstayid,
      CASE
        WHEN COUNT(norepinephrine) >= 1 THEN 1
        WHEN COUNT(phenylephrine) >= 1 THEN 1
        WHEN COUNT(epinephrine) >= 1 THEN 1
        WHEN COUNT(vasopressin) >= 1 THEN 1
        ELSE NULL
        END AS vp_yes,
      
      MIN(chartoffset) AS vp_start_offset
    
    FROM `physionet-data.eicu_crd_derived.pivoted_infusion`
    GROUP BY patientunitstayid

    UNION DISTINCT

    -- infusions table to get vasopressors
    SELECT 
      patientunitstayid,
      CASE
        WHEN COUNT(drugname) >= 1 THEN 1
        ELSE NULL
        END AS vp_yes,
      
      MIN (infusionoffset) AS vp_start_offset
   
    FROM `physionet-data.eicu_crd.infusiondrug`
    WHERE(
      LOWER(drugname) LIKE '%norepinephrine%' 
      OR LOWER(drugname) LIKE '%phenylephrine%'
      OR LOWER(drugname) LIKE '%epinephrine%'
      OR LOWER(drugname) LIKE '%vasopressin%'
      OR LOWER(drugname) LIKE '%neo synephrine%' 
      OR LOWER(drugname) LIKE '%neo-synephrine%' 
      OR LOWER(drugname) LIKE '%neosynephrine%'
      OR LOWER(drugname) LIKE '%neosynsprine%'
    )
    GROUP BY patientunitstayid

    UNION DISTINCT

    -- medication
    SELECT 
      patientunitstayid,
      CASE
        WHEN COUNT(drugname) >= 1 THEN 1
        ELSE NULL
        END AS vp_yes,
      
      MIN (drugstartoffset) as vp_start_offset

    FROM `physionet-data.eicu_crd.medication`
    WHERE(
      LOWER(drugname) LIKE '%norepinephrine%' 
      OR LOWER(drugname) LIKE '%phenylephrine%'
      OR LOWER(drugname) LIKE '%epinephrine%'
      OR LOWER(drugname) LIKE '%vasopressin%'
      OR LOWER(drugname) LIKE '%neo synephrine%' 
      OR LOWER(drugname) LIKE '%neo-synephrine%' 
      OR LOWER(drugname) LIKE '%neosynephrine%'
      OR LOWER(drugname) LIKE '%neosynsprine%'
    )
    GROUP BY patientunitstayid

    UNION DISTINCT

    -- pivoted med
    SELECT 
      patientunitstayid,
      
      CASE
        WHEN SUM(norepinephrine) >= 1 THEN 1
        WHEN SUM(phenylephrine) >= 1 THEN 1
        WHEN SUM(epinephrine) >= 1 THEN 1
        WHEN SUM(vasopressin) >= 1 THEN 1
        ELSE NULL
        END AS vp_yes,

      MIN (chartoffset) as vp_start_offset

    FROM `physionet-data.eicu_crd_derived.pivoted_med`
    GROUP BY patientunitstayid
    HAVING vp_yes IS NOT NULL
  )

  SELECT DISTINCT
      patientunitstayid,
      
      CASE
        WHEN COUNT(vp_yes) >= 1 THEN 1
        ELSE NULL
        END AS vp_yes,

      MIN (vp_start_offset) as vp_start_offset
  
  FROM vp_offest_table
  GROUP BY patientunitstayid

)
AS vp
ON vp.patientunitstayid = icu.patientunitstayid

ORDER BY patientunitstayid