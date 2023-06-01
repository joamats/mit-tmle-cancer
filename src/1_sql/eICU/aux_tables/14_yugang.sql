drop table if exists `db_name.my_eICU.yugang`; 
create table `db_name.my_eICU.yugang` as

select pt.*,
sf.sofa_admit,
sf.respiration,
sf.coagulation,
sf.liver,
sf.cardiovascular,
sf.cns,
sf.renal,

(s3.patientunitstayid = vaso.patientunitstayid) as vasopressor,
(s3.patientunitstayid = rrtid.patientunitstayid) as rrt,
(s3.patientunitstayid = ventid.patientunitstayid) as vent,
cci.final_charlson_score as Charlson,
hospitaldischargeoffset / 1440 AS los_icu

from `db_name.icu_elos.sepsis_adult_eicu` s3

left join `physionet-data.eicu_crd.patient` pt
on s3.patientunitstayid = pt.patientunitstayid

left join (select distinct patientunitstayid, 
sofa_resp as respiration,
sofa_gcs as cns,
sofa_circ as cardiovascular,
sofa_liver as liver,
sofa_hematology as coagulation, 
sofa_renal as renal,
sofa as sofa_admit

from `db_name.icu_elos.itu_sofa_day` where day = 1 ) sf
on s3.patientunitstayid = sf.patientunitstayid 

left join (select distinct patientunitstayid from `physionet-data.eicu_crd_derived.pivoted_treatment_vasopressor` ) vaso
on s3.patientunitstayid = vaso.patientunitstayid

left join (select distinct patientunitstayid from `physionet-data.eicu_crd.intakeoutput` where dialysistotal<>0) as rrtid
on s3.patientunitstayid = rrtid.patientunitstayid 

left join (select distinct patientunitstayid from `db_name.icu_elos.invasive`) as ventid
on s3.patientunitstayid = ventid.patientunitstayid 

left join (select patientunitstayid,final_charlson_score from `db_name.icu_elos.charlson_comorbidity_index`) as cci
on  s3.patientunitstayid = cci.patientunitstayid