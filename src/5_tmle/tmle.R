library(tmle)
library(pROC)
library(data.table)

### Get the data ###
# now read treatment from txt
treatments <- read.delim("config/treatments.txt")$treatment

# read features from list in txt
confounders <- read.delim("config/confounders.txt")$confounder

# read the cofounders from list in txt
outcomes <- read.delim("config/outcomes.txt")$outcome

# Get the cohorts
cohorts <- read.delim("config/cohorts.txt")$cohorts

# Get cancer types:
cancer_types <- read.delim("config/cancer_types.txt")$cancer_type

# Define the SL library
SL_library <- read.delim("config/SL_libraries_base.txt")

# Define predicted mortality ranges
prob_mort_ranges <- read.csv("config/prob_mort_ranges.csv")

# First iteration
FIRST <- TRUE

# run TMLE 
run_tmle <- function(data, treatment, confounders, outcome, SL_libraries,
                     cohort, sev_min, sev_max, results_df, group_true) {
               
    W <- data[, confounders]
    A <- data[, treatment]
    Y <- data[, outcome]

    if (length(unique(Y)) > 2) {
        
        # Normalize continuous outcomes to be between 0 and 1
        min.Y <- min(Y)
        max.Y <- max(Y)
        Y <- (Y-min.Y)/(max.Y-min.Y)
        # Transform continuous outcomes to be between 0 and 1
        Y <- (data[, outcome]-min.Y)/(max.Y-min.Y)

        result <- tmle(
            Y = Y,
            A = A,
            W = W,
            #Delta = my_delta,
            family = "gaussian", 
            gbound = c(0.05, 0.95),
            g.SL.library = SL_libraries$SL_library,
            Q.SL.library = SL_libraries$SL_library
            )

    log <- summary(result) 
    
    RR <- 0

    # Transform back the ATE estimate
    log$estimates$ATE$psi <- (max.Y-min.Y)*log$estimates$ATE$psi

    # Transform back the CI estimate
    log$estimates$ATE$CI[1] <- (max.Y-min.Y)*log$estimates$ATE$CI[1]
    log$estimates$ATE$CI[2] <- (max.Y-min.Y)*log$estimates$ATE$CI[2]

    }

    else {
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
    
    RR <- log$estimates$RR$psi # output RR for calculating the e-value 
    }

    print('***************')
   #print(log)

    results_df[nrow(results_df) + 1,] <- c( outcome,
                                            treatment,
                                            cohort,
                                            group_true,
                                            sev_min,
                                            sev_max,
                                            log$estimates$ATE$psi,
                                            log$estimates$ATE$CI[1],
                                            log$estimates$ATE$CI[2],
                                            log$estimates$ATE$pvalue,
                                            nrow(data),
                                            paste(SL_libraries$SL_library, collapse = " "),
                                            paste(result$Qinit$coef, collapse = " "),
                                            paste(result$g$coef, collapse = " "),
                                            RR                                    
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

                # append treatments that are not the current one to confounders
                conf <- c()
                for (confounder in confounders) {
                    if (confounder != treatment) {
                        # Append treatment to confounders
                        conf <- c(conf, confounder)
                    }
                }

                # Get the data for the current group
                # When group is true: group = 1
                group_true = 1
                data_subset <- subset(data, data[[group]] == 1)

                if (group %in% c("group_solid", "group_hematologic", "group_metastasized")) {
                        
                        sev_min <- 0
                        sev_max <- 1

                        print(paste0("Stratification by prob_mort: ", sev_min, " - ", sev_max))

                        # Stratify by prob_mort
                        data_subsub <- subset(data_subset, prob_mort >= sev_min & prob_mort < sev_max)

                        # Run TMLE
                        results_df = run_tmle(data_subsub, treatment, confounders, outcome, SL_libraries,
                                                cohort, sev_min, sev_max, results_df, group_true)

                    } else {

                        for (i in 1:nrow(prob_mort_ranges)) {

                        sev_min <- prob_mort_ranges$min[i]
                        sev_max <- prob_mort_ranges$max[i]
                    
                        print(paste0("Stratification by prob_mort: ", sev_min, " - ", sev_max))

                        # Stratify by prob_mort
                        data_subsub <- subset(data_subset, prob_mort >= sev_min & prob_mort < sev_max)
                        
                        # Run TMLE                        
                        results_df = run_tmle(data_subsub, treatment, confounders, outcome, SL_libraries,
                                            cohort, sev_min, sev_max, results_df, group_true)

                    }
                }

                # When group is false: group = 0
                if (FIRST == TRUE) {
                    
                    FIRST <- FALSE
                    
                    group_true = 0
                    data_subset <- subset(data, data[["has_cancer"]] == 0)
                    
                    if (group %in% c("group_solid", "group_hematologic", "group_metastasized")) {
                            
                            sev_min <- 0
                            sev_max <- 1

                            print(paste0("Stratification by prob_mort: ", sev_min, " - ", sev_max))

                            # Stratify by prob_mort
                            data_subsub <- subset(data_subset, prob_mort >= sev_min & prob_mort < sev_max)

                            # Run TMLE
                            results_df = run_tmle(data_subsub, treatment, confounders, outcome, SL_libraries,
                                                    cohort, sev_min, sev_max, results_df, group_true)
                    
                    } else {

                        for (i in 1:nrow(prob_mort_ranges)) {

                            sev_min <- prob_mort_ranges$min[i]
                            sev_max <- prob_mort_ranges$max[i]
                        
                            print(paste0("Stratification by prob_mort: ", sev_min, " - ", sev_max))

                            # Stratify by prob_mort
                            data_subsub <- subset(data_subset, prob_mort >= sev_min & prob_mort < sev_max)
                            
                            # Run TMLE                        
                            results_df = run_tmle(data_subsub, treatment, confounders, outcome, SL_libraries,
                                                cohort, sev_min, sev_max, results_df, group_true)

                            print(paste0("Stratification by prob_mort: ", sev_min, " - ", sev_max))

                            # Stratify by prob_mort
                            data_subsub <- subset(data_subset, prob_mort >= sev_min & prob_mort < sev_max)
                        
                            # Run TMLE
                            results_df = run_tmle(data_subsub, treatment, confounders, outcome, SL_libraries,
                                                    cohort, sev_min, sev_max, results_df, group_true)
                        }
                    }
                }   
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

databases = c("all", "eicu", "mimic") 

for (db in databases){
  print('***************')
  print(db)
  print('***************')
  
    # create data.frames to store results
    results_df <- data.frame(matrix(ncol=15, nrow=0))
    colnames(results_df) <- c(
                            "outcome",
                            "treatment",
                            "cohort",
                            "has_cancer",
                            "prob_mort_start",
                            "prob_mort_end",
                            "ATE",
                            "i_ci",
                            "s_ci",
                            "pvalue",
                            "n",
                            "SL_libraries",
                            "Q_weights",
                            "g_weights",
                            "RR"
                           )
                        
    group <- ""
    for (cohort in cohorts) {
        
        # Remove hospital confounders for analysis with MIMIC only, as they do not vary
        confounders_aux <- confounders[!confounders %in% c("hospitalid", "numbedscategory", "teaching_hospital", "region")]

        if (cohort == "cancer_vs_nocancer") {

            df <- read.csv("data/cohorts/merged_all.csv")

            # Get all data
            if (db == "eicu") {
               df <- subset(df, source == db)

            } else if (db == "mimic") {
               df <- subset(df, source == db)

            } else {
                cat(paste("Error:", db, "should be all, eicu or mimic"), "\n")
                break
            }

            group <- "has_cancer"
            cohort <- "cancer"
            
            if (db == "mimic") {
            # pass updated confounders without hospital confounders to tmle function
            results_df <- calculate_tmle_per_cohort(df, group, treatments, outcomes, confounders_aux, paste0(cohort, "_vs_others"), results_df, SL_library)
            
            } else {
            # if database is all or eicu -> keep hospital confounders
            results_df <- calculate_tmle_per_cohort(df, group, treatments, outcomes, confounders, paste0(cohort, "_vs_others"), results_df, SL_library)
            } 
        }
        else if (cohort == "cancer_type") {
            
            # Remove hospital confounders for analysis with MIMIC only, as they do not vary
            confounders_aux <- confounders[!confounders %in% c("hospitalid", "numbedscategory", "teaching_hospital", "region")]

            for (cancer_type in cancer_types) {
                cat(paste("Getting data for cancer type:", cancer_type), "\n")
    
                # Get all data
                if (db == "all"){
                    df <- read.csv("data/cohorts/merged_all.csv")
                } else if (db == "eicu") {
                df <- read.csv("data/cohorts/merged_eicu_all.csv")
                } else if (db == "mimic") {
                df <- read.csv("data/cohorts/merged_mimic_all.csv")
                } else {
                    cat(paste("Error:", db, "should be all, eicu or mimic"), "\n")
                    break
                }

                group <- cancer_type
                cohort <- cancer_type
                
                if (db == "mimic") {
                # pass updated confounders without hospital confounders to tmle function
                results_df <- calculate_tmle_per_cohort(df, group, treatments, outcomes, confounders_aux, paste0(cohort, "_vs_nocancer"), results_df, SL_library)
            
                } else {
                # if database is all or eicu -> keep hospital confounders
                results_df <- calculate_tmle_per_cohort(df, group, treatments, outcomes, confounders, paste0(cohort, "_vs_others"), results_df, SL_library)
                }
            }     
        } else {
            cat(paste("Error:", cohort, "should be cancer_vs_nocancer or cancer_type or both of them"), "\n")
            next
        }
    }

    # Save results as we go
    dir.create("results/tmle", showWarnings = FALSE, recursive = TRUE)
    results <- paste0('tmle_results_', db)
    write.csv(results_df, file.path("results/tmle", paste0(results, ".csv")), row.names = FALSE)

}
