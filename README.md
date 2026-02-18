# 🛰️ Orbital Grid

> A comprehensive PostgreSQL database catalog of all past and present spacecraft launched into space by humanity.

[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-blue.svg)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

<p align="center">
  <img src="Gemini_Generated_Image_u7lohwu7lohwu7lo.png" width="600" />
</p>
---

## 📖 Overview

Orbital Grid is an active catalog that centralizes information about spacecraft their launch vehicles, orbital parameters, and payload data. Built with PostgreSQL, this database serves as a valuable resource for space enthusiasts, researchers, and analysts who need access to quick facts and stats about the spacecraft industry.

The database integrates data from trusted sources including [Celestrak](https://celestrak.org/satcat/search.php) and [Jonathan's Space Report](https://planet4589.org/space/index.html), providing accurate historical and current information about satellites, rocket bodies, and space debris.

### Key Features

- **Comprehensive Coverage**: Tracks satellites, debris, and rocket bodies with unique identifiers (NORAD_ID, COSPAR_ID)
- **Launch History**: Complete launch manifests with dates, sites, and vehicle specifications
- **Orbital Elements**: Detailed orbital parameters including apogee, perigee, inclination, and period
- **Payload Information**: Mission programs, categories, and operational status
- **Optimized Queries**: Pre-built views for common queries (Starlink satellites, interplanetary spacecraft, GEO satellites)

---

## 🛠️ Tech Stack

- **PostgresSQL 14+**: Database queries and design
- **Python 3.9**: Data formatting and preprocessing
- **Mermaid JS**: Entity Relationship Diagram Design

---

## 💡 Usage Examples



### Query Examples

*What are the dominant satellite categories in GEO orbit and what are their average inclination and eccentricities ?*
```sql
SELECT "category", COUNT("obj_name") AS "Number of Satellites", ROUND(AVG("eccentricity")::numeric,4) AS
"Average Eccentricity", ROUND(AVG("inclination_deg")::numeric,2) AS "Average Inclination_deg" FROM "GEO_SPACECRAFT"
GROUP BY "category"
ORDER BY COUNT("obj_name") DESC LIMIT 5;
```
```
 category | Number of Satellites | Average Eccentricity | Average Inclination_deg
----------+----------------------+----------------------+-------------------------
 COM      |                 1013 |               0.0015 |                    7.22
 MET      |                   61 |               0.0010 |                    7.10
 EW       |                   46 |               0.0172 |                    7.97
 NAV      |                   38 |               0.0038 |                   23.80
 TECH     |                   38 |               0.0189 |                    4.03
(5 rows)

```

*Find all the Sentinel Missions:*
```sql
SELECT "obj_name","satellite_info"."country", "satellite_info"."sat_owner", "satellite_info"."manufacturer", "satellite_info"."total_mass_kg", "satellite_info"."operational_status", "satellite_info"."launch_date", "sat_payload"."category" FROM "satellites"
JOIN "satellite_info" On "satellites"."NORAD_ID" = "satellite_info"."satellite_id"
JOIN "sat_payload" ON "satellites"."JCAT_ID" = "sat_payload"."JCAT_ID"
WHERE "satellites"."obj_name" LIKE 'SENTINEL-%'
ORDER BY "launch_date" ASC;
```
```
  obj_name   | country | sat_owner  | manufacturer | total_mass_kg | operational_status | launch_date | category
-------------+---------+------------+--------------+---------------+--------------------+-------------+----------
 SENTINEL-1A | ESA     | ESA        | THALES       |       2157.00 | +                  | 2014-04-03  | IMG-R
 SENTINEL-2A | ESA     | COPERN/ESA | ADSB         |       1130.00 | +                  | 2015-06-23  | IMG
 SENTINEL-3A | ESA     | COPERN/ESA | THALES       |       1250.00 | +                  | 2016-02-16  | IMG
 SENTINEL-1B | ESA     | COPERN/ESA | THALES       |       2157.00 |                    | 2016-04-25  | IMG-R
 SENTINEL-2B | ESA     | COPERN/ESA | ADSB         |       1130.00 | +                  | 2017-03-07  | IMG
 SENTINEL-5P | ESA     | COPERN/ESA | ADSUK        |        820.00 | +                  | 2017-10-13  | IMG
 SENTINEL-3B | ESA     | COPERN/ESA | THALES       |       1250.00 | +                  | 2018-04-25  | IMG
 SENTINEL-6A | ESA     | COPERN/ESA | ADSDF        |       1192.00 | +                  | 2020-11-21  | EOSCI
 SENTINEL-2C | ESA     | COPERN/ESA | ADSB         |       1143.00 | +                  | 2024-09-05  | IMG
 SENTINEL-1C | ESA     | COPERN/ESA | THALES       |       2157.00 | +                  | 2024-12-05  | IMG-R
 SENTINEL-1D | ESA     | COPERN/ESA | THALES       |       2157.00 | +                  | 2025-11-04  | IMG-R
 SENTINEL-6B | ESA     | COPERN/ESA | ADSDF        |       1140.00 | +                  | 2025-11-17  | EOSCI
(12 rows)
```

*Find ICESAT orbital parameters:*
```sql
SELECT * FROM "orbital_params" WHERE "satellite_id" = (
    SELECT "NORAD_ID" FROM "satellites" WHERE "obj_name" = 'ICESAT'
);
```
```
  id   | satellite_id | apogee_km | perigee_km | inclination_deg | period_minutes | orbit_center | orbit_class | orbit_type | eccentricity
-------+--------------+-----------+------------+-----------------+----------------+--------------+-------------+------------+--------------
 27642 |        27642 |       139 |        129 |           93.97 |         87.170 | EA           | LLEO/P      | IMP        |       0.0008
(1 row)
```

---

## 🗂️ Project Structure

```
project/
├── README.md
├── DESIGN.md
├── schema.sql
├── queries.sql
├── Gemini_Generated_Image_u7lohwu7lohwu7lo.png
├── Satellites DB ER Diagram-2026-02-01-013734.png
├── Preprocessing/
│   ├── celestrak_fetch.py
│   ├── data_format.py
│   └── data_cleanup.py
├── Data/
│   ├── CSV_Clean_Data/
│   │   ├── launch_cleaned.csv
│   │   ├── lv_cleaned.csv
│   │   ├── payload_cleaned.csv
│   │   ├── satcat_celestrak_cleaned.csv
│   │   └── satcat_cleaned.csv
│   ├── CSV_Data/
│   │   ├── launch.csv
│   │   ├── lv.csv
│   │   ├── payload.csv
│   │   ├── satcat_celestrak.csv
│   │   └── satcat.csv
│   └── TSV_Data/
│       ├── launch.tsv
│       ├── lv.tsv
│       ├── psatcat.tsv
│       └── satcat.tsv
└── Utilities/
    ├── reset.sql
    └── load_data.sql
```
---


## 🙏 Acknowledgments

- **[Jonathan's Space Report](https://planet4589.org/space/index.html)** - TSV data files and comprehensive space launch documentation
- **[Celestrak](https://celestrak.org/)** - SATCAT CSV data and satellite catalog documentation
- **Course**: CS50 SQL - Introduction to Databases with SQL

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👤 Author

**Harvir Ghuman**

- GitHub: [@Hghn02](https://github.com/Hghn02)
- LinkedIn: [Harvir Ghuman](https://www.linkedin.com/in/hghuman)

