library(magrittr) 
library(dplyr)
library(tidyr)
library(gdata)

load_data <- function(cohort){

  file_path <- paste0("data/cohort_", cohort, ".csv")

  # Load Data  
  data <- read.csv(file_path, header = TRUE, stringsAsFactors = TRUE)

 if (file_path == "data/cohort_eICU_all.csv" | file_path == "data/cohort_eICU_cancer.csv") {
    
    data <- data %>% mutate(anchor_age = ifelse(anchor_age == "> 89", 91, strtoi(anchor_age)))
  
    # create empty columns, as this info is missing in eICU
    data['mortality_90'] <- NA
    data['language'] <- NA

  } 

  data$ethno_white <- data$race_group 
  data <- data %>% mutate(ethno_white = ifelse(race_group=="White", 1, 0))

  data$lang_eng <- data$language 
  data <- data %>% mutate(lang_eng = ifelse(language=="ENGLISH", 1, 0))


  # Replace all NAs with 0
  # data[is.na(data)] <- 0

  # Replace all NAs in cancer types with 0
  cancer_list <- c("has_cancer", "cat_solid", "cat_hematological", "cat_metastasized",
                          "loc_colon_rectal", "loc_liver_bd", "loc_pancreatic", "loc_lung_bronchus",
                          "loc_melanoma", "loc_breast", "loc_endometrial", "loc_prostate",
                          "loc_kidney", "loc_bladder", "loc_thyroid", "loc_nhl", "loc_leukemia")
  data <- data %>% mutate_at(cancer_list, ~replace_na(.,0))


  # Return just keeping columns of interest
  return(data[, c("sex_female", "race_group", "anchor_age",
                  "mech_vent", "rrt", "vasopressor",  
                  "CCI", "CCI_ranges", 
                  "ethno_white", "lang_eng",
                  "SOFA", "SOFA_ranges", "los_icu",
                  "mortality_in", "mortality_90",
                  "has_cancer", "cat_solid", "cat_hematological", "cat_metastasized",
                  "loc_colon_rectal", "loc_liver_bd", "loc_pancreatic", "loc_lung_bronchus",
                  "loc_melanoma", "loc_breast", "loc_endometrial", "loc_prostate",
                  "loc_kidney", "loc_bladder", "loc_thyroid", "loc_nhl", "loc_leukemia",
                  "com_hypertension_present", "com_heart_failure_present", "com_asthma_present",
                  "com_copd_present", "com_ckd_stages",
                  "is_full_code_admission", "is_full_code_discharge")
             ])
}

get_merged_datasets <- function() {

  mimic_all <- load_data("MIMIC_all")
  eicu_all <- load_data("eICU_all")
  mimic_cancer <- load_data("MIMIC_cancer")
  eicu_cancer <- load_data("eICU_cancer")

  # merge both datasets 
  data_all <- combine(mimic_all, eicu_all)
  data_cancer <- combine(mimic_cancer, eicu_cancer)
  
  write.csv(data_all, "data/cohort_merged_all.csv")
  write.csv(data_cancer, "data/cohort_merged_cancer.csv")

  data_list <- list(data_all, data_cancer)
  return (data_list)
}

get_merged_datasets()