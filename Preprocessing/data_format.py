import csv
import pandas as pd
import os

satcat_tsv = "/workspaces/93231704/project/TSV_Data/satcat.tsv"
lv_tsv = "/workspaces/93231704/project/TSV_Data/lv.tsv"
payload_tsv = "/workspaces/93231704/project/TSV_Data/psatcat.tsv"
launch_tsv = "/workspaces/93231704/project/TSV_Data/launch.tsv"

file_list = [satcat_tsv,lv_tsv,payload_tsv,launch_tsv]
output_files = ["satcat.csv","lv.csv","payload.csv","launch.csv"]

for i,j in enumerate(file_list):
    if os.path.isfile(j):
        if not os.path.isfile(f"/workspaces/93231704/project/{output_files[i]}"):
            try:
                csv_table = pd.read_table(j,sep='\t')
                csv_table.to_csv(output_files[i],index=False)
                print(f"Successfully created {output_files[i]} file")

            except Exception as e:
                print(f"Something went wrong: {e}")

        else:
            print(f"{output_files[i]} already exists.")

    else:
        print(f"{j} does not exist.")

