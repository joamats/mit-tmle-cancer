# Code for creating Table 1 in MIMIC data
library(tidyverse)
library(table1)
library(dplyr)
library(flextable)
library(magrittr)

df <- read_csv('data/cohorts/merged_cancer.csv', show_col_types = FALSE)

# Cohort of Source
df <- df %>% mutate(source = ifelse(source == "mimic_cancer", "MIMIC", "eICU"))

# Cancer Categories
df <- df %>% mutate(group_solid = ifelse(group_solid == 1, "Present", "Not Present"))
df <- df %>% mutate(group_hematological = ifelse(group_hematological == 1, "Present", "Not Present"))
df <- df %>% mutate(group_metastasized = ifelse(group_metastasized == 1, "Present", "Not Present"))

# Cancer Types
df <- df %>% mutate(loc_colon_rectal = ifelse(loc_colon_rectal == 1, "Present", "Not Present"))
df <- df %>% mutate(loc_liver_bd = ifelse(loc_liver_bd == 1, "Present", "Not Present"))
df <- df %>% mutate(loc_pancreatic = ifelse(loc_pancreatic == 1, "Present", "Not Present"))
df <- df %>% mutate(loc_lung_bronchus = ifelse(loc_lung_bronchus == 1, "Present", "Not Present"))
df <- df %>% mutate(loc_melanoma = ifelse(loc_melanoma == 1, "Present", "Not Present"))
df <- df %>% mutate(loc_breast = ifelse(loc_breast == 1, "Present", "Not Present"))
df <- df %>% mutate(loc_endometrial = ifelse(loc_endometrial == 1, "Present", "Not Present"))
df <- df %>% mutate(loc_prostate = ifelse(loc_prostate == 1, "Present", "Not Present"))
df <- df %>% mutate(loc_kidney = ifelse(loc_kidney == 1, "Present", "Not Present"))
df <- df %>% mutate(loc_bladder = ifelse(loc_bladder == 1, "Present", "Not Present"))
df <- df %>% mutate(loc_thyroid = ifelse(loc_thyroid == 1, "Present", "Not Present"))
df <- df %>% mutate(loc_nhl = ifelse(loc_nhl == 1, "Present", "Not Present"))
df <- df %>% mutate(loc_leukemia = ifelse(loc_leukemia == 1, "Present", "Not Present"))

df$cancer_type <- 0
df$cancer_type[df$group_solid == "Present"] <- 1
df$cancer_type[df$group_metastasized == "Present"] <- 2
df$cancer_type[df$group_hematological == "Present"] <- 3

df$cancer_type <- factor(df$cancer_type, levels = c(1, 2, 3), 
                        labels = c('Solid cancer', 'Metastasized cancer', 'Hematological cancer'))

label(df$group_solid) <- "Solid Cancer"
label(df$group_hematological) <- "Hematological Cancer"
label(df$group_metastasized) <- "Metastasized Cancer"

label(df$loc_breast) <- "Breast"
label(df$loc_prostate) <- "Prostate"
label(df$loc_lung_bronchus) <- "Lung (including bronchus)"
label(df$loc_colon_rectal) <- "Colon and Rectal (combined)"
label(df$loc_melanoma) <- "Melanoma"
label(df$loc_bladder) <- "Bladder"
label(df$loc_kidney) <- "Kidney"
label(df$loc_nhl) <- "NHL"
label(df$loc_endometrial) <- "Endometrial"
label(df$loc_leukemia) <- "Leukemia"
label(df$loc_pancreatic) <- "Pancreatic"
label(df$loc_thyroid) <- "Thyroid"
label(df$loc_liver_bd) <- "Liver and intrahepatic BD"

render.categorical <- function(x, ...) {
  c("", sapply(stats.apply.rounding(stats.default(x)), function(y) with(y,
  sprintf("%s (%s%%)", prettyNum(FREQ, big.mark=","), PCT))))
}

render.strat <- function (label, n, ...) {
  sprintf("<span class='stratlabel'>%s<br><span class='stratn'>(N=%s)</span></span>", 
          label, prettyNum(n, big.mark=","))
}

# Create Table1 Object
tbl1 <- table1(~ 
               group_solid + group_hematological + group_metastasized +
               loc_colon_rectal + loc_liver_bd + loc_pancreatic +
               loc_lung_bronchus + loc_melanoma + loc_breast +
               loc_endometrial + loc_prostate + loc_kidney +
               loc_bladder + loc_thyroid + loc_nhl + loc_leukemia,
               data=df,
               render.missing=NULL,
               topclass="Rtable1-grid Rtable1-shade Rtable1-times",
               render.categorical=render.categorical,
               render.strat=render.strat
              )


# Convert to flextable
t1flex(tbl1) %>% save_as_docx(path="results/table1/1B.docx")

# Create Table1 Object
tbl1 <- table1(~ 
               group_solid + group_hematological + group_metastasized +
               loc_colon_rectal + loc_liver_bd + loc_pancreatic +
               loc_lung_bronchus + loc_melanoma + loc_breast +
               loc_endometrial + loc_prostate + loc_kidney +
               loc_bladder + loc_thyroid + loc_nhl + loc_leukemia
               | source,
               data=df,
               render.missing=NULL,
               topclass="Rtable1-grid Rtable1-shade Rtable1-times",
               render.categorical=render.categorical,
               render.strat=render.strat
              )

# Convert to flextable
t1flex(tbl1) %>% save_as_docx(path="results/table1/1B_by_database.docx")
