library(magrittr) 
library(tidyverse)
library(gdata)

load_data <- function(cohort){

  file_path <- paste0("data/cohort_", cohort, ".csv")

  # Load Data  
  data <- read.csv(file_path, header = TRUE, stringsAsFactors = TRUE)

  if (file_path == "data/cohort_MIMIC_all.csv" | file_path == "data/cohort_MIMIC_cancer.csv") {
    

    # Map ethnicity
    data$ethnicity <- data$race
    data$ethnicity[     data$race == 'OTHER' 
                      | data$race == 'UNABLE TO OBTAIN'
                      | data$race == 'UNKNOWN'
                      | data$race == 'MULTIPLE RACE/ETHNICITY'
                      | data$race == 'PATIENT DECLINED TO ANSWER'
                      | data$race == 'AMERICAN INDIAN/ALASKA NATIVE'
                      | data$race == 'NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER'] <- "OTHER" #7

    data$ethnicity[     data$race == 'HISPANIC OR LATINO' 
                      | data$race == 'HISPANIC/LATINO - GUATEMALAN'
                      | data$race == 'HISPANIC/LATINO - PUERTO RICAN'
                      | data$race == 'HISPANIC/LATINO - DOMINICAN'
                      | data$race == 'HISPANIC/LATINO - MEXICAN'
                      | data$race == 'HISPANIC/LATINO - SALVADORAN'
                      | data$race == 'HISPANIC/LATINO - COLUMBIAN'
                      | data$race == 'HISPANIC/LATINO - HONDURAN'
                      | data$race == 'HISPANIC/LATINO - CENTRAL AMERICAN'
                      | data$race == 'HISPANIC/LATINO - CUBAN'
                      | data$race == 'SOUTH AMERICAN'] <- "HISPANIC" #11

    data$ethnicity[     data$race == 'ASIAN' 
                      | data$race == 'ASIAN - KOREAN'
                      | data$race == 'ASIAN - SOUTH EAST ASIAN'
                      | data$race == 'ASIAN - ASIAN INDIAN'
                      | data$race == 'ASIAN - CHINESE'] <- "ASIAN" #4

    data$ethnicity[     data$race == 'BLACK/AFRICAN AMERICAN' 
                      | data$race == 'BLACK/CARIBBEAN ISLAND'
                      | data$race == 'BLACK/AFRICAN'
                      | data$race == 'BLACK/CAPE VERDEAN'] <- "BLACK" #4

    data$ethnicity[     data$race == 'WHITE' 
                      | data$race == 'WHITE - OTHER EUROPEAN'
                      | data$race == 'WHITE - EASTERN EUROPEAN'
                      | data$race == 'WHITE - BRAZILIAN'
                      | data$race == 'WHITE - RUSSIAN'
                      | data$race == 'PORTUGUESE'] <- "WHITE" #6
      
    data$ethno_white <- data$ethnicity
    data <- data %>% mutate(ethno_white = ifelse(ethno_white == "WHITE", 1, 0))

    data$lang_eng <- data$language
    data <- data %>% mutate(lang_eng = ifelse(lang_eng == "ENGLISH", 1, 0))


    } else if (file_path == "data/cohort_eICU_all.csv" | file_path == "data/cohort_eICU_cancer.csv") {
    
    # Map ethnicity
    data$ethnicity <- data$race
    data$ethnicity[data$ethnicity == "African American"] <- "BLACK"
    data$ethnicity[data$ethnicity == "Asian"] <- "ASIAN"
    data$ethnicity[data$ethnicity == "Caucasian"] <- "WHITE"
    data$ethnicity[data$ethnicity == "Hispanic"] <- "HISPANIC"
    data$ethnicity[data$ethnicity == "Native American" | data$ethnicity == "Other/Unknown" | is.na(data$ethnicity)] <- "OTHER"

    data$ethno_white <- data$ethnicity
    data <- data %>% mutate(ethno_white = ifelse(ethno_white == "WHITE", 1, 0))

    data <- data %>% mutate(anchor_age = ifelse(anchor_age == "> 89", 91, strtoi(anchor_age)))
    data['mortality_90'] <- NA

  } else {

    print("Wrong path or file name.")
  }


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
                  "ethno_white", # "lang_eng",
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
  
  write.csv(data_all, "data/cohort_all_merged.csv")
  write.csv(data_cancer, "data/cohort_cancer_merged.csv")

  data_list <- list(data_all, data_cancer)
  return (data_list)
}

get_merged_datasets()