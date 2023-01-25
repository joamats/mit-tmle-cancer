read_confounders <- function(j, treatments, confounders) {

    other_t <- treatments$treatment[-j]

    final_confounders <- other_t

    for (i in 1:nrow(confounders)) {
        final_confounders <- append(final_confounders, confounders$confounder[i])
    }

    return(final_confounders)
}

databases <- c("MIMIC", "eICU")
cohorts <- c("all", "cancer")
sofa_ranges <- read.csv("config/SOFA_ranges.csv")
treatments <- read.delim("config/treatments.txt")
confounders <- read.delim("config/confounders.txt")

fla <- read_confounders(3,treatments, confounders)

print(fla)