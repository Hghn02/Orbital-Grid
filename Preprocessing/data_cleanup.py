import pandas as pd

satcat_csv = "/workspaces/93231704/project/CSV_Data/satcat.csv"
lv_csv = "/workspaces/93231704/project/CSV_Data/lv.csv"
launch_csv = "/workspaces/93231704/project/CSV_Data/launch.csv"
payload_csv = "/workspaces/93231704/project/CSV_Data/payload.csv"
satcat_celestrak = "/workspaces/93231704/project/CSV_Data/satcat_celestrak.csv"

satcat_csv_cleaned = "/workspaces/93231704/project/CSV_Clean_Data/satcat_cleaned.csv"
lv_csv_cleaned = "/workspaces/93231704/project/CSV_Clean_Data/lv_cleaned.csv"
launch_csv_cleaned = "/workspaces/93231704/project/CSV_Clean_Data/launch_cleaned.csv"
payload_csv_cleaned = "/workspaces/93231704/project/CSV_Clean_Data/payload_cleaned.csv"
satcat_celestrak_cleaned = "/workspaces/93231704/project/CSV_Clean_Data/satcat_celestrak_cleaned.csv"

lv_df = pd.read_csv(lv_csv)
lv_df.rename(columns={'#LV_Name': 'LV_Name'},inplace=True)
#lv_rows_drop = lv_df[lv_df['LV_Name'].str.match('#.*')].index
#lv_df = lv_df.drop(index=2)
lv_df = lv_df.drop(['LV_Variant','LV_Alias', 'LV_Min_Stage', 'LFlag', 'DFlag', 'MFlag','GTO_Capacity', 'Apogee', 'Range'], axis=1)
lv_df = lv_df.drop_duplicates(subset=["LV_Name"])
lv_df['LV_Max_Stage'] = lv_df['LV_Max_Stage'].astype(int)
lv_df.replace("-", "", inplace=True)
lv_df.replace("*", "", inplace=True)
lv_df.to_csv(lv_csv_cleaned,index=False)

launch_df = pd.read_csv(launch_csv)
launch_df.rename(columns={'#Launch_Tag': 'Launch_Tag'},inplace=True)
#launch_rows_drop = launch_df[launch_df['Launch_Tag'].str.match('#.*')].index
#launch_df = launch_df.drop(index=2)
launch_df = launch_df.drop(columns=launch_df.loc[:, 'Launch_Pad':'OrbPay'].columns)
launch_df = launch_df.drop(['Launch_JD', 'Variant', 'Flight_ID', 'Flight', 'Mission', 'FlightCode', 'Platform'], axis=1)
launch_df = launch_df.drop(columns=launch_df.loc[:, 'LaunchCode':'Notes'].columns)
launch_tags = launch_df['Launch_Tag'].tolist()
for i,t in enumerate(launch_tags):
    launch_tags[i] = t.replace("-"," ")
launch_df['Launch_Tag'] = pd.Series(launch_tags)
launch_df.replace("*", "", inplace=True)
launch_df.to_csv(launch_csv_cleaned,index=False)

satcat_df = pd.read_csv(satcat_csv)
satcat_df.rename(columns={'#JCAT': 'JCAT'},inplace=True)
#satcat_rows_drop = satcat_df[satcat_df['JCAT'].str.match('#.*')].index
#satcat_df = satcat_df.drop(index=2)
satcat_df = satcat_df.drop(columns=satcat_df.loc[:, 'Piece':'Dest'].columns)
satcat_df = satcat_df.drop(columns=satcat_df.loc[:, 'TotFlag':'IF'].columns)
satcat_df = satcat_df.drop(['State', 'Motor', 'Mass', 'MassFlag', 'DryMass', 'DryFlag', 'OQUAL', 'AltNames'],axis=1)
satcat_df.replace("-", "", inplace=True)
satcat_df['Satcat'] = pd.to_numeric(satcat_df['Satcat'],errors='coerce').astype('Int64')
satcat_df = satcat_df.drop_duplicates(subset=["Satcat"])
satcat_df.replace("*", "", inplace=True)
satcat_launch_tags = satcat_df['Launch_Tag'].tolist()
for j,k in enumerate(satcat_launch_tags):
    satcat_launch_tags[j] = k.replace("-"," ")
satcat_df['Launch_Tag'] = pd.Series(satcat_launch_tags)
satcat_df.to_csv(satcat_csv_cleaned,index=False)

payload_df = pd.read_csv(payload_csv)
payload_df.rename(columns={'#JCAT': 'JCAT'},inplace=True)
#payload_rows_drop = payload_df[payload_df['JCAT'].str.match('#.*')].index
#payload_df = payload_df.drop(index=2)
payload_df = payload_df.drop(columns=payload_df.loc[:, 'Control':'Comment'].columns)
payload_df = payload_df.drop(['Piece', 'LDate', 'TLast', 'TOp', 'TF', 'Plane', 'Att', 'Mvr', 'Class'],axis=1)
payload_df.replace("-", "", inplace=True)
payload_df.replace("*", "", inplace=True)
#jcat_ids = payload_df['JCAT'].tolist()
#for a,b in enumerate(jcat_ids):
    #jcat_ids[a] = b.replace("S","")
#payload_df['JCAT'] = pd.Series(jcat_ids)
payload_df.to_csv(payload_csv_cleaned,index=False)

sc_df = pd.read_csv(satcat_celestrak)
sc_df.rename(columns={'OWNER': 'STATE'},inplace=True)
sc_df = sc_df.drop(['RCS', 'DATA_STATUS_CODE'],axis=1)
sc_df['LAUNCH_DATE'] = pd.to_datetime(sc_df['LAUNCH_DATE'],format='mixed',errors='coerce')
sc_df['DECAY_DATE'] = pd.to_datetime(sc_df['DECAY_DATE'],format='mixed',errors='coerce')
sc_df['APOGEE'] = pd.to_numeric(sc_df['APOGEE'],errors='coerce').astype('Int64')
sc_df['PERIGEE'] = pd.to_numeric(sc_df['PERIGEE'],errors='coerce').astype('Int64')
sc_df.replace("-", "", inplace=True)
sc_df.to_csv(satcat_celestrak_cleaned,index=False)
