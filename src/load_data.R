library(magrittr) 
library(dplyr)
library(gdata)

load_data <- function(cohort){

  file_path <- paste0("data/cohort_", cohort, ".csv")

  # Load Data  
  data <- read.csv(file_path, header = TRUE, stringsAsFactors = TRUE)

  if (file_path == "data/cohort_eICU.csv") {
    
    data <- data %>% mutate(anchor_age = ifelse(anchor_age == "> 89", 91, strtoi(anchor_age)))
  }
  # Replace all NAs with 0
  #data[is.na(data)] <- 0

  # Return just keeping columns of interest
  return(data[, c("sex_female", "race_group", "anchor_age",
                  "mech_vent", "rrt", "vasopressor",  
                  "CCI",  "SOFA", "los_icu",
                  "mortality_in", "has_cancer",
                  "cat_solid", "cat_hematological", "cat_metastasized",
                  "loc_colon_rectal", "loc_liver_bd", "loc_pancreatic", "loc_lung_bronchus",
                  "loc_melanoma", "loc_breast", "loc_endometrial", "loc_prostate",
                  "loc_kidney", "loc_bladder", "loc_thyroid", "loc_nhl", "loc_leukemia",
                  "com_hypertension_present", "com_heart_failure_present", "com_asthma_present",
                  "com_copd_present", "com_ckd_stages",
                  "is_full_code_admission", "is_full_code_discharge")
             ])
}

get_merged_datasets <- function() {

  mimic <- load_data("MIMIC")
  eicu <- load_data("eICU")

  # merge both datasets 
  data <- combine(mimic, eicu)
  
  write.csv(data, "data/cohort_merged.csv")

  return (data)
}

get_merged_datasets()