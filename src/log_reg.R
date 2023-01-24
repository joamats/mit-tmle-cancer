# treatment -> rrt, mech_vent, vassopressor
# cohort -> cancer, all
# SOFA level -> 0-3, 4-6, 7-10, >10

encode_data <- function (df, cohort, treatment) {

    df[,'m_age'] <- NA
    df$m_age <-df$anchor_age / 10

    #df <- within(df, mortality_in   <- relevel(factor(mortality_in), ref = 0))
    df <- within(df, com_ckd_stages <- factor(com_ckd_stages, levels = c(0, 1, 2, 3, 4, 5)))
    df <- within(df, com_ckd_stages <- fct_collapse(com_ckd_stages, Absent=c("0", "1", "2"), Present=c("3", "4", "5")))

   # if (treatment == "all") {

       # df <- within(df, cns_24     <- relevel(factor(cns_24),      ref = "Normal")

        comps <- c("SOFA")

   # } else if (treatment == "cancer") {

        #df <- within(df, cns_168    <- relevel(factor(cns_168),     ref = "Normal"))

    #    comps <- c("SOFA")
        #comps <- c("SOFA", "source")
    #}


    ready_df <- df[, append(comps, 
    c("m_age","sex_female", "ethno_white", "mortality_in", "CCI", "los_icu", 
    "has_cancer", "cat_solid", "cat_hematological",	"cat_metastasized", "is_full_code_admission",
    "com_ckd_stages", "com_hypertension_present", "com_heart_failure_present", "com_asthma_present", "com_copd_present",
    "mech_vent", "rrt",	"vasopressor"))]

    write.csv(ready_df, 'data/d.csv')

    return (ready_df)

}

run_glm <- function(df, treatment) {

    if (treatment == "mech_vent") {

        m <- glm(mech_vent ~ m_age + sex_female + ethno_white + CCI + com_ckd_stages + SOFA + mortality_in + # regular confounders
                            com_hypertension_present + com_heart_failure_present + com_asthma_present + com_copd_present + # regular confounders
                            vasopressor + rrt + # other two treatments
                            has_cancer + cat_solid + cat_hematological + cat_metastasized + is_full_code_admission,   # Cancer components
            data = df, family = "binomial"(link=logit))

    } else if (treatment == "rrt") {

        m <- glm(rrt ~ m_age + sex_female + ethno_white + CCI + com_ckd_stages + SOFA + mortality_in + # regular confounders
                            com_hypertension_present + com_heart_failure_present + com_asthma_present + com_copd_present + # regular confounders
                            mech_vent + vasopressor + # other two treatments
                            has_cancer + cat_solid + cat_hematological + cat_metastasized + is_full_code_admission,   # Cancer components
            data = df, family = "binomial"(link=logit))

    } else if (treatment == "vasopressor") {

        m <- glm(vasopressor ~ m_age + sex_female + ethno_white + CCI + com_ckd_stages + SOFA + mortality_in + # regular confounders
                            com_hypertension_present + com_heart_failure_present + com_asthma_present + com_copd_present + # regular confounders
                            mech_vent + rrt + # other two treatments
                            has_cancer + cat_solid + cat_hematological + cat_metastasized + is_full_code_admission,   # Cancer components
            data = df, family = "binomial"(link=logit))

    }

    # summary(m)
    m_OR <- exp(cbind(OR = coef(m), confint(m), N = log(nobs(m)) ))

    return (m_OR)

}

cohorts <- c("all", "cancer")
treatments <- c("mech_vent", "rrt", "vasopressor")


for (c in cohorts) {

            df <- read.csv(paste0("data/cohort_merged_", c, ".csv"))
            df <- encode_data(df, c, t)
            m_OR <- run_glm(df, t)
            write.csv(m_OR, paste0("results/glm/", c, ".csv"))
            file.remove('data/d.csv')

    }