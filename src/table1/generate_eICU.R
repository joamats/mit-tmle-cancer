# Code for creating Table 1 in MIMIC data
library(tidyverse)
library(table1)
library(dplyr)
library(flextable)
library(magrittr)

df <- read_csv('data/table_eICU.csv', show_col_types = FALSE)
final_df <- df

final_df$race_new = final_df$race
final_df <- final_df %>% mutate(race_new = ifelse(race == "Caucasian", "White", "Non-White"))

final_df$dis_expiration = final_df$hospitaldischargelocation
final_df <- final_df %>% mutate(dis_expiration = ifelse(dis_expiration == "Death", "Died", "Survived"))

# Treatments
final_df$pressor_lab = final_df$PRESSOR_final
final_df$pressor_lab[final_df$PRESSOR_final == 1] <- "Received"
final_df$pressor_lab[is.na(final_df$PRESSOR_final)] <- "Did not receive"

final_df$rrt_new = final_df$RRT_final
final_df$rrt_new[final_df$RRT_final == 1] <- "Received"
final_df$rrt_new[is.na(final_df$RRT_final)] <- "Did not receive"

final_df$vent_req = final_df$VENT_final
final_df$vent_req[final_df$VENT_final == 1] <- "Received"
final_df$vent_req[is.na(final_df$VENT_final)] <- "Did not receive"

# Age groups
final_df$age <- as.numeric(final_df$age) # destring age, replace >89 == 91 
final_df$age[is.na(final_df$age)] <- 91

final_df$age_new <- final_df$age

final_df$age_new[final_df$age_new >= 18 
                 & final_df$age_new <= 44] <- "18 - 44"

final_df$age_new[final_df$age_new >= 45 
                 & final_df$age_new <= 64] <- "45 - 64"

final_df$age_new[final_df$age_new >= 65 
                 & final_df$age_new <= 74] <- "65 - 74"

final_df$age_new[final_df$age_new >= 75 
                 & final_df$age_new <= 84] <- "75 - 84"

final_df$age_new[final_df$age_new >= 85] <- "85 and higher"

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

final_df$los_hosp = (final_df$hospitaldischargeoffset/1440)

final_df$los_hosp[final_df$los_hosp < 0] <- 0 # clean data to have minimum of 0 days

# Cancer Types
final_df$other[!is.na(final_df$other)] <- "Yes"
final_df$breast[!is.na(final_df$breast)] <- "Yes"
final_df$prostate[!is.na(final_df$prostate)] <- "Yes"
final_df$lung_bronchus[!is.na(final_df$lung_bronchus)] <- "Yes"
final_df$melanoma[!is.na(final_df$melanoma)] <- "Yes"
final_df$bladder[!is.na(final_df$bladder)] <- "Yes"
final_df$endometrial[!is.na(final_df$endometrial)] <- "Yes"
final_df$pancreatic[!is.na(final_df$pancreatic)] <- "Yes"
final_df$thyroid[!is.na(final_df$thyroid)] <- "Yes"
final_df$liver_bd[!is.na(final_df$liver_bd)] <- "Yes"


# Get data into factor format

final_df$gender <- factor(df$gender)

final_df$pressor_lab <- factor(final_df$pressor_lab)
final_df$rrt_new <- factor(final_df$rrt_new)
final_df$pressor_lab <- factor(final_df$pressor_lab)

final_df$discharge_location <- factor(final_df$hospitaldischargelocation)

final_df$dis_expiration <- factor(final_df$dis_expiration)

final_df$SOFA_new <- factor(final_df$SOFA_new, levels = c('0 - 5', '6 - 10','11 - 15', '16 and above' ))
final_df$charlson_new <- factor(final_df$charlson_new, levels = c('0 - 5', '6 - 10','11 - 15', '16 and above'))



# Factorize and label variables
label(final_df$age_new) <- "Age by group"
units(final_df$age_new) <- "years"

label(final_df$age) <- "Age overall"
units(final_df$age) <- "years"

label(final_df$gender) <- "Sex"

label(final_df$SOFA) <- "SOFA overall"
label(final_df$SOFA_new) <- "SOFA"

label(final_df$los_hosp) <- "Length of stay"
units(final_df$los_hosp) <- "days"

label(final_df$race_new) <- "Race"

label(final_df$charlson_comorbidity_index) <- "Charlson index overall"
label(final_df$charlson_new) <- "Charlson index"

label(final_df$vent_req) <- "Mechanic Ventilation"
label(final_df$rrt_new) <- "Renal Replacement Therapy"
label(final_df$pressor_lab) <- "Vasopressor(s)"

label(final_df$dis_expiration) <- "In-hospital Mortality"

label(final_df$other) <- "Other"
label(final_df$metastasized) <- "Metastasized"
label(final_df$breast) <- "Breast"
label(final_df$lung_bronchus) <- "Lung (including bronchus)"
label(final_df$colon_retal) <- "Colon and Rectal (combined)"
label(final_df$melanoma) <- "Melanoma"
label(final_df$bladder) <- "Bladder"
label(final_df$kidney) <- "Kidney"
label(final_df$endometrial) <- "Endometrial"
label(final_df$leukemia) <- "Leukemia"
label(final_df$pancreatic) <- "Pancreatic"
label(final_df$thyroid) <- "Thyroid"
label(final_df$liver_bd) <- "Liver and intrahepatic BD"

label(final_df$race_new) <- "Race"


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
               age_new + age + gender + SOFA_new + SOFA + 
               charlson_new + charlson_comorbidity_index + los_hosp +
               other + metastasized + breast + prostate + lung_bronchus +
               colon_retal + melanoma + bladder + kidney + nhl + endometrial +
               leukemia + pancreatic + thyroid + liver_bd +
               race_new,
               data=final_df,
               render.missing=NULL,
               topclass="Rtable1-grid Rtable1-shade Rtable1-times",
               render.categorical=render.categorical,
               render.strat=render.strat
              )

# Convert to flextable
t1flex(tbl1) %>% save_as_docx(path="results/table1/eICU.docx")