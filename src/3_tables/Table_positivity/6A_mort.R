library(tidyverse)
library(table1)
library(flextable)

df <- read_csv('data/cohorts/merged_all.csv', show_col_types = FALSE)

df$mortality_in <- factor(df$mortality_in, levels=c(1,0), labels=c("Died", "Survived"))

df$mech_vent <- factor(df$mech_vent, levels=c(1,0), labels=c("Received", "Not received"))
df$vasopressor <- factor(df$vasopressor, levels=c(1,0), labels=c("Received", "Not received"))

# Create a factor variable for mech_vent depending on cancer status
df$imv_cancer <- df$mech_vent
df$imv <- df$mech_vent
df <- df %>% mutate(imv_cancer = ifelse(has_cancer==1, 1, NA))
df <- df %>% mutate(imv = ifelse(has_cancer==0, 1, NA))
df$imv_cancer <- factor(df$imv_cancer, levels=c(1,0), labels=c("Received cancer", "Not received"))
df$imv <- factor(df$imv, levels=c(1,0), labels=c("Received no cancer", "Not received"))

df$vp_cancer <- df$vasopressor
df$vp <- df$vasopressor
df <- df %>% mutate(vp_cancer = ifelse(has_cancer==1, 1, NA))
df <- df %>% mutate(vp = ifelse(has_cancer==0, 1, NA))
df$vp_cancer <- factor(df$vp_cancer, levels=c(1,0), labels=c("Received cancer", "Not received"))
df$vp <- factor(df$vp, levels=c(1,0), labels=c("Received no cancer", "Not received"))

# Get data into factor format
df$prob2 <- df$prob_mort
df$prob2<- cut(df$prob2, breaks = c(0, 0.1, 0.2, 1))
df$prob2 <- factor(df$prob2, labels = c('< 10', '10 - 19', '≥ 20'))

label(df$prob2) <- "Predicted mortality range"
label(df$imv) <- "Mechanical Ventilation"
label(df$imv_cancer) <- "Mechanical Ventilation cancer"
label(df$vp) <- "Vasopressor(s)"
label(df$vp_cancer) <- "Vasopressor(s) cancer"

label(df$mortality_in) <- "In-hospital Mortality"

render.categorical <- function(x, ...) {
  c("", sapply(stats.apply.rounding(stats.default(x)), function(y) with(y,
  sprintf("%s (%s%%)", prettyNum(FREQ, big.mark=","), PCT))))
}

render.strat <- function (label, n, ...) {
  sprintf("<span class='stratlabel'>%s<br><span class='stratn'>(N=%s)</span></span>", 
          label, prettyNum(n, big.mark=","))
}

# Both datasets
tbl_pos <- table1(~ imv + imv_cancer + vp + vp_cancer
                  | prob2 * mortality_in, 
                  data=df,
                  #render.missing=NULL, 
                  topclass="Rtable1-grid Rtable1-shade Rtable1-times",
                  render.categorical=render.categorical, 
                  render.strat=render.strat)

# Convert to flextable
t1flex(tbl_pos) %>% save_as_docx(path="results/positivity/6A_suppl.docx")