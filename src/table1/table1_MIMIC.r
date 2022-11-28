# Code for creating Table 1 in MIMIC data
library(tidyverse)
library(table1)
library(dplyr)
library(flextable)
library(magrittr)

df <- read_csv('data/table_MIMIC.csv', show_col_types = FALSE)
final_df <- df

final_df$race_new <- final_df$race
final_df <- final_df %>% mutate(race_new = ifelse(race == "WHITE" | race == "WHITE - BRAZILIAN" | race == "WHITE - EASTERN EUROPEAN" | race == "WHITE - OTHER EUROPEAN" | race == "WHITE - RUSSIAN" | race == "PORTUGUESE", "White", "Non-White"))


final_df$dis_expiration <- final_df$discharge_location
final_df <- final_df %>% mutate(dis_expiration = ifelse(dis_expiration == "DIED" | dis_expiration == "HOSPICE", "Died", "Survived"))

# Treatments
final_df$pressor_lab = final_df$pressor
final_df$pressor_lab[final_df$pressor == 'TRUE'] <- "Received"
final_df$pressor_lab[is.na(final_df$pressor)] <- "Did not receive"

final_df$rrt_new = final_df$rrt
final_df$rrt_new[final_df$rrt == 1] <- "Received"
final_df$rrt_new[is.na(final_df$rrt)] <- "Did not receive"

final_df$vent_req = final_df$InvasiveVent_hr
final_df$vent_req[!is.na(final_df$vent_req)] <- "Received"
final_df$vent_req[is.na(final_df$vent_req)] <- "Did not receive"

# Age groups
final_df$age_new = final_df$admission_age
final_df$age_new[final_df$admission_age >= 18 
                 & final_df$admission_age <= 44] <- "18 - 44"

final_df$age_new[final_df$admission_age >= 45 
                 & final_df$admission_age <= 64] <- "45 - 64"

final_df$age_new[final_df$admission_age >= 65 
                 & final_df$admission_age <= 74] <- "65 - 74"

final_df$age_new[final_df$admission_age >= 75 
                 & final_df$admission_age <= 84] <- "75 - 84"

final_df$age_new[final_df$admission_age >= 85] <- "85 and higher"

# SOFA
final_df$SOFA_new <- final_df$SOFA
final_df$SOFA_new[final_df$SOFA >= 0 
                  & final_df$SOFA <= 5] <- "0 - 5"

final_df$SOFA_new[final_df$SOFA >= 6 
                  & final_df$SOFA <= 10] <- "6 - 10"

final_df$SOFA_new[final_df$SOFA >= 11 
                  & final_df$SOFA <= 15] <- "11 - 15"

final_df$SOFA_new[final_df$SOFA >= 16] <- "16 and above"

# Charlson
final_df$charlson_new <- final_df$charlson_comorbidity_index
final_df$charlson_new[final_df$charlson_comorbidity_index >= 0 
                      & final_df$charlson_comorbidity_index <= 5] <- "0 - 5"

final_df$charlson_new[final_df$charlson_comorbidity_index >= 6 
                      & final_df$charlson_comorbidity_index <= 10] <- "6 - 10"

final_df$charlson_new[final_df$charlson_comorbidity_index >= 11 
                      & final_df$charlson_comorbidity_index <= 15] <- "11 - 15"

final_df$charlson_new[final_df$charlson_comorbidity_index >= 16] <- "16 and above"

final_df$los_hosp <- as.numeric(difftime(final_df$dischtime, final_df$admittime, units = 'days'))

final_df$los_hosp[final_df$los_hosp < 0] <- 0 # clean data to have minimum of 0 days

# Cancer Types
final_df$cancer <- final_df$other
final_df$cancer[final_df$other >= 1] <- "Other (only)"
final_df$cancer[final_df$metastasized >= 1] <- "Metastasized"
final_df$cancer[final_df$breast >= 1] <- "Breast"
final_df$cancer[final_df$prostate >= 1] <- "Prostate"
final_df$cancer[final_df$lung_bronchus >= 1] <- "Lung (including bronchus)"
final_df$cancer[final_df$colon_retal >= 1] <- "Colon and Rectal (combined)"
final_df$cancer[final_df$melanoma >= 1] <- "Melanoma"
final_df$cancer[final_df$bladder >= 1] <- "Bladder"
final_df$cancer[final_df$endometrial >= 1] <- "Endometrial"
final_df$cancer[final_df$leukemia >= 1] <- "Leukemia"
final_df$cancer[final_df$pancreatic >= 1] <- "Pancreatic"
final_df$cancer[final_df$thyroid >= 1] <- "Thyroid"
final_df$cancer[final_df$liver_bd >= 1] <- "Liver and intrahepatic BD"


# Get data into factor format

final_df$gender <- factor(df$gender, levels = c('F', 'M'), 
                          labels = c('Female', 'Male'))

final_df$pressor_lab <- factor(final_df$pressor_lab)
final_df$rrt_new <- factor(final_df$rrt_new)
final_df$pressor_lab <- factor(final_df$pressor_lab)

final_df$discharge_location <- factor(final_df$discharge_location)

final_df$dis_expiration <- factor(final_df$dis_expiration)

final_df$SOFA_new <- factor(final_df$SOFA_new, levels = c('0 - 5', '6 - 10','11 - 15', '16 and above' ))
final_df$charlson_new <- factor(final_df$charlson_new, levels = c('0 - 5', '6 - 10','11 - 15', '16 and above'))
final_df$cancer <- factor(final_df$cancer, levels = c("Breast", 
                                                      "Prostate",
                                                      "Lung (including bronchus)",
                                                      "Colon and Rectal (combined)",
                                                      "Melanoma",
                                                      "Bladder",
                                                      "Endometrial",
                                                      "Leukemia",
                                                      "Pancreatic",
                                                      "Thyroid",
                                                      "Liver and intrahepatic BD",
                                                      "Metastasized",
                                                      "Other (only)"
))



# Factorize and label variables
label(final_df$age_new) <- "Age by group"
units(final_df$age_new) <- "years"

label(final_df$admission_age) <- "Age overall"
units(final_df$admission_age) <- "years"

label(final_df$gender) <- "Sex"

label(final_df$SOFA) <- "SOFA overall"
label(final_df$SOFA_new) <- "SOFA"

label(final_df$cancer) <- "Active Cancer by Type"

label(final_df$los_hosp) <- "Length of stay"
units(final_df$los_hosp) <- "days"

label(final_df$race_new) <- "Race"

label(final_df$charlson_comorbidity_index) <- "Charlson index overall"
label(final_df$charlson_new) <- "Charlson index"

label(final_df$vent_req) <- "Mechanic Ventilation"
label(final_df$rrt_new) <- "Renal Replacement Therapy"
label(final_df$pressor_lab) <- "Vasopressor(s)"

label(final_df$dis_expiration) <- "In-hospital Mortality"

render.categorical <- function(x, ...) {
  c("", sapply(stats.apply.rounding(stats.default(x)), function(y) with(y,
  sprintf("%s (%s%%)", prettyNum(FREQ, big.mark=","), PCT))))
}

render.strat <- function (label, n, ...) {
  sprintf("<span class='stratlabel'>%s<br><span class='stratn'>(N=%s)</span></span>", 
          label, prettyNum(n, big.mark=","))
}

# Create Table1 Object
tbl1 <- table1(~ dis_expiration + vent_req + rrt_new + pressor_lab +
               age_new + admission_age + gender + SOFA_new + SOFA + 
               charlson_new + charlson_comorbidity_index + los_hosp + cancer + race
               | race_new,
               data=final_df,
               render.missing=NULL,
               topclass="Rtable1-grid Rtable1-shade Rtable1-times",
               render.categorical=render.categorical,
               render.strat=render.strat
              )

# Convert to flextable
t1flex(tbl1) %>% save_as_docx(path="results/table1/MIMIC.docx")