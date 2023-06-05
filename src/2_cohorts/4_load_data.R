library(magrittr) 
library(dplyr)
library(tidyr)
library(gdata)
library(forcats)

load_data <- function(cohort){

  file_path <- paste0("data/cohorts/", cohort, ".csv")

  # Load Data  
  data <- read.csv(file_path, header = TRUE, stringsAsFactors = TRUE)

  if (file_path == "data/cohorts/eICU_all.csv" | 
      file_path == "data/cohorts/eICU_cancer.csv") {
      
      # create empty columns, as this info is missing in eICU
      data['mortality_90'] <- NA

      # add date before dischtime to have same structure as in MIMIC
      data$dummy_date <- "2022-05-10"     
      data$dischtime <- paste(data$dummy_date, data$dischtime)
      data$dischtime <- as.POSIXct(data$dischtime, format = "%Y-%m-%d %H:%M:%S")

    } 
  
  # Show the data frame
  # check if eICU or MIMIC in cohort name
  if (grepl("eICU", cohort)) {
    print(paste0("eICU cohort: ", cohort))
  } else {
    print(paste0("MIMIC cohort: ", cohort))
  }

  # Common data cleaning steps

  # labs
  # PO2 is within its physiological range
  data$po2_min[data$po2_min < 0] <- 0
  data$po2_min[data$po2_min > 1000] <- 0
  data$po2_min[data$po2_min == 0 |
                      is.na(data$po2_min)] <- 90

  # PCO2 is within its physiological range
  data$pco2_max[data$pco2_max < 0] <- 0
  data$pco2_max[data$pco2_max > 200] <- 0 
  data$pco2_max[data$pco2_max == 0 |
                        is.na(data$pco2_max)] <- 40

  # pH is within its physiological range
  data$ph_min[data$ph_min < 5] <- 0
  data$ph_min[data$ph_min > 10] <- 0
  data$ph_min[data$ph_min == 0 |
                      is.na(data$ph_min)] <- 7.35

  # Lactate is within its physiological range
  data$lactate_max[data$lactate_max < 0] <- 0
  data$lactate_max[data$lactate_max > 30] <- 0
  data$lactate_max[data$lactate_max == 0 |
                          is.na(data$lactate_max)] <- 1.05

  # Glucose is within its physiological range
  data$glucose_max[data$glucose_max < 0] <- 0
  data$glucose_max[data$glucose_max > 2000] <- 0
  data$glucose_max[data$glucose_max == 0 |
                          is.na(data$glucose_max)] <- 95

  # Sodium
  data$sodium_min[is.na(data$sodium_min)] <- 0
  data$sodium_min[data$sodium_min < 0] <- 0
  data$sodium_min[data$sodium_min > 160] <- 0
  data$sodium_min[data$sodium_min == 0 |
                          is.na(data$sodium_min)] <- 140

  # Potassium
  data$potassium_max[data$potassium_max < 0] <- 0
  data$potassium_max[data$potassium_max > 9.9] <- 0
  data$potassium_max[data$potassium_max == 0 |
                            is.na(data$potassium_max)] <- 3.5

  # Cortisol
  data$cortisol_min[data$cortisol_min < 0] <- 0
  data$cortisol_min[data$cortisol_min > 70] <- 0
  data$cortisol_min[data$cortisol_min == 0 |
                            is.na(data$cortisol_min)] <- 20

  # Hemoglobin
  data$hemoglobin_min[data$hemoglobin_min < 3
                            & (data$gender == "M" | data$gender == "Male" | data$gender == 0)] <- 13.5
  data$hemoglobin_min[data$hemoglobin_min < 3
                            & (data$gender == "F" | data$gender == "Female" | data$gender == 1)] <- 12 

  data$hemoglobin_min[data$hemoglobin_min > 30] <- 0

  data$hemoglobin_min[(data$hemoglobin_min == 0 |
                              is.na(data$hemoglobin_min))
                              & (data$gender == "M" | data$gender == "Male" | data$gender == 0)] <- 13.5

  data$hemoglobin_min[(data$hemoglobin_min == 0 |
                              is.na(data$hemoglobin_min))
                              & (data$gender == "F" | data$gender == "Female" | data$gender == 1)] <- 12
  # Fibrinogen
  data$fibrinogen_min[data$fibrinogen_min < 0] <- 0
  data$fibrinogen_min[data$fibrinogen_min > 1000] <- 400
  data$fibrinogen_min[data$fibrinogen_min == 0 |
                              is.na(data$fibrinogen_min)] <- 200
  # INR
  data$inr_max[data$inr_max < 0] <- 0
  data$inr_max[data$inr_max > 10] <- 0
  data$inr_max[data$inr_max == 0 |
                      is.na(data$inr_max)] <- 1.1

  # Respiratory rate
  data$resp_rate_mean[data$resp_rate_mean < 0] <- 0
  data$resp_rate_mean[data$resp_rate_mean > 50] <- 0
  data$resp_rate_mean[data$resp_rate_mean == 0 |
                            is.na(data$resp_rate_mean)] <- 15
  # Heart rate
  data$heart_rate_mean[data$heart_rate_mean < 0] <- 0
  data$heart_rate_mean[data$heart_rate_mean > 250] <- 0
  data$heart_rate_mean[data$heart_rate_mean == 0 |
                            is.na(data$heart_rate_mean)] <- 90

  # MBP
  data$mbp_mean[data$mbp_mean < 0] <- 0
  data$mbp_mean[data$mbp_mean > 200] <- 0
  data$mbp_mean[data$mbp_mean == 0 |
                        is.na(data$mbp_mean)] <- 85
  # Temperature
  data$temperature_mean[data$temperature_mean < 32] <- 0
  data$temperature_mean[data$temperature_mean > 45] <- 0
  data$temperature_mean[data$temperature_mean == 0 |
                              is.na(data$temperature_mean)] <- 36.5

  # SpO2
  data$spo2_mean[data$spo2_mean < 0] <- 0
  data$spo2_mean[data$spo2_mean > 100] <- 0
  data$spo2_mean[data$spo2_mean == 0 |
                        is.na(data$spo2_mean)] <- 95

  # Ethnicity
  data$ethnicity_white <- data$race_group 
  data <- data %>% mutate(ethnicity_white = ifelse(race_group=="White", 1, 0))

  # Replace all NAs in cancer types and comorbidities with 0
  # outcomes and POA / source of infection
  # complications and SOFA
  cancer_list <- c("has_cancer", "group_solid", "group_hematological", "group_metastasized",
                    "loc_colon_rectal", "loc_liver_bd", "loc_pancreatic", "loc_lung_bronchus",
                    "loc_melanoma", "loc_breast", "loc_endometrial", "loc_prostate",
                    "loc_kidney", "loc_bladder", "loc_thyroid", "loc_nhl", "loc_leukemia",
                    "copd_present", "asthma_present", "heart_failure_present", "connective_disease",
                    "hypertension_present", "cad_present", "ckd_stages", "diabetes_types", 
                    "adm_elective", "major_surgery",
                    "clabsi", "cauti", "ssi", "vap", "pneumonia", "uti", "biliary", "skin",
                    "SOFA", "respiration", "coagulation", "liver", "cardiovascular", "cns", "renal", 
                    'mv_elig', 'rrt_elig', 'vp_elig')

  data <- data %>% mutate_at(cancer_list, ~ replace_na(., 0))

  # combine complications
  data <- data %>% mutate(comb_noso = ifelse(clabsi == 1 | cauti == 1 | ssi == 1 | vap == 1, 1, 0))

  # Encode teachingstatus as binary
  data <- data %>% mutate(teaching_hospital = ifelse(teachingstatus == "False", 0, 1))
  
  # Encode CKD stages as binary
  data <- within(data, ckd_stages <- factor(ckd_stages, levels = c(0, 1, 2, 3, 4, 5)))
  data <- within(data, ckd_stages <- fct_collapse(ckd_stages,"0" = c("0", "1", "2"), "1" = c("3", "4", "5")))
  
  # encode anchor_year_group by: MIMIC, 2008-2010, 2011-2013, 2014-2016, 2017-2019 into 1, 2, 3, 4
  # eICU: 2014 = 0, 2015 = 1
  data$anchor_year_group <- as.numeric(data$anchor_year_group)

  # Offsets: make 0 if na
  data$MV_init_offset_d_abs[is.na(data$MV_init_offset_d_abs)] <- 0
  data$RRT_init_offset_d_abs[is.na(data$RRT_init_offset_d_abs)] <- 0
  data$VP_init_offset_d_abs[is.na(data$VP_init_offset_d_abs)] <- 0

  # Definition of "free days" outcomes:
  # “Free day” outcomes were calculated as 28 minus the number of days in the ICU
  # Patients who died in the hospital were assigned 0 “free days”

  data$los_icu[data$los_icu < 0] <- 0 # clean data to have minimum of 0 days
  data$free_days_hosp_28 <- pmax(round((28 - data$los_icu), 0), 0)
  # round to closest integer day, use pmax to convert values < 0 to 0

  # set free days to 0 if NA
  data <- data %>% mutate(free_days_hosp_28 = ifelse(is.na(free_days_hosp_28), 0, free_days_hosp_28))
  
  # set free days to 0 in case of death
  data <- data %>% mutate(free_days_hosp_28 = ifelse(mortality_in == 1, 0, free_days_hosp_28))

  # Therapy within eligibility period
  data <- data %>% mutate(mv_elig = ifelse(mech_vent == 1 & (MV_init_offset_d_abs <= 1), 1, 0))
  data <- data %>% mutate(vp_elig = ifelse(vasopressor == 1 & (VP_init_offset_d_abs <= 1), 1, 0))
  data <- data %>% mutate(rrt_elig = ifelse(rrt == 1 & (RRT_init_offset_d_abs <= 3), 1, 0))

  # odd hours for negative control outcome
  data$dischtime <- as.POSIXct(data$dischtime)

  # Extract hour from 'dischtime'
  data$hour <- format(data$dischtime, "%H")

  # Convert hour to numeric
  data$hour <- as.numeric(data$hour)

  # Create new column 'odd_hour' based on 'hour'
  data$odd_hour <- ifelse(data$hour %% 2 == 1, 1, 0)

  # Return just keeping columns of interest

  data <- data[, c("sex_female", "race_group", "ethnicity_white", "anchor_age",
                  "mech_vent", "rrt", "vasopressor",  
                  "charlson_cont", "CCI_ranges", "anchor_year_group", "adm_elective", "major_surgery",
                  "SOFA", "respiration", "coagulation", "liver", "cardiovascular", "cns", "renal",
                  "prob_mort", 
                  "mortality_in", "los_icu", "free_days_hosp_28", "odd_hour", "comb_noso",
                  "hospitalid", "numbedscategory", "teaching_hospital", "region",
                  "resp_rate_mean", "mbp_mean", "heart_rate_mean", "temperature_mean", "spo2_mean",
                  "po2_min", "pco2_max", "ph_min", "lactate_max", "glucose_max", "sodium_min",
                  "potassium_max", "cortisol_min", "hemoglobin_min", "fibrinogen_min", "inr_max",
                  "has_cancer", "group_solid", "group_hematological", "group_metastasized",
                  "loc_colon_rectal", "loc_liver_bd", "loc_pancreatic", "loc_lung_bronchus",
                  "loc_melanoma", "loc_breast", "loc_endometrial", "loc_prostate",
                  "loc_kidney", "loc_bladder", "loc_thyroid", "loc_nhl", "loc_leukemia",
                  "hypertension_present", "heart_failure_present", "asthma_present",
                  "copd_present", "ckd_stages", "cad_present", "diabetes_types", "connective_disease",
                  "pneumonia", "uti", "biliary", "skin",
                  "clabsi", "cauti", "ssi", "vap",
                  "is_full_code_admission", "is_full_code_discharge", 
                  'mv_elig', 'rrt_elig', 'vp_elig')
             ]
    return(data)

}

get_merged_datasets <- function() {

  mimic_all <- load_data("MIMIC_all")
  eicu_all <- load_data("eICU_all")

  mimic_cancer <- load_data("MIMIC_cancer")
  eicu_cancer <- load_data("eICU_cancer")

  # merge 2 cohorts
  data_all <- combine(mimic_all, eicu_all, names=c("mimc", "eicu"))
  data_cancer <- combine(mimic_cancer, eicu_cancer, names=c("mimc", "eicu"))

  # save ignoring index column
  write.csv(data_all, "data/cohorts/merged_all.csv", row.names = FALSE)
  write.csv(eicu_all, "data/cohorts/merged_eicu_all.csv", row.names = FALSE)
  write.csv(mimic_all, "data/cohorts/merged_mimic_all.csv", row.names = FALSE)

  write.csv(data_cancer, "data/cohorts/merged_cancer.csv", row.names = FALSE)
  write.csv(eicu_cancer, "data/cohorts/merged_eicu_cancer.csv", row.names = FALSE)
  write.csv(mimic_cancer, "data/cohorts/merged_mimic_cancer.csv", row.names = FALSE)

  print('Done!')
}

get_merged_datasets()