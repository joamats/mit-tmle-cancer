source("src/6_tmle/utils.R")    

# run TMLE 
run_tmle <- function(data, treatment, confounders, outcome,
                     cohort, cancer_type, sens, results_df) {

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
                                            cancer_type,
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
cancer_types <- read.delim("config/cancer_types.txt")
treatments <- read.delim("config/treatments.txt")
confounders <- read.delim("config/tmle2_vars.txt")
outcome <- read.delim("config/tmle2_out.txt")$outcome

# Dataframe to hold results
results_df <- data.frame(matrix(ncol=9, nrow=0))
colnames(results_df) <- c(
                          "treatment",
                          "cohort",
                          "cancer_type",
                          "sens",
                          "psi",
                          "i_ci",
                          "s_ci",
                          "pvalue",
                          "n")

# Read Data for this database and cohort
data <- read.csv("data/cohorts/merged_cancer.csv")

for (j in 1:nrow(treatments)) {
    # Treatment
    treatment <- treatments$treatment[j]
    print(paste0("Treatment: ", treatment))

    # Get formula with confounders and treatment
    model_confounders <- read_confounders(j, treatments, confounders) 

    for (ca in 1:nrow(cancer_types)) {

        cancer_type <- cancer_types$cancer_type[ca]
        
        print(paste0("Cancer Type: ", cancer_type))

        # Stratify by Cancer Type
        subset_data <- subset(data, data[[cancer_type]] == 1)

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
                                    c, cancer_type, sens, results_df)

            # Save Results
            write.csv(results_df, "results/tmle/SAs/2B_SA.csv")
        }

    }           
}
