source("src/6_tmle/utils.R")

# run TMLE 
run_tmle <- function(data, treatment, confounders, outcome,
                     cohort, sofa_min, sofa_max, results_df) {


    W <- data[, confounders]
    A <- data[, treatment]
    Y <- data[, outcome]

    min.Y <- min(Y)
    max.Y <- max(Y)

    Y_transf <- (Y-min.Y)/(max.Y-min.Y)

    result <- tmle(
                Y = Y_transf,
                A = A,
                W = W,
                family = "gaussian", 
                gbound = c(0.05, 0.95),
                g.SL.library = c("SL.glm"),
                Q.SL.library = c("SL.glm"),
                )

    log <- summary(result)     

    # Rescale back to original scale
    # Check with Andre -> here https://ehsanx.github.io/TMLEworkshop/pre-packaged-software.html
    # They don't sum min.Y back

    log$estimates$ATE$psi <- log$estimates$ATE$psi * (max.Y-min.Y) + min.Y
    log$estimates$ATE$CI <- log$estimates$ATE$CI * (max.Y-min.Y) + min.Y

    results_df[nrow(results_df) + 1,] <- c(
                                            treatment,
                                            cohort,
                                            sofa_min,
                                            sofa_max,
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
confounders <- read.delim("config/tmle3_vars.txt")
outcome <- read.delim("config/tmle3_out.txt")$outcome

# Dataframe to hold results
results_df <- data.frame(matrix(ncol=9, nrow=0))
colnames(results_df) <- c(
                          "treatment",
                          "cohort",
                          "sofa_start",
                          "sofa_end",
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

            # Run TMLE
            results_df <- run_tmle(subset_data, treatment, model_confounders, outcome,
                                   c, sofa_min, sofa_max, results_df)

            # Save Results
            write.csv(results_df, "results/tmle/3A.csv")

        }           
    }
}

