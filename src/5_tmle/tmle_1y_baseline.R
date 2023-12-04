#source("src/2_cohorts/4_load_data.R")
source("src/2_cohorts/utils.R")

# Set seed
set.seed(19840402)

# Initialize parallel processing
plan(multicore, workers = 8, .cleanup = TRUE)
message("Number of parallel workers: ", nbrOfWorkers())

# run TMLE 
run_tmle %<-% function(data, treatment, confounders, outcome, SL_libraries,
                     cohort, group, has_cancer, sev_min, sev_max, results_df) {
    
    W <- data[, confounders]
    data$none <- 1
    A <- data[, treatment]
    Y <- data[, outcome]

    result <- tmle(
                Y = Y,
                A = A,
                # A = NULL,
                W = W,
                family = "binomial", 
                gbound = c(0.05, 0.95),
                g.SL.library = SL_libraries$SL_library,
                Q.SL.library = SL_libraries$SL_library,
                V=5
                )

    log <- summary(result)   

    print("has cancer status")
    print(has_cancer)

    results_df[nrow(results_df) + 1,] <- c( outcome,
                                            treatment,
                                            cohort,
                                            group,
                                            has_cancer,
                                            sev_min,
                                            sev_max,
                                            log$estimates$EY1$psi,
                                            log$estimates$EY1$CI[1],
                                            log$estimates$EY1$CI[2],
                                            log$estimates$EY1$pvalue,
                                            nrow(data),
                                            paste(SL_libraries$SL_library, collapse = " "),
                                            paste(result$Qinit$coef, collapse = " "),
                                            paste(result$g$coef, collapse = " ")
                                            ) 

    return(results_df)
}

# Main
outcome <- c('mortality_1y') # just 'mortality_1y'
treatment <- c("none")

# Confounders
confounders <- read.delim(paste0("config/confounders.txt"))
# Remove the following from the confounder list as not varying in MIMIC
confounders <- unlist(confounders)
confounders <- confounders[!(confounders %in% c("hospitalid", "numbedscategory", "teaching_hospital", "region"))]

# Get the cohorts
cohorts <- read.delim("config/cohorts.txt")$cohorts

# Cancer types
cancer_types <- read.delim("config/cancer_types.txt")$cancer_type
groups <- cancer_types
has_cancer <- c(0,1)

# simply use the overall range for this use case
prob_mort_ranges <- read.csv("config/prob_mort_ranges.csv")
prob_mort_ranges <- prob_mort_ranges[prob_mort_ranges$min == 0 & prob_mort_ranges$max == 1, ]

SL_libraries <- read.delim("config/SL_libraries_SL.txt") # or use only base libraries, see below
#SL_libraries <- read.delim("config/SL_libraries_base.txt") # or read.delim("config/SL_libraries_SL.txt")


# Read Data for this database and cohort
data <- read.csv("data/cohorts/merged_mimic_all.csv")

# Fixing wierd error -> checked dataframe -> row 1 problem, in csv outcome == 1
# Replace NULL values in the outcome column with 1
data$outcome <- replace(data$outcome, is.null(data$outcome), 1)

print(paste0("Outcome: ", outcome))

# Dataframe to hold results
results_df <- data.frame(matrix(ncol=15, nrow=0))
colnames(results_df) <- c(
                        "outcome",
                        "treatment",
                        "cohort",
                        "group",
                        "has_cancer",
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


for (c in cohorts) {
    print(paste0("Cohort: ", c))

    if (c == "cancer_type") {
        
        for (g in groups) {

            print(paste0("Group: ", g))

            if (g == "group_solid") {
                subset_data <- subset(data, group_solid == 1)

            } else if (g == "group_hematological") {        
                subset_data <- subset(data, group_hematological == 1)
                
            } else if (g == "group_metastasized") {        
                subset_data <- subset(data, group_metastasized == 1)
                
            } 

            sev_min <- prob_mort_ranges$min[1]
            sev_max <- prob_mort_ranges$max[1]
            
            print(paste0("Stratification by prob_mort: ", sev_min, " - ", sev_max))

            # Stratify by prob_mort
            subsubset_data <- subset(subset_data, prob_mort >= sev_min & prob_mort < sev_max)

            # Run TMLE
            results_df <- run_tmle(subsubset_data, treatment, confounders, outcome, 
                                    SL_libraries, c, g, has_cancer, sev_min, sev_max, results_df)
        } 
    
    } else {
        
        for (i in has_cancer) {
            
            g <- "all"

            print(paste0("has cancer: ", i))  
            subset_data <- subset(data, has_cancer == i)

            sev_min <- prob_mort_ranges$min[1]
            sev_max <- prob_mort_ranges$max[1]
            
            print(paste0("Stratification by prob_mort: ", sev_min, " - ", sev_max))

            # Stratify by prob_mort
            subsubset_data <- subset(subset_data, prob_mort >= sev_min & prob_mort < sev_max)

            # Run TMLE
            results_df <- run_tmle(subsubset_data, treatment, confounders, outcome, 
                                    SL_libraries, c, g, i, sev_min, sev_max, results_df)

        }

    }       
}



# Save Results
write.csv(results_df, paste0("results/tmle/SAs/tmle_results", outcome, ".csv"))
#write.csv(results_df, paste0("results/tmle/SAs/mimic_base_", outcome, ".csv"))
        
