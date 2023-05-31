import numpy as np
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score
from zepid import load_sample_data
import warnings
warnings.simplefilter("ignore", UserWarning)
from causalml.inference.meta.tmle import TMLELearner



# Load sample data (you can use your own dataset)
data = load_sample_data(False)
print(data.head())

# Define the treatment, outcome, and covariates
treatment = 'art'
outcome = 'dead'
covariates = ['age0', 'cd40', 'dvl0', 'male']

# Prepare the data for analysis
data = data[covariates + [treatment, outcome]]

# Convert treatment variable to integers
data[treatment] = data[treatment].astype(int)

# Instantiate the Super Learner models
models = [
    LogisticRegression(),
    RandomForestClassifier()
]

# Initialize an empty matrix to store the predicted outcomes from each model
all_preds = np.zeros((data.shape[0], len(models)))

# Loop through each model, fit it on the data, and obtain predictions
for i, model in enumerate(models):
    model.fit(data[covariates], data[treatment])
    preds = model.predict(data[covariates])
    all_preds[:, i] = preds

# Calculate the predicted probabilities of treatment
super_learner_prob = np.mean(all_preds, axis=1)

print("Super Learner Probabilities:", super_learner_prob.shape)

# Instantiate the TMLE class
tmle_learner = TMLELearner(learner=models[0])

# Estimate treatment effects
te = tmle_learner.estimate_ate(data[covariates], data[outcome], data[treatment], super_learner_prob)
print("Treatment Effects:", te)
