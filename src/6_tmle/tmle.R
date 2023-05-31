library(tmle)
library(pROC)
library(data.table)

### Constants ###
setting <- "tmle_results"

### Get the data ###
# now read treatment from txt
treatments <- read.delim("config/treatments.txt")$treatment

# read features from list in txt
confounders <- read.delim("config/confounders_test.txt")$confounder

# read the cofounders from list in txt
###### TODO: change txt
outcomes <- read.delim("config/outcomes_test.txt")$outcome

# Get the cohorts
cohorts <- read.delim("config/cohorts.txt")$cohorts

# Get cancer types:
cancer_types <- read.delim("config/cancer_types.txt")$cancer_type

# Define the SL library
SL_library <- read.delim("config/SL_libraries_base.txt")


# run TMLE 
run_tmle <- function(data, treatment, confounders, outcome, SL_libraries,
                     cohort, sev_min, sev_max, results_df) {

    W <- data[, confounders]
    A <- data[, treatment]
    Y <- data[, outcome]
    
    result <- tmle(
                Y = Y,
                A = A,
                W = W,
                #Delta = my_delta,
                family = "binomial", 
                gbound = c(0.05, 0.95),
                g.SL.library = SL_libraries$SL_library,
                Q.SL.library = SL_libraries$SL_library
                )

    log <- summary(result)

    results_df[nrow(results_df) + 1,] <- c( outcome,
                                            treatment,
                                            cohort,
                                            #race,
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


calculate_tmle_per_cohort <- function(data, groups, treatments, outcomes, confounders, cohort, results_df, SL_libraries) {

    for (outcome in outcomes) {
        print('***************')
        cat(paste("Outcomes:", outcome), "\n")
        # Get the treatments:
        for (treatment in treatments) {
            cat(paste("Doing the prediction for treatment:", treatment), "\n")
        
            for (group in groups) {
                cat(paste("Group:", group), "\n")
                
                data_subset <- subset(data, data[[group]] == 1)
                
                # append treatments that are not the current one to confounders
                # select X, y
                conf <- c()
                for (confounder in confounders) {
                    if (confounder != treatment) {
                        # Append treatment to confounders
                        conf <- c(conf, confounder)
                    }
                }
                
                results_df = run_tmle(data_subset, treatment, conf, outcome, SL_libraries,
                     cohort, sev_min=0, sev_max=1, results_df)
            }
        }
    }
    return(results_df)
}

check_columns_in_df <- function(df, columns) {
  cols_not_in_df <- setdiff(columns, colnames(df))
  
  if (length(cols_not_in_df) > 0) {
    cat("These cofounders are not in the df:", cols_not_in_df, "\n")
    return(FALSE)
  } else {
    return(TRUE)
  }
}

# create data.frames to store results
results_df <- data.frame(matrix(ncol=13, nrow=0))
colnames(results_df) <- c(
                        "outcome",
                        "treatment",
                        "cohort",
                        #"race",
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
                    
group <- ""
for (cohort in cohorts) {
    if (cohort == "cancer_vs_nocancer") {
        # Get all data
        df <- read.csv("data/cohorts/merged_all.csv")
        group <- "has_cancer"
        cohort <- "cancer"

        results_df <- calculate_tmle_per_cohort(df, group, treatments, outcomes, confounders, paste0(cohort, "_vs_others"), results_df, SL_library)
    } 
    else if (cohort == "cancer_type") {
        for (cancer_type in cancer_types) {
            group <- cancer_type
            cat(paste("Getting data for cancer type:", cancer_type), "\n")
            df <- read.csv("data/cohorts/merged_cancer.csv")
            cohort <- cancer_type

            results_df <- calculate_tmle_per_cohort(df, group, treatments, outcomes, confounders, paste0(cohort, "_vs_others"), results_df, SL_library)
        }
    } else {
        cat(paste("Error:", cohort, "should be cancer_vs_nocancer or cancer_type or both of them"), "\n")
        next
    }
}

# Save results as we go
dir.create("results/tmle", showWarnings = FALSE, recursive = TRUE)
write.csv(results_df, file.path("results/tmle", paste0(setting, ".csv")), row.names = FALSE)

