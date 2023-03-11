source("src/glm/utils.R")

run_glm <- function(df, fla, treatment) {

    m <- glm(fla, data = df, family = "binomial"(link=logit))
    m_OR <- cbind(exp(cbind(OR = coef(m), confint(m), N = log(nobs(m)))), treatment)

    m_OR_frame <- as.data.frame(m_OR) #['group_cancer', ] # limit to cancer coefficient
    m_OR_frame <- m_OR_frame %>% filter(row.names(m_OR_frame)
                             %in% c('group_cancergroup_hematological',
                                    'group_cancergroup_metastasized'))
    colnames(m_OR_frame) <- c("OR", "CI_low", "CI_high", "N", "treatment")
    control_frame <- data.frame(OR = 1, CI_low = 1, CI_high = 1,
                                N = nobs(m), treatment = treatment,
                                row.names = "group_cancergroup_solid")
    OR_df <- rbind(m_OR_frame, control_frame)

    return (OR_df)
}

# Main
treatments <- read.delim("config/treatments.txt")
confounders <- read.delim("config/confounders_cancer.txt")

# Read Data for this database and cohort
df <- read.csv(paste0("data/cohorts/merged_cancer.csv"))

# Undo One Hot Encoding
sub_df <- df %>% select(contains("group_"))
df$group_cancer <- names(sub_df)[max.col(sub_df)]

# Relevel the factor with cancer type
df <- within(df, group_cancer <- relevel(factor(group_cancer), ref = "group_solid"))

results_df <- data.frame(matrix(ncol=6, nrow=0))

for (j in 1:nrow(treatments)) {
    # Treatment
    t <- treatments$treatment[j]

    # Stratify by SOFA
    subset_df <- subset(df, SOFA <= sofa_max & SOFA >= sofa_min)

    # Get formula with confounders and treatment
    formula <- read_confounders(j, treatments, confounders) 
    print(paste0("Treatment: ", as.character(formula)[2]))
    print(paste0("Adjusted for: ", as.character(formula)[3]))

    # Run GLM
    m_OR_frame <- run_glm(subset_df, formula, t)

    # Save Results
    results_df <- rbind(results_df, m_OR_frame)
    write.csv(results_df, paste0("results/glm/1C.csv"))
}           