# SOFA level -> 0-3, 4-6, 7-10, >10
# database -> mimic, eicu
# cohort -> cancer, all
# treatment -> rrt, mech_vent, vassopressor


read_confounders <- function(t, treatments, confounders) {

    vars <- paste0(t, " ~ ")

    other_t <- treatments$treatment[-j]

    for (k in 1:length(other_t)) {

        vars <- paste0(vars, other_t[k], " + ")
    }

    for (i in 1:nrow(confounders)) {

        vars <- paste0(vars, confounders$confounder[i], " + ")
    }

    fla <- substr(vars, 1, nchar(vars)-3)
    return(as.formula(fla))
}

encode_data <- function (df, cohort, treatment) {



    #df <- within(df, mortality_in   <- relevel(factor(mortality_in), ref = 0))

    # move to load data
    df <- within(df, com_ckd_stages <- factor(com_ckd_stages, levels = c(0, 1, 2, 3, 4, 5)))
    df <- within(df, com_ckd_stages <- fct_collapse(com_ckd_stages, Absent=c("0", "1", "2"), Present=c("3", "4", "5")))


    ready_df <- df[, append(comps, 
    c("m_age","sex_female", "ethno_white", "mortality_in", "CCI", "los_icu", 
    "has_cancer", "cat_solid", "cat_hematological",	"cat_metastasized", "is_full_code_admission",
    "com_ckd_stages", "com_hypertension_present", "com_heart_failure_present", "com_asthma_present", "com_copd_present",
    "mech_vent", "rrt",	"vasopressor"))]

    write.csv(ready_df, 'data/d.csv')

    return (ready_df)

}

run_glm <- function(df, fla) {

    m <- glm(fla, data = df, family = "binomial"(link=logit))

    # summary(m)
    m_OR <- exp(cbind(OR = coef(m), confint(m), N = log(nobs(m)) ))

    return (m_OR)

}

databases <- c("MIMIC", "eICU")
cohorts <- c("all", "cancer")
sofa_ranges <- read.csv("config/SOFA_ranges.csv")
treatments <- read.delim("config/treatments.txt")
confounders <- read.delim("config/confounders.txt")


for (d in databases) {
    for (c in cohorts) {
        for (i in nrow(sofa_ranges)) {
            df <- read.csv(paste0("data/cohort_", d, "_", c, ".csv"))
            df <- df[df$SOFA <= sofa_ranges$min[i,] &  df$SOFA >= sofa_ranges$max[i,]]

            for (t in treatments) {


                
                fla <- read_confounders(t, treatments, confounders) 
                m_OR <- run_glm(df, fla)


            }

            df <- encode_data(df, c, t)
            write.csv(m_OR, paste0("results/glm/", d, "_", c, ".csv"))

        }
    }
}