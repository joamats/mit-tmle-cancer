#source("src/2_cohorts/4_load_data.R")
source("src/2_cohorts/utils.R")

# run TMLE 
run_tmle <- function(data, treatment, confounders, outcome, SL_libraries,
                     cohort, group, sev_min, sev_max, results_df) {

    W <- data[, confounders]
    A <- data[, treatment]
    Y <- data[, outcome]
    
    result <- tmle(
                Y = Y,
                A = A,
                W = W,
                family = "binomial", 
                gbound = c(0.05, 0.95),
                g.SL.library = SL_libraries$SL_library,
                Q.SL.library = SL_libraries$SL_library
                )

    log <- summary(result)   

    results_df[nrow(results_df) + 1,] <- c( outcome,
                                            treatment,
                                            cohort,
                                            group,
                                            sev_min,
                                            sev_max,
                                            log$estimates$ATE$psi,
                                            log$estimates$ATE$CI[1],
                                            log$estimates$ATE$CI[2],
                                            log$estimates$ATE$pvalue,
                                            nrow(data),
                                            paste(SL_libraries$SL_library, collapse = " "),
                                            paste(result$Qinit$coef, collapse = " "),
                                            paste(result$g$coef, collapse = " ")
                                            ) 
    return (results_df)
}

# Main
cohorts <- c("mimic") # choose "MIMIC", "eICU", or "MIMIC_eICU" for both
outcomes <- c('mortality_1y') # "odd_hour","insulin_yes", "blood_yes", "comb_noso", "mortality_in", 'mortality_1y'
prob_mort_ranges <- read.csv("config/prob_mort_ranges.csv")
treatments <- read.delim("config/treatments.txt")
#SL_libraries <- read.delim("config/SL_libraries_SL.txt") # or use only base libraries, see below
SL_libraries <- read.delim("config/SL_libraries_base.txt") # or read.delim("config/SL_libraries_SL.txt")


for (c in cohorts) {
    print(paste0("Cohort: ", c))

    # Read Data for this database and cohort
    data <- read.csv(paste0("data/cohorts/merged_", c, "_all.csv"))

    # Factorize variables

    confounders <- read.delim(paste0("config/confounders.txt"))

    for (outcome in outcomes) {
        print(paste0("Outcome: ", outcome))

        # Dataframe to hold results
        results_df <- data.frame(matrix(ncol=14, nrow=0))
        colnames(results_df) <- c(
                                "outcome",
                                "treatment",
                                "cohort",
                                "group",
                                "prob_mort_start",
                                "prob_mort_end",
                                "psi",
                                "i_ci",
                                "s_ci",
                                "pvalue",
                                "n",
                                "SL_libraries",
                                "Q_weights",
                                "g_weights")

        if (outcome == "mortality_in" | outcome == "mortality_1y" ) {
            groups <- c("group_solid", "group_hematological", "group_metastasized") 
        } else {
            groups <- c("has_cancer") 
        }

        for (j in 1:nrow(treatments)) {
            # Treatment
            treatment <- treatments$treatment[j]
            print(paste0("Treatment: ", treatment))

            # Get formula with confounders and treatment
            model_confounders <- read_confounders(j, treatments, confounders) 

            for (g in groups) {

                print(paste0("Group: ", g))

                if (g == "group_solid") {
                    subset_data <- subset(data, group_solid == 1)

                } else if (g == "group_hematological") {        
                    subset_data <- subset(data, group_hematological == 1)
                    
                } else if (g == "group_metastasized") {        
                    subset_data <- subset(data, group_metastasized == 1)
                    
                } else {
                    subset_data <- data
                }

                for (i in 1:nrow(prob_mort_ranges)) {
                    
                    sev_min <- prob_mort_ranges$min[i]
                    sev_max <- prob_mort_ranges$max[i]

                    print(paste0("Stratification by prob_mort: ", sev_min, " - ", sev_max))

                    # Stratify by prob_mort
                    subsubset_data <- subset(subset_data, prob_mort >= sev_min & prob_mort < sev_max)
                    
                    # Run TMLE
                    results_df <- run_tmle(subsubset_data, treatment, model_confounders, outcome, 
                                           SL_libraries, c, g, sev_min, sev_max, results_df)

                    # Save Results
                    write.csv(results_df, paste0("results/tmle/SAs/", c, "/", outcome, ".csv"))

                }
            }           
        }
    }
}
