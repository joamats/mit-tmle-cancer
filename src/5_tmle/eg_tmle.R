library(tmle)
library(pROC)
library(data.table)


### Get the data ###
# read features from list in txt
confounders <- read.delim("config/confounders_test.txt")$confounder

# Define the SL library
SL_library <- read.delim("config/SL_libraries_base.txt")

data <- read.csv("data/cohorts/merged_all.csv")

treatment <- "mv_elig"
outcome <- "mortality_in"

W <- data[, confounders]
A <- data[, treatment]
Y <- data[, outcome]

tmle_fit <- tmle::tmle(
Y = Y, # outcome vector
A = A, # treatment vector
W = W, # matrix of confounders W1, W2, W3, W4
Q.SL.library = SL_libraries$SL_library, # superlearning libraries from earlier for outcome regression Q(A,W)
g.SL.library = SL_libraries$SL_library) # superlearning libraries from earlier for treatment regression g(W)

print(tmle_fit)
