source("src/glm/utils.R")

run_glm <- function(df, fla, treatment, sofa_min, sofa_max) {

    m <- glm(fla, data = df, family = "binomial"(link=logit))
    m_OR <- cbind(exp(cbind(OR = coef(m), confint(m), N = log(nobs(m)))), treatment, sofa_min, sofa_max )

    m_OR_frame <- as.data.frame(m_OR)['has_cancer', ] # limit to cancer coefficient
    colnames(m_OR_frame) <- c("OR", "CI_low", "CI_high", "N", "treatment", "sofa_min", "sofa_max")

    return (m_OR_frame)
}

# Main
sofa_ranges <- read.csv("config/SOFA_ranges.csv")
treatments <- read.delim("config/treatments.txt")
confounders <- read.delim("config/confounders.txt")

# Read Data for this database and cohort
df <- read.csv(paste0("data/cohorts/merged_all.csv"))

results_df <- data.frame(matrix(ncol=8, nrow=0))

for (i in 1:nrow(sofa_ranges)) {

    sofa_max <- sofa_ranges$max[i]
    sofa_min <- sofa_ranges$min[i]

    print(paste0("Stratification by SOFA: ", sofa_min, " - ", sofa_max))

    for (j in 1:nrow(treatments)) {
        # Treatment
        t <- treatments$treatment[j]

        # Stratify by SOFA
        subset_df <- subset(df, SOFA <= sofa_max & SOFA >= sofa_min)

        # Get formula with confounders and treatment
        formula <- as.formula(read_confounders(j, treatments, confounders) )
        print(paste0("Treatment: ", as.character(formula)[2]))
        print(paste0("Adjusted for: ", as.character(formula)[3]))

        # Run GLM
        m_OR_frame <- run_glm(subset_df, formula, t, sofa_min, sofa_max)

        # Save Results
        results_df <- rbind(results_df, m_OR_frame)
        write.csv(results_df, paste0("results/glm/1A.csv"))
    }           
}