import argparse
from tqdm import tqdm
import pandas as pd

def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("--original_file",
                        default="data\diagnoses_tables\icd_9_and_10.csv",
                        help="Insert your original file with ICD 9 and 10 codes")

    parser.add_argument("--result_file",
                        default="data\diagnoses_tables\icd_10_only.csv",
                        help="Insert your target path for the ICD 10 converted file ")

    return parser.parse_args()

if __name__ == '__main__':

    args = parse_args()

    df = pd.read_csv(args.original_file)

    conversions = pd.read_csv("data\icd_codes\ICD10_Formatted.csv")[['ICD-9', 'ICD-10']]

    mapping = dict(zip(conversions['ICD-9'], conversions['ICD-10']))

    n = len(df)
    i = 0
    idxs_to_drop = list()

    for index, row in tqdm(df.iterrows(), total=n):

        if row.icd_version == 9:
            try:
                df.iloc[index].icd_code = mapping[row.icd_code]
            except:
                idxs_to_drop.append(index)

    df.drop(idxs_to_drop, inplace=True)      
                
    print(f"{len(idxs_to_drop) / n * 100:.2f}% of codes failed!")
    print(f"Inital length: {n}\nFinal Length: {len(df)}")

    df.to_csv(args.result_file)