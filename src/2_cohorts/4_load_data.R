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
  data <- within(data, com_ckd_stages <- fct_collapse(com_ckd_stages,"0"=c("0", "1", "2"), "1"=c("3", "4", "5")))

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
  data_all <- combine(mimic_all, eicu_all)
  data_cancer <- combine(mimic_cancer, eicu_cancer)

  write.csv(data_all, "data/cohorts/merged_all.csv")
  write.csv(data_cancer, "data/cohorts/merged_cancer.csv")
  print('Done!')
}

get_merged_datasets()