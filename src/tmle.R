library(tmle)

source("src/load_data.R")

# Get data within SOFA ranges
data_between_sofa <- function(data, lower_bound, upper_bound) {

    res <- data[data$SOFA >= lower_bound & data$SOFA <= upper_bound, ]
    
    return(na.omit(res))
}

# TMLE by SOFA
tmle_sofa <- function(data_sofa, treatment) {

    confounders <- c("source","anchor_age","gender_female","race_white",
                     "SOFA","charlson_comorbidity_index")

    if(treatment == "mech_vent") {

        W <- data_sofa[, append(confounders, c("rrt", "pressor"))]
        A <- data_sofa$mech_vent

    } else if(treatment == "rrt") {

        W <- data_sofa[, append(confounders, c("mech_vent", "pressor"))]
        A <- data_sofa$rrt

    } else if(treatment == "pressor") {

        W <- data_sofa[, append(confounders, c("rrt", "mech_vent"))]
                           
        A <- data_sofa$pressor
    }

    Y <- data_sofa$mortality

    result <- tmle(Y = Y,
                   A = A,
                   W = W,
                   family = "binomial", 
                   gbound = c(0.05, 0.95)
                  )

    log <- summary(result)
    print(log)

    return(log)
}


# run TMLE by SOFA only (main analysis)
tmle_stratified_sofas <- function(data, treatment, has_cancer, df) {

    sofa_ranges <- list(list(0, 3), list(4,6), list(7, 10), list(11, 100))

    for (sofa in sofa_ranges) {
        
        start <- sofa[[1]]
        end <- sofa[[2]]

        print(paste0(treatment, " - ", has_cancer, ": ", start, " - ",end))

        if (has_cancer == "non-cancer") {
            data <- data[data$has_cancer == 0, ]
            
        } else if (has_cancer == "cancer") {
            data <- data[data$has_cancer == 1, ]
            
        } # else, nothing because race = "all" needs no further filtering

        data_sofa <- data_between_sofa(data, start, end)
        log <- tmle_sofa(data_sofa, treatment)

        df[nrow(df) + 1,] <- c(treatment,
                               has_cancer,
                               start,
                               end,
                               log$estimates$ATE$psi,
                               log$estimates$ATE$CI[1],
                               log$estimates$ATE$CI[2],
                               log$estimates$ATE$pvalue,
                               nrow(data_sofa)
                              ) 
    }  

    return (df)
}


# Get merged datasets' data
data <- read_csv('data/table_all.csv', show_col_types = FALSE)

# List with possible invasive treatments
treatments <- list("mech_vent", "rrt", "pressor")
has_cancer_list <- list("all", "non-cancer", "cancer")

# Dataframe to hold results
df <- data.frame(matrix(ncol=9, nrow=0))
colnames(df) <- c("treatment", "has_cancer", "sofa_start", "sofa_end",
                    "psi", "i_ci","s_ci", "pvalue", "n")

# Go through all treatments
for (treatment in treatments) {
    for (has_cancer in has_cancer_list){
        df <- tmle_stratified_sofas(data, treatment, has_cancer, df)
    }
}

write.csv(df, "results/TMLE.csv")