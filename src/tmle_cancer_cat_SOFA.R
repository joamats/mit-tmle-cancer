library(tmle)

read_confounders <- function(j, treatments, confounders) {

    other_t <- treatments$treatment[-j]

    final_confounders <- other_t

    for (i in 1:nrow(confounders)) {
        final_confounders <- append(final_confounders, confounders$confounder[i])
    }

    return(final_confounders)
}

# run TMLE 
run_tmle <- function(data, treatment, confounders, database, cohort, cancer_cat, sofa_min, sofa_max, results_df) {

    W <- data[, confounders]
    A <- data[, treatment]
    Y <- data$mortality_in

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
                                            database,
                                            cohort,
                                            cancer_cat,
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
#databases <- c("MIMIC", "eICU")
databases <- c("merged")
cohorts <- c("cancer")

#cancer_cats <- c("cat_solid", "cat_hematological", "cat_metastasized")
cancer_grps <- c("group_liver_bd_pancreatic", "group_prostate_breast", "group_lung_bronchus")

sofa_ranges <- read.csv("config/SOFA_ranges.csv")

treatments <- read.delim("config/treatments.txt")
confounders <- read.delim("config/confounders_cancer_cat.txt")

# Dataframe to hold results
results_df <- data.frame(matrix(ncol=11, nrow=0))
colnames(results_df) <- c(
                          "treatment",
                          "database",
                          "cohort",
                          "cancer_cat",
                          "sofa_start",
                          "sofa_end",
                          "psi",
                          "i_ci",
                          "s_ci",
                          "pvalue",
                          "n")

for (d in databases) {
    for (c in cohorts) {

        # Read Data for this database and cohort
        data <- read.csv(paste0("data/cohort_", d, "_", c, ".csv"))

        print(paste0("Study: ", d, " - ", c))

        for (j in 1:nrow(treatments)) {
            # Treatment
            treatment <- treatments$treatment[j]
            print(paste0("Treatment: ", treatment))

            # Get formula with confounders and treatment
            model_confounders <- read_confounders(j, treatments, confounders) 

            #for (cat in cancer_cats) {
            for (cat in cancer_grps) {

                print(paste0("Stratification by Cancer Category: ", cat))

                # Stratify by Cancer Category
                subset_data <- subset(data, data[cat] == 1)

                for (i in 1:nrow(sofa_ranges)) {
                
                    sofa_min <- sofa_ranges$min[i]
                    sofa_max <- sofa_ranges$max[i]

                    print(paste0("Stratification by SOFA: ", sofa_min, " - ", sofa_max))

                    # Stratify by SOFA
                    sub_subset_data <- subset(subset_data, SOFA <= sofa_max & SOFA >= sofa_min)
                
                    # Run TMLE
                    results_df <- run_tmle(sub_subset_data, treatment, model_confounders, d, c, cat, sofa_min, sofa_max, results_df)

                    # Save Results
                    #write.csv(results_df, "results/TMLE_cancer_cat_SOFA.csv")
                    write.csv(results_df, "results/TMLE_cancer_grp_SOFA.csv")
                }
            }           
        }
    }
}

