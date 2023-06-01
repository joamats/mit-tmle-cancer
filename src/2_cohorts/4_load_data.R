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
      file_path == "data/cohorts/eICU_cancer.csv" |
      file_path == "data/cohorts/eICU_all_surviving.csv" |
      file_path == "data/cohorts/eICU_cancer_surviving.csv") {
      
      # create empty columns, as this info is missing in eICU
      data['mortality_90'] <- NA

    } 
  
  # Show the data frame
  # check if eICU or MIMIC in cohort name
  if (grepl("eICU", cohort)) {
    print(paste0("eICU cohort: ", cohort))
  } else {
    print(paste0("MIMIC cohort: ", cohort))
  }

  data$ethno_white <- data$race_group 
  data <- data %>% mutate(ethno_white = ifelse(race_group=="White", 1, 0))

  # Replace all NAs in cancer types and comorbidities with 0
  cancer_list <- c("has_cancer", "group_solid", "group_hematological", "group_metastasized",
                    "loc_colon_rectal", "loc_liver_bd", "loc_pancreatic", "loc_lung_bronchus",
                    "loc_melanoma", "loc_breast", "loc_endometrial", "loc_prostate",
                    "loc_kidney", "loc_bladder", "loc_thyroid", "loc_nhl", "loc_leukemia",
                    "com_copd_present", "com_asthma_present", "com_heart_failure_present",
                    "com_hypertension_present", 'mv_elig', 'rrt_elig', 'vp_elig')

  data <- data %>% mutate_at(cancer_list, ~ replace_na(., 0))

  # Encode CKD stages as binary
  data <- within(data, com_ckd_stages <- factor(com_ckd_stages, levels = c(0, 1, 2, 3, 4, 5)))
  data <- within(data, com_ckd_stages <- fct_collapse(com_ckd_stages,"0" = c("0", "1", "2"), "1" = c("3", "4", "5")))
  
  if (file_path == paste0("data/cohorts/", cohort, ".csv")) {
    
    sepsis_data <- sepsis_data %>% mutate(gender = ifelse(gender == "F", 1, 0))
    
    mech_vent <- sepsis_data[, c(1)] 
    sepsis_data <- cbind(sepsis_data, mech_vent)

    sepsis_data <- sepsis_data %>% mutate(mech_vent = ifelse((InvasiveVent_hr > 0 & !is.na(InvasiveVent_hr)) |
                                                                   (Trach_hr > 0 & !is.na(Trach_hr)), 1, 0))
    sepsis_data <- sepsis_data %>% mutate(pressor = ifelse(pressor=="True", 1, 0))
    sepsis_data <- sepsis_data %>% mutate(rrt = ifelse(is.na(rrt), 0, 1))

    sepsis_data <- sepsis_data %>% mutate(discharge_hosp = ifelse(discharge_location == "HOSPICE", 1, 0))
    sepsis_data <- sepsis_data %>% mutate(ethnicity_white = ifelse(race == "WHITE" | race == "WHITE - BRAZILIAN" | race == "WHITE - EASTERN EUROPEAN" | race == "WHITE - OTHER EUROPEAN" | race == "WHITE - RUSSIAN" | race == "PORTUGUESE", 1, 0))

    sepsis_data$charlson_cont <- sepsis_data$charlson_comorbidity_index # create unified and continous Charlson column
    
    sepsis_data <- sepsis_data %>% mutate(charlson_comorbidity_index = ifelse(
      charlson_comorbidity_index >= 0 & charlson_comorbidity_index <= 5, "0 - 5", ifelse(
        charlson_comorbidity_index >= 6 & charlson_comorbidity_index <= 10, "6 - 10", ifelse(
          charlson_comorbidity_index >= 11 & charlson_comorbidity_index <= 15, "11 - 15", "16 and above"))))
          
    sepsis_data$los <- as.numeric(difftime(sepsis_data$dischtime, sepsis_data$admittime, units = 'days')) # Length of stay MIMIC

    sepsis_data$OASIS_W <- sepsis_data$oasis
    sepsis_data$OASIS_N <- sepsis_data$oasis
    sepsis_data$OASIS_B <- sepsis_data$oasis

    # drop row if oasis_prob is nan
    sepsis_data <- sepsis_data[!is.na(sepsis_data$oasis_prob), ]

    # rename oasis_prob into prob_mort
    sepsis_data <- sepsis_data %>% rename(prob_mort = oasis_prob)

    # clean fluids_volume: if fluids_volume_norm_by_los_icu is over 4000, set it to 4000
    # and then adjust fluids_volume accordingly, given the los_icu
    sepsis_data$fluids_volume_norm_by_los_icu[sepsis_data$fluids_volume_norm_by_los_icu > 4000] <- 4000
    sepsis_data$fluids_volume <- sepsis_data$fluids_volume_norm_by_los_icu * sepsis_data$los_icu

    # add 0 to fluids_volume if it is NA
    sepsis_data$fluids_volume[is.na(sepsis_data$fluids_volume)] <- 0

    # MV_time_perc_of_stay: make 0 if na
    sepsis_data$MV_time_perc_of_stay[is.na(sepsis_data$MV_time_perc_of_stay)] <- 0
    # VP_time_perc_of_stay: make 0 if na
    sepsis_data$VP_time_perc_of_stay[is.na(sepsis_data$VP_time_perc_of_stay)] <- 0
    # MV_init_offset_perc: make 0 if na
    sepsis_data$MV_init_offset_perc[is.na(sepsis_data$MV_init_offset_perc)] <- 0
    sepsis_data$MV_init_offset_d_abs[is.na(sepsis_data$MV_init_offset_d_abs)] <- 0
    # RRT_time_perc_of_stay: make 0 if na
    sepsis_data$RRT_init_offset_perc[is.na(sepsis_data$RRT_init_offset_perc)] <- 0
    sepsis_data$RRT_init_offset_d_abs[is.na(sepsis_data$RRT_init_offset_d_abs)] <- 0
    # VP_init_offset_perc: make 0 if na
    sepsis_data$VP_init_offset_perc[is.na(sepsis_data$VP_init_offset_perc)] <- 0
    sepsis_data$VP_init_offset_d_abs[is.na(sepsis_data$VP_init_offset_d_abs)] <- 0

    # If FiO2 is not available and Oxygen_hr, HighFlow_hr, and NonInvasiveVent_hr are all na, then FiO2 = 21%
    # i.e, no oxygen therapy at all -> room air
    sepsis_data$FiO2_mean_24h[is.na(sepsis_data$FiO2_mean_24h) & is.na(sepsis_data$oxygen_hr) &
                     is.na(sepsis_data$highflow_hr) & is.na(sepsis_data$noninvasivevent_hr) &
                     is.na(sepsis_data$InvasiveVent_hr) & is.na(sepsis_data$Trach_hr)] <- 21

    # else if FiO2_mean_24h is na, set it to -1 bc we don't know how to impute it
    sepsis_data$FiO2_mean_24h[is.na(sepsis_data$FiO2_mean_24h)] <- -1

    # encode insurance as numeric
    sepsis_data$insurance <- as.numeric(sepsis_data$insurance)    

    # Encode outcomes

    # Definition of "free days" outcomes:
    # “Free day” outcomes were calculated as 28 minus the number of days on therapy (MV, RRT, or VP)
    # Patients who died in the hospital were assigned 0 “free days”

    sepsis_data$free_days_mv_28 <- pmax(round((28 - sepsis_data$mv_time_d), 0), 0)
    sepsis_data$free_days_rrt_28 <- pmax(round((28 - sepsis_data$rrt_time_d), 0), 0)
    sepsis_data$free_days_vp_28 <- pmax(round((28 - sepsis_data$vp_time_d), 0), 0)
    sepsis_data$los_icu[sepsis_data$los_icu < 0] <- 0 # clean data to have minimum of 0 days
    sepsis_data$free_days_hosp_28 <- pmax(round((28 - sepsis_data$los_icu), 0), 0)
    # round to closest integer day, use pmax to convert values < 0 to 0

    # set free days to 0 if NA
    sepsis_data <- sepsis_data %>% mutate(free_days_hosp_28 = ifelse(is.na(free_days_hosp_28), 0, free_days_hosp_28))
    sepsis_data <- sepsis_data %>% mutate(free_days_mv_28 = ifelse(is.na(free_days_mv_28), 0, free_days_mv_28))
    sepsis_data <- sepsis_data %>% mutate(free_days_rrt_28 = ifelse(is.na(free_days_rrt_28), 0, free_days_rrt_28))
    sepsis_data <- sepsis_data %>% mutate(free_days_vp_28 = ifelse(is.na(free_days_vp_28), 0, free_days_vp_28))
    
    # set free days to 0 in case of death
    sepsis_data <- sepsis_data %>% mutate(free_days_hosp_28 = ifelse(mortality_in == 1, 0, free_days_hosp_28))
    sepsis_data <- sepsis_data %>% mutate(free_days_mv_28 = ifelse(mortality_in == 1, 0, free_days_mv_28))
    sepsis_data <- sepsis_data %>% mutate(free_days_rrt_28 = ifelse(mortality_in == 1, 0, free_days_rrt_28))
    sepsis_data <- sepsis_data %>% mutate(free_days_vp_28 = ifelse(mortality_in == 1, 0, free_days_vp_28))

    # Therapy within eligibility period
    sepsis_data <- sepsis_data %>% mutate(mv_elig = ifelse(mech_vent == 1 & (MV_init_offset_d_abs <= 1), 1, 0))
    sepsis_data <- sepsis_data %>% mutate(vp_elig = ifelse(pressor == 1 & (VP_init_offset_d_abs <= 1), 1, 0))
    sepsis_data <- sepsis_data %>% mutate(rrt_elig = ifelse(rrt == 1 & (RRT_init_offset_d_abs <= 3), 1, 0))

    # Drop observations with LOS <= 1 day
    sepsis_data <- sepsis_data[sepsis_data$los_icu >= 1, ]
    sepsis_data <- sepsis_data[sepsis_data$los_icu <= 30, ]

    # odd hours for negative control outcome
    sepsis_data$dischtime <- as.POSIXct(sepsis_data$dischtime)

    # Extract hour from 'dischtime'
    sepsis_data$hour <- format(sepsis_data$dischtime, "%H")

    # Convert hour to numeric
    sepsis_data$hour <- as.numeric(sepsis_data$hour)

    # Create new column 'odd_hour' based on 'hour'
    sepsis_data$odd_hour <- ifelse(sepsis_data$hour %% 2 == 1, 1, 0)

    # Return just keeping columns of interest
    return(sepsis_data[, c("admission_age", "gender", "ethnicity_white", "race_group", "insurance", "odd_hour",
                          #  "weight_admit",  "eng_prof",
                          "anchor_year_group", 
                          "adm_elective", "major_surgery", "is_full_code_admission",
                          "is_full_code_discharge", "prob_mort", "discharge_hosp", "OASIS_N",
                          "SOFA", "respiration", "coagulation", "liver", "cardiovascular",
                          "cns", "renal", "charlson_cont",
                          "MV_time_perc_of_stay", "FiO2_mean_24h","VP_time_perc_of_stay",
                          "MV_init_offset_perc","RRT_init_offset_perc","VP_init_offset_perc",
                          "fluids_volume", 
                          "resp_rate_mean", "mbp_mean", "heart_rate_mean", "temperature_mean",
                          "spo2_mean", "po2_min", "pco2_max", "ph_min", "lactate_max", "glucose_max",
                          "sodium_min", "potassium_max", "cortisol_min", "hemoglobin_min",
                          "fibrinogen_min", "inr_max", "hypertension_present", "heart_failure_present",
                          "copd_present", "asthma_present", "cad_present", "ckd_stages", "diabetes_types",
                          "connective_disease", "pneumonia", "uti", "biliary", "skin", "mortality_in",
                          "blood_yes", "insulin_yes", "los", "mortality_90", "comb_noso", "clabsi", "cauti", "ssi", "vap",
                          "mech_vent", "rrt", "pressor", "mv_elig", "rrt_elig", "vp_elig",
                          "free_days_rrt_28", "free_days_mv_28", "free_days_vp_28", "free_days_hosp_28") 
                          ])


  } else if (file_path == "data/eICU_data.csv") {

    # generate dummy var for eICU reliable hospitals -> match with list from Leo
    # rel_hosp <- read.csv("hospitals/reliable_teach_hosp.csv", header = TRUE, stringsAsFactors = TRUE)
    # sepsis_data <- sepsis_data %>%  mutate(rel_icu = ifelse(sepsis_data$hospitalid %in% rel_hosp$hospitalid , 1, 0))
    # sepsis_data <- subset(sepsis_data, rel_icu == 1) # only keep reliable hospitals

    sepsis_data <- sepsis_data %>% mutate(gender = ifelse(gender == "Female", 1, 0))

    sepsis_data <- sepsis_data %>% mutate(death_bin = ifelse(unitdischargelocation == "Death" | unitdischargestatus == "Expired" | hospitaldischargestatus == "Expired", 1, 0))
    # Rename mortality_in to mortality_in
    sepsis_data <- sepsis_data %>% rename(death_bin = mortality_in)

    sepsis_data <- sepsis_data %>% mutate(discharge_hosp = ifelse(unitdischargelocation == "HOSPICE", 1, 0)) # dummy line to have homogeneous columns 
    sepsis_data <- sepsis_data %>% mutate(ethnicity_white = ifelse(race == "Caucasian", 1, 0))

    sepsis_data$charlson_cont <- sepsis_data$charlson_comorbidity_index # create unified and continous Charlson column
    sepsis_data <- sepsis_data %>% mutate(charlson_comorbidity_index = ifelse(
      charlson_comorbidity_index >= 0 & charlson_comorbidity_index <= 5, "0 - 5", ifelse(
        charlson_comorbidity_index >= 6 & charlson_comorbidity_index <= 10, "6 - 10", ifelse(
          charlson_comorbidity_index >= 11 & charlson_comorbidity_index <= 15, "11 - 15", "16 and above"))))

    sepsis_data <- sepsis_data %>% mutate(anchor_age = ifelse(anchor_age == "> 89", 91, strtoi(anchor_age)))
    # rename into admission_age
    sepsis_data <- sepsis_data %>% rename(admission_age = anchor_age)

    sepsis_data <- sepsis_data %>% mutate(anchor_year_group = as.character(anchor_year_group))
    
    sepsis_data$los <- (sepsis_data$hospitaldischargeoffset/1440) # Generate eICU Lenght of stay

    sepsis_data$OASIS_W <- sepsis_data$score_OASIS_W      # worst case scenario
    sepsis_data$OASIS_N <- sepsis_data$score_OASIS_Nulls  # embracing the nulls
    sepsis_data$OASIS_B <- sepsis_data$score_OASIS_B      # best case scenario

    # drop row if apache_pred_hosp_mort is nan or -1
    sepsis_data <- sepsis_data[!is.na(sepsis_data$apache_pred_hosp_mort), ]
    sepsis_data <- sepsis_data[sepsis_data$apache_pred_hosp_mort != -1, ]

    # rename apache_pred_hosp_mort into prob_mort
    sepsis_data <- sepsis_data %>% rename(prob_mort = apache_pred_hosp_mort)

    # Return just keeping columns of interest
    return(sepsis_data[, c("admission_age", "gender", "ethnicity_white", "race_group",
                          # "weight_admit",  "eng_prof",
                          "anchor_year_group", 
                          "adm_elective", "major_surgery", "is_full_code_admission",
                          "is_full_code_discharge", "prob_mort", 
                          "SOFA", "respiration", "coagulation", "liver", "cardiovascular",
                          "cns", "renal", "charlson_cont",
                          "resp_rate_mean", "mbp_mean", "heart_rate_mean", "temperature_mean",
                          "spo2_mean", "po2_min", "pco2_max", "ph_min", "lactate_max", "glucose_max",
                          "sodium_min", "potassium_max", "cortisol_min", "hemoglobin_min",
                          "fibrinogen_min", "inr_max", "hypertension_present", "heart_failure_present",
                          "copd_present", "asthma_present", "cad_present", "ckd_stages", "diabetes_types",
                          "connective_disease", "pneumonia", "uti", "biliary", "skin", "mortality_in",
                          "blood_yes", "insulin_yes","los", "comb_noso", "clabsi", "cauti", "ssi", "vap",
                          "mech_vent", "rrt", "pressor", "mv_elig", "rrt_elig", "vp_elig",
                          "free_days_rrt_28", "free_days_mv_28", "free_days_vp_28", "free_days_hosp_28") 
                          ])


  } else {
    print("Wrong path or file name.")
  }

  # Rename columns to ensure consistency with other TMLE projects
  data <- data %>% rename("c1" = "id",
                          "c2" = "pages",
                          "c3" = "name")


  # Return just keeping columns of interest
  data <- data[, c("sex_female", "race_group", "anchor_age",
                  "mech_vent", "rrt", "vasopressor",  
                  "CCI", "CCI_ranges", 
                  "ethno_white", 
                  "SOFA", "SOFA_ranges", 
                  "mortality_in", "los_icu",
                  "has_cancer", "group_solid", "group_hematological", "group_metastasized",
                  "loc_colon_rectal", "loc_liver_bd", "loc_pancreatic", "loc_lung_bronchus",
                  "loc_melanoma", "loc_breast", "loc_endometrial", "loc_prostate",
                  "loc_kidney", "loc_bladder", "loc_thyroid", "loc_nhl", "loc_leukemia",
                  "com_hypertension_present", "com_heart_failure_present", "com_asthma_present",
                  "com_copd_present", "com_ckd_stages",
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
  write.csv(data_cancer, "data/cohorts/merged_cancer.csv", row.names = FALSE)
  print('Done!')
}

get_merged_datasets()