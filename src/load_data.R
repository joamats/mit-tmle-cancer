library(magrittr) 
library(dplyr)
library(gdata)

load_data <- function(cohort){

  file_path <- paste0("data/table_", cohort, ".csv")

  # Load Data  
  data <- read.csv(file_path, header = TRUE, stringsAsFactors = TRUE)

  mech_vent <- data[, c(1)] 
  mortality <- data[, c(1)]
  race_white <- data[, c(1)]

  data <- cbind(data, mech_vent, mortality, race_white)

  if (file_path == "data/table_MIMIC.csv") {

    data <- data %>% mutate(gender_female = ifelse(gender == "F", 1, 0))
    data <- data %>% mutate(race_white = ifelse(race == "WHITE" |
                                                race == "WHITE - BRAZILIAN" |
                                                race == "WHITE - EASTERN EUROPEAN" |
                                                race == "WHITE - OTHER EUROPEAN" |
                                                race == "WHITE - RUSSIAN" |
                                                race == "PORTUGUESE", 1, 0))

    data <- data %>% mutate(mech_vent = ifelse(InvasiveVent_hr > 0 & !is.na(InvasiveVent_hr), 1, 0))
    data <- data %>% mutate(rrt = ifelse(is.na(rrt), 0, 1))
    data <- data %>% mutate(pressor = ifelse(pressor=="True", 1, 0))

    data <- data %>% mutate(mortality = ifelse(discharge_location == "DIED" |
                                               discharge_location == "HOSPICE" |
                                               dod != "", 1, 0))
    
    data <- data %>% mutate(has_cancer = ifelse(has_cancer == "True", 1, 0))

    
    # Additional conditions as confounders
    #data <- data %>% mutate(hypertension = ifelse(!is.na(hypertension), 1, 0))
    #data <- data %>% mutate(heart_failure = ifelse(!is.na(heart_failure), 1, 0))
    #data <- data %>% mutate(ckd = ifelse(!is.na(ckd), ckd, 0))
    #data <- data %>% mutate(copd = ifelse(!is.na(copd), 1, 0))
    #data <- data %>% mutate(asthma = ifelse(!is.na(asthma), 1, 0))
    
    # Length of stay MIMIC
    data$los <- as.numeric(difftime(data$dischtime, data$admittime, units = 'days')) 
    data$los[data$los < 0] <- 0 # clean data to have minimum of 0 days


  } else if (file_path == "data/table_eICU.csv") {
    
    data <- data %>% mutate(gender_female = ifelse(gender == "Female", 1, 0))
    data <- data %>% mutate(anchor_age = ifelse(age == "> 89", 91, strtoi(age)))
    data <- data %>% mutate(race_white = ifelse(race == "Caucasian", 1, 0))

    data <- data %>% mutate(mech_vent = ifelse(is.na(VENT_final), 0, 1))
    data <- data %>% mutate(rrt = ifelse(is.na(RRT_final), 0, 1))
    data <- data %>% mutate(pressor = ifelse(is.na(PRESSOR_final), 0, 1))

    data <- data %>% mutate(mortality = ifelse(unitdischargelocation == "Death" |
                                               unitdischargestatus == "Expired" |
                                               hospitaldischargestatus == "Expired", 1, 0))

    data <- data %>% mutate(has_cancer = ifelse(has_cancer == "True", 1, 0))


    # Additional conditions as confounders
    #data <- data %>% mutate(hypertension = ifelse(!is.na(hypertension), 1, 0))
    #data <- data %>% mutate(heart_failure = ifelse(!is.na(heart_failure), 1, 0))
    #data <- data %>% mutate(ckd = ifelse(!is.na(ckd), ckd, 0))
    #data <- data %>% mutate(copd = ifelse(!is.na(copd), 1, 0))
    #data <- data %>% mutate(asthma = ifelse(!is.na(asthma), 1, 0))

    data$los <- (data$hospitaldischargeoffset/1440) # Generate eICU Lenght of stay

  } else {
    print("Wrong path or file name.")
  }

  # Replace all NAs with 0
  data[is.na(data)] <- 0

  # Return just keeping columns of interest
  return(data[, c("gender_female", "race_white", "anchor_age",
                  "mech_vent", "rrt", "pressor",  
                  "charlson_comorbidity_index",  "SOFA", "los",
                  "has_cancer", "mortality", 
                  "breast","prostate","lung_bronchus","colon_retal",
                  "melanoma","bladder","nhl","kidney","endometrial",
                  "leukemia","pancreatic","thyroid","liver_bd",
                  "metastasized","other")])
}

get_merged_datasets <- function() {

  mimic <- load_data("MIMIC")
  eicu <- load_data("eICU")

  # merge both datasets 
  data <- combine(mimic, eicu)
  
  write.csv(data, "data/table_all.csv")

  return (data)
}

get_merged_datasets()