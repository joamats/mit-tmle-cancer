# Disparities in Use of Interventions across ICU Cancer Patients

(to be organized)

## How to run this project?

### 1. Clone this repository

Run the following command in your terminal.
```sh
git clone https://github.com/joamats/mit-tmle-cancer.git
```

### 2. Install required Packages
R scripts
Run the following command in R:
```sh
source('setup/install_packages.R')
```

Python scripts
Run the following command:
```sh
pip install -r setup/requirements_py.txt
```

### 3. Get the Data!

Both MIMIC and eICU data can be found in [PhysioNet](https://physionet.org/), a repository of freely-available medical research data, managed by the MIT Laboratory for Computational Physiology. Due to its sensitive nature, credentialing is required to access both datasets.

Documentation for MIMIC-IV's can be found [here](https://mimic.mit.edu/) and for eICU [here](https://eicu-crd.mit.edu/).

#### Integration with Google Cloud Platform (GCP)

In this section, we explain how to set up GCP and your environment in order to run SQL queries through GCP right from your local Python setting. Follow these steps:

1) Create a Google account if you don't have one and go to [Google Cloud Platform](https://console.cloud.google.com/bigquery)
2) Enable the [BigQuery API](https://console.cloud.google.com/apis/api/bigquery.googleapis.com)
3) Create a [Service Account](https://console.cloud.google.com/iam-admin/serviceaccounts), where you can download your JSON keys
4) Place your JSON keys in the parent folder (for example) of your project
5) Create a .env file with the command `nano .env` or `touch .env` for Mac and Linux users or `echo. >  .env` for Windows.
6) Update your .env file with your ***JSON keys*** path and the ***id*** of your project in BigQuery

Follow the format:
```sh
KEYS_FILE = "../GoogleCloud_keys.json"
PROJECT_ID = "project-id"
```

#### MIMIC-IV

After getting credentialing at PhysioNet, you must sign the data use agreement and connect the database with GCP, either asking for permission or uploading the data to your project. Please note that only MIMIC v2.0 is available at GCP.

Having all the necessary tables for the cohort generation query in your project, run the following command to fetch the data as a dataframe that will be saved as CSV in your local project. Make sure you have all required files and folders

```shell
python3 src/2_cohorts/1_get_data.py --sql "src/1_sql/MIMIC/MIMIC_cancer.sql" --destination "data/MIMIC.csv"
```

#### eICU-CRD

The rationale for eICU-CRD is similar. Run the following commands:

```sh
python3 src/2_cohorts/1_get_data.py --sql "src/1_sql/eICU/eICU_cancer.sql" --destination "data/eICU.csv"
```

### 4. Get the Cohorts

**4.1 Get the cohorts ready for analysis**

With the following command, you can get the same cohorts we used for the study. Run the commands in your terminal:

#### eICU-CRD

```sh
python3 src/2_cohorts/2_eICU.py
```

#### MIMIC-IV
```sh
python3 src/2_cohorts/3_MIMIC.py
```

This will create the files `data/cohorts/MIMIC_all.csv` and `data/cohorts/MIMIC_cancer.csv` for MIMIC IV, and the files `data/cohorts/eICU_all.csv` and `data/cohorts/eICU_cancer.csv` for eICU.

**4.2 Get a merged dataframe ready**

Run the command in you R console:
```sh  
source("src/2_cohorts/4_load_data.R")
```
This will create the files `data/cohorts/merged_all.csv` and `data/cohorts/merged_cancer.csv`.

### 3. Run the TMLE analysis

We made it really easy for you in this part. All you have to do is:

```sh
source("src/r/tmle.R")
```

And you'll get the resulting odds ratios both for MIMIC and eICU, for both timepoints and all sensitivity analysis here: `results/tmle`

## How to contribute?

We are actively working on this project.
Feel free to raise questions opening an issue, send an email to jcmatos@mit.edu or to fork this project and submit a pull request!
