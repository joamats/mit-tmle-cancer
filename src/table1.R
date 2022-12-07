# Code for creating Table 1 in MIMIC data
library(tidyverse)
library(table1)
library(dplyr)
library(flextable)
library(magrittr)

source("src/load_data/load_data.R")

df <- read_csv('data/table_all.csv', show_col_types = FALSE)

df <- df %>% mutate(gender_female = ifelse(gender_female == 1, "Female", "Male"))
df <- df %>% mutate(race_white = ifelse(race_white == 1, "White", "Non-White or Unknown"))

df <- df %>% mutate(mortality = ifelse(mortality == 1, "Died", "Survived"))
df <- df %>% mutate(has_cancer = ifelse(has_cancer == 1, "Yes", "No"))

df$age_ranges <- df$anchor_age
df$age_ranges[df$anchor_age >= 18 & df$anchor_age <= 44] <- "18 - 44"
df$age_ranges[df$anchor_age >= 45 & df$anchor_age <= 64] <- "45 - 64"
df$age_ranges[df$anchor_age >= 65 & df$anchor_age <= 74] <- "65 - 74"
df$age_ranges[df$anchor_age >= 75 & df$anchor_age <= 84] <- "75 - 84"
df$age_ranges[df$anchor_age >= 85] <- "85 and higher"

df <- df %>% mutate(mech_vent = ifelse(mech_vent == 1, "Received", "Did not receive"))
df <- df %>% mutate(rrt = ifelse(rrt == 1, "Received", "Did not receive"))
df <- df %>% mutate(pressor = ifelse(pressor == 1, "Received", "Did not receive"))

# SOFA
df$SOFA_ranges <- df$SOFA
df$SOFA_ranges[df$SOFA >= 0 & df$SOFA <= 3] <- "0 - 3"
df$SOFA_ranges[df$SOFA >= 4 & df$SOFA <= 6] <- "4 - 6"
df$SOFA_ranges[df$SOFA >= 7 & df$SOFA <= 10] <- "7 - 10"
df$SOFA_ranges[df$SOFA >= 11] <- "11 and above"

# Charlson
df$cci_ranges <- df$charlson_comorbidity_index
df$cci_ranges[df$charlson_comorbidity_index >= 0 & df$charlson_comorbidity_index <= 3] <- "0 - 3"
df$cci_ranges[df$charlson_comorbidity_index >= 4 & df$charlson_comorbidity_index <= 6] <- "4 - 6"
df$cci_ranges[df$charlson_comorbidity_index >= 7 & df$charlson_comorbidity_index <= 10] <- "7 - 10"
df$cci_ranges[df$charlson_comorbidity_index >= 11] <- "11 and above"

# Cohort of Source
df <- df %>% mutate(source = ifelse(source == "mimic", "MIMIC", "eICU"))


# Cancer Types
#df$other[!is.na(df$other)] <- "Yes"
#df$metastasized[!is.na(df$metastasized)] <- "Yes"
#df$breast[!is.na(df$breast)] <- "Yes"
#df$prostate[!is.na(df$prostate)] <- "Yes"
#df$lung_bronchus[!is.na(df$lung_bronchus)] <- "Yes"
#df$colon_retal[!is.na(df$colon_retal)] <- "Yes"
#df$melanoma[!is.na(df$melanoma)] <- "Yes"
#df$bladder[!is.na(df$bladder)] <- "Yes"
#df$kidney[!is.na(df$kidney)] <- "Yes"
#df$endometrial[!is.na(df$endometrial)] <- "Yes"
#df$leukemia[!is.na(df$leukemia)] <- "Yes"
#df$pancreatic[!is.na(df$pancreatic)] <- "Yes"
#df$thyroid[!is.na(df$thyroid)] <- "Yes"
#df$liver_bd[!is.na(df$liver_bd)] <- "Yes"

# Get data into factor format
df$gender_female <- factor(df$gender_female)
df$age_ranges <- factor(df$age_ranges)
df$race_white <- factor(df$race_white)
df$mech_vent <- factor(df$mech_vent)
df$rrt <- factor(df$rrt)
df$pressor <- factor(df$pressor)
df$SOFA_ranges <- factor(df$SOFA_ranges, levels = c('0 - 3', '4 - 6','7 - 10', '11 and above' ))
df$cci_ranges <- factor(df$cci_ranges, levels = c('0 - 3', '4 - 6','7 - 10', '11 and above'))
df$source <- factor(df$source)
df$has_cancer <- factor(df$has_cancer)


# Factorize and label variables
label(df$age_ranges) <- "Age by group"
units(df$age_ranges) <- "years"

label(df$anchor_age) <- "Age overall"
units(df$anchor_age) <- "years"

label(df$gender_female) <- "Sex"
label(df$SOFA) <- "SOFA overall"
label(df$SOFA_ranges) <- "SOFA"

label(df$los) <- "Length of stay"
units(df$los) <- "days"

label(df$race_white) <- "Race"
label(df$charlson_comorbidity_index) <- "Charlson index overall"
label(df$cci_ranges) <- "Charlson index"

label(df$mech_vent) <- "Mechanic Ventilation"
label(df$rrt) <- "Renal Replacement Therapy"
label(df$pressor) <- "Vasopressor(s)"

label(df$mortality) <- "In-hospital Mortality"

label(df$has_cancer) <- "Active Cancer"

#label(df$other) <- "Other"
#label(df$metastasized) <- "Metastasized"
#label(df$breast) <- "Breast"
#label(df$lung_bronchus) <- "Lung (including bronchus)"
#label(df$colon_retal) <- "Colon and Rectal (combined)"
#label(df$melanoma) <- "Melanoma"
#label(df$bladder) <- "Bladder"
#label(df$kidney) <- "Kidney"
#label(df$endometrial) <- "Endometrial"
#label(df$leukemia) <- "Leukemia"
#label(df$pancreatic) <- "Pancreatic"
#label(df$thyroid) <- "Thyroid"
#label(df$liver_bd) <- "Liver and intrahepatic BD"

label(df$race_white) <- "Race"


render.categorical <- function(x, ...) {
  c("", sapply(stats.apply.rounding(stats.default(x)), function(y) with(y,
  sprintf("%s (%s%%)", prettyNum(FREQ, big.mark=","), PCT))))
}

render.strat <- function (label, n, ...) {
  sprintf("<span class='stratlabel'>%s<br><span class='stratn'>(N=%s)</span></span>", 
          label, prettyNum(n, big.mark=","))
}

# Create Table1 Object
tbl1 <- table1(~ mortality + mech_vent + rrt + pressor +
               age_ranges + anchor_age + gender_female + race_white + 
               SOFA_ranges + SOFA + cci_ranges + charlson_comorbidity_index + 
               los + has_cancer
               #other + metastasized + breast + prostate + lung_bronchus +
               #colon_retal + melanoma + bladder + kidney + nhl + endometrial +
               #leukemia + pancreatic + thyroid + liver_bd +
               | source,
               data=df,
               render.missing=NULL,
               topclass="Rtable1-grid Rtable1-shade Rtable1-times",
               render.categorical=render.categorical,
               render.strat=render.strat
              )


# Convert to flextable
t1flex(tbl1) %>% save_as_docx(path="results/table1/MIMIC_and_eICU.docx")