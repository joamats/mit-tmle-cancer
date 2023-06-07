# Code for creating Table 1 in MIMIC data
library(tidyverse)
library(table1)
library(flextable)

df <- read_csv('data/cohorts/merged_all.csv', show_col_types = FALSE)

# Cohort of Source
df <- df %>% mutate(source = ifelse(source == "mimic", "MIMIC", "eICU"))

# Outcomes
df$mortality_in <- factor(df$mortality_in, levels=c(1,0), labels=c("Died", "Survived"))
df$has_cancer <- factor(df$has_cancer, levels=c(1,0), labels=c("Cancer", "Non-Cancer"))
df$odd_hour <- factor(df$odd_hour, levels=c(1,0), labels=c("Odd hour", "Even hour"))
df$comb_noso <- factor(df$comb_noso, levels=c(1,0), labels=c("Nosocomial Inf", "No Infection"))

# Define predicted mortality ranges
df$prob_mort_ranges <- df$prob_mort
df$prob_mort_ranges[df$prob_mort >= 0 & df$prob_mort <= 0.06] <- "0 - 6"
df$prob_mort_ranges[df$prob_mort >= 0.07 & df$prob_mort <= 0.11] <- "7 - 11"
df$prob_mort_ranges[df$prob_mort >= 0.12 & df$prob_mort <= 0.21] <- "12 - 21"
df$prob_mort_ranges[df$prob_mort >= 0.22] <- "21 and higher"

df$prob_mort_ranges <- factor(df$prob_mort_ranges, levels = c("0 - 6", "7 - 11", "12 - 21", "21 and higher"), 
                        labels = c('0 - 6', '7 - 11', '12 - 21', '21 and higher'))


# Cancer Categories
df <- df %>% mutate(group_solid = ifelse(group_solid == 1, "Present", "Not Present"))
df <- df %>% mutate(group_hematological = ifelse(group_hematological == 1, "Present", "Not Present"))
df <- df %>% mutate(group_metastasized = ifelse(group_metastasized == 1, "Present", "Not Present"))

# Cancer Types
df$cancer_type <- 0
df$cancer_type[df$group_solid == "Present"] <- 1
df$cancer_type[df$group_metastasized == "Present"] <- 2
df$cancer_type[df$group_hematological == "Present"] <- 3

df$cancer_type <- factor(df$cancer_type, levels = c(0, 1, 2, 3), 
                        labels = c('No cancer', 'Solid cancer', 'Metastasized cancer', 'Hematological cancer'))

label(df$group_solid) <- "Solid Cancer"
label(df$group_hematological) <- "Hematological Cancer"
label(df$group_metastasized) <- "Metastasized Cancer"

# Rendering functions
render.categorical <- function(x, ...) {
  c("", sapply(stats.apply.rounding(stats.default(x)), function(y) with(y,
  sprintf("%s (%s%%)", prettyNum(FREQ, big.mark=","), PCT))))
}

render.strat <- function (label, n, ...) {
  sprintf("<span class='stratlabel'>%s<br><span class='stratn'>(N=%s)</span></span>", 
          label, prettyNum(n, big.mark=","))
}

# Create Table1 Object
tbl1 <- table1(~ mortality_in + has_cancer + comb_noso + odd_hour +prob_mort_ranges  
              | cancer_type,
               data=df,
               render.missing=NULL,
               topclass="Rtable1-grid Rtable1-shade Rtable1-times",
               render.categorical=render.categorical,
               render.strat=render.strat
              )

# Convert to flextable
t1flex(tbl1) %>% save_as_docx(path="results/table1/2_outcome_all.docx")

# Create Table1 Object
tbl1 <- table1(~ mortality_in + has_cancer + comb_noso + odd_hour +prob_mort_ranges
               | cancer_type,
               data=subset(df, source == "eICU"),
               render.missing=NULL,
               topclass="Rtable1-grid Rtable1-shade Rtable1-times",
               render.categorical=render.categorical,
               render.strat=render.strat
              )

# Convert to flextable
t1flex(tbl1) %>% save_as_docx(path="results/table1/2_outcome_eICU.docx")

# Create Table1 Object
tbl1 <- table1(~ mortality_in + has_cancer + comb_noso + odd_hour +prob_mort_ranges
               | cancer_type,
               data=subset(df, source == "MIMIC"),
               render.missing=NULL,
               topclass="Rtable1-grid Rtable1-shade Rtable1-times",
               render.categorical=render.categorical,
               render.strat=render.strat
              )

# Convert to flextable
t1flex(tbl1) %>% save_as_docx(path="results/table1/2_outcome_MIMIC.docx")