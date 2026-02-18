import requests

celestrak_data_url = "http://www.celestrak.org/pub/satcat.csv"

try:

    satcat_data = requests.get(celestrak_data_url)
    satcat_data.raise_for_status()
    
    with open("satcat.csv", mode="wb") as dataFile:
        dataFile.write(satcat_data.content)

except Exception as e:
    print("Error fetching new satellite data: {e}")


