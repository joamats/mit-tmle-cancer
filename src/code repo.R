cohorts <- c("all", "cancer")
treatments <- c("mech_vent", "rrt", "vasopressor")
#sens_analys <- c("all", "no_cirrhosis", "no_esrd")

for (c in cohorts) {
    for (t in treatments) {

            df <- read.csv(paste0("data/cohort_", c, "_", t, ".csv"))
            df <- encode_data(df, c, t)
            m_OR <- run_glm(df, t)
            write.csv(m_OR, paste0("results/glm/", c, "_", t, ".csv"))
            file.remove('data/d.csv')

    }
}