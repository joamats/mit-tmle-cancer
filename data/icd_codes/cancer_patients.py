import argparse
from tqdm import tqdm
import pandas as pd

def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--original_file",
                        default="data\diagnoses_tables\icd_10_only.csv",
                        help="Insert your original file with ICD 10 codes")

    parser.add_argument("--result_file",
                        default="data\diagnoses_tables\icd_10_only.csv",
                        help="Insert your target path for the cancer ICD 10 codes only file")

    return parser.parse_args()

