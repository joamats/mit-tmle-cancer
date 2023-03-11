source("src/6_tmle/utils.R")

# run TMLE 
run_tmle <- function(data, treatment, confounders, outcome,
                     cohort, sofa_min, sofa_max, sens, results_df) {

    W <- data[, confounders]
    A <- data[, treatment]
    Y <- data[, outcome]

    result <- tmle(
                Y = Y,
                A = A,
                W = W,
                family = "binomial", 
                gbound = c(0.05, 0.95),
                g.SL.library = c("SL.glm"),
                Q.SL.library = c("SL.glm"),
                )

    log <- summary(result)     

    results_df[nrow(results_df) + 1,] <- c(
                                            treatment,
                                            cohort,
                                            sofa_min,
                                            sofa_max,
                                            sens,
                                            log$estimates$ATE$psi,
                                            log$estimates$ATE$CI[1],
                                            log$estimates$ATE$CI[2],
                                            log$estimates$ATE$pvalue,
                                            nrow(data)
                                            ) 
    return (results_df)
}

# Main
cohorts <- c("all", "cancer")
sofa_ranges <- read.csv("config/SOFA_ranges.csv")
treatments <- read.delim("config/treatments.txt")
confounders <- read.delim("config/tmle2_vars.txt")
outcome <- read.delim("config/tmle2_out.txt")$outcome

# Dataframe to hold results
results_df <- data.frame(matrix(ncol=10, nrow=0))
colnames(results_df) <- c(
                          "treatment",
                          "cohort",
                          "sofa_start",
                          "sofa_end",
                          "sens",
                          "psi",
                          "i_ci",
                          "s_ci",
                          "pvalue",
                          "n")


for (c in cohorts) {
    print(paste0("Cohort: ", c))

    # Read Data for this database and cohort
    data <- read.csv(paste0("data/cohorts/merged_", c, ".csv"))

    # Non-Cancer Patients
    if (c == "all") {
        data <- subset(data, has_cancer == 0)
    }

    for (j in 1:nrow(treatments)) {
        # Treatment
        treatment <- treatments$treatment[j]
        print(paste0("Treatment: ", treatment))

        # Get formula with confounders and treatment
        model_confounders <- read_confounders(j, treatments, confounders) 

        for (i in 1:nrow(sofa_ranges)) {
            
            sofa_min <- sofa_ranges$min[i]
            sofa_max <- sofa_ranges$max[i]

            print(paste0("Stratification by SOFA: ", sofa_min, " - ", sofa_max))

            # Stratify by SOFA
            subset_data <- subset(data, SOFA <= sofa_max & SOFA >= sofa_min)

                for (s in 1:nrow(treatments)) {

                    sens <- treatments$treatment[s]

                    print(paste0("Sensitivity Analysis for: ", sens))

                    # Remove patients with key comorbidities
                    if (sens == "mech_vent") {
                        sub_subset_data <- subset(subset_data,
                                                  com_asthma_present != 1 &
                                                  com_copd_present != 1)
                    } else if(sens == "rrt") {
                        sub_subset_data <- subset(subset_data,
                                                  com_ckd_stages != 1)
 
                    } else if(sens == "vasopressor") {
                        sub_subset_data <- subset(subset_data,
                                                  com_heart_failure_present != 1 &
                                                  com_hypertension_present != 1)                        
                    }

                    # Run TMLE
                    results_df <- run_tmle(sub_subset_data, treatment, model_confounders, outcome,
                                           c, sofa_min, sofa_max, sens, results_df)

                    # Save Results
                    write.csv(results_df, "results/tmle/SAs/2A_SA.csv")
                }
        }           
    }
}

