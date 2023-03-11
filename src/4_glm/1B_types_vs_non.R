source("src/glm/utils.R")

run_glm <- function(df, fla, treatment, cancer_type) {

    m <- glm(fla, data = df, family = "binomial"(link=logit))
    m_OR <- cbind(exp(cbind(OR = coef(m), confint(m), N = log(nobs(m)))), treatment)

    m_OR_frame <- as.data.frame(m_OR)[cancer_type, ] # limit to cancer coefficient

    colnames(m_OR_frame) <- c("OR", "CI_low", "CI_high", "N", "treatment")

    return (m_OR_frame)
}

# Main
treatments <- read.delim("config/treatments.txt")
confounders <- read.delim("config/glm1B_vars.txt")
cancer_types <- read.delim("config/cancer_types.txt")

# Read Data for this database and cohort
df <- read.csv("data/cohorts/merged_all.csv")

results_df <- data.frame(matrix(ncol=6, nrow=0))

for (j in 1:nrow(treatments)) {
    # Treatment
    t <- treatments$treatment[j]

    for (c in 1:nrow(cancer_types)) {

        cancer_type <- cancer_types$cancer_type[c]

        subset_df <- subset(df, df[[cancer_type]] == 1 | has_cancer == 0) 

        # Get formula with confounders and treatment
        formula <- paste0(read_confounders(j, treatments, confounders), ' + ', cancer_type)
        formula <- as.formula(formula)

        print(formula)

        print(paste0("Treatment: ", as.character(formula)[2]))
        print(paste0("Adjusted for: ", as.character(formula)[3]))

        # Run GLM
        m_OR_frame <- run_glm(subset_df, formula, t, cancer_type)

        # Save Results
        results_df <- rbind(results_df, m_OR_frame)
        write.csv(results_df, paste0("results/glm/1B.csv"))

    }


}           