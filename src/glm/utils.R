read_confounders <- function(j, treatments, confounders) {

    t <- treatments$treatment[j]
    vars <- paste0(t, " ~ ")

    other_t <- treatments$treatment[-j]

    for (k in 1:length(other_t)) {

        vars <- paste0(vars, other_t[k], " + ")
    }

    for (i in 1:nrow(confounders)) {

        vars <- paste0(vars, confounders$confounder[i], " + ")
    }

    fla <- substr(vars, 1, nchar(vars)-3)
    return(fla)
}