# Design Document

By HARVIR GHUMAN

Video overview: <https://youtu.be/8pqPEHsp9fE>

---

## Scope

### Purpose of Database
The purpose of Orbital Grid is to serve as an active catalog of all past and present spacecraft launched into space by humanity. The database centralizes information about a spacecraft's launch vehicle, orbital elements, origin, payload and more. This is a goldmine for space enthusiasts who want to learn quick facts and technical details about any spacecraft from the type of orbit to who the manufacturer is. My database uses active, reliable data sources from Celestrak and Jonathan's Space Report so users can trust their query returns. The database is meant to be active by updating itself with new launches and spacecraft.

#### Inlcusions:
+ Satellite/object with unique identifiers such as `NORAD_ID`, `COSPAR_ID`, and `obj_name`
+ Launch vehicles with details like `lv_name`, `lv_family`, and `vehicle_class`
+ A Launch manifest with attributes such as `launch_tag`, `launch_date`, `launch_vehicle_id`
+ Orbital parameters such as `apogee_km`, `perigee_km`, and `period_minutes`
+ Satellite detailed infromation with attributes such as `country`, owner of satellite, and `manufacturer`
+ Payload information such as `program`, `category`, and `result`

#### Exclusions:

+ Satellite engineering characteristics such as power, data rate, bandwidth and more
+ Financial information such as costs and budget of satellite
+ Satellite instrument names or descriptions - this is usually proprietary information and not widely available
+ Live orbtial element updating and tracking (TLE) as these are constantly updating. However, the drift in these values is minimal and approximate static values should be sufficient

---

## ⚙️ Functional Requirements

### User Capabilities:

+ Query for any manmade object including satellites, debris, and rocket bodies in space
+ Find the orbital elements of a satellite if available
+ Find details of a launch including date, site, and objects being carried to space
+ Lookup details of a launch vehicle or a satellite and its payload
+ Write queries to study the history and present day of unmanned and manned spacecraft
+ Update satellite entries for attributes such as `operational_status` and `transmission_end_date`

### Beyond Scope:
+ Delete entries of objects that are still being monitored and tracked
+ Insert new launches and spacecraft as that will be handled by admin
+ Obtain live orbital element data for objects
+ See telemetry data for satellites

---

## Representation

### Entities:

+ #### 🚀 **launch_vehicles:**
    | Attribute | Type | Constraint |
    | :--- | :--- | :--- |
    | id | SERIAL | PRIMARY KEY |
    | lv_name | VARCHAR(32) | NOT NULL, UNIQUE
    | lv_family | VARCHAR(32) | NOT NULL |
    | lv_manufacturer | VARCHAR(16)|
    | max_stage | smallint | NOT NULL
    | length_m | DECIMAL(6,2)| |
    | diameter_m | DECIMAL(5,2) | |
    | launch_mass_tonnes | DECIMAL(6,2) |
    | leo_capacity_kg | INT |
    | launch_thrust_kn | INT |
    | vehicle_class | CHAR(1) |

+ #### 📅 **launch_manifest**
    | Attribute | Type | Constraint |
    | :--- | :--- | :--- |
    | id | SERIAL | PRIMARY KEY
    | launch_tag | VARCHAR(16) |
    | launch_date | VARCHAR(32) | NOT NULL
    | launch_site | VARCHAR(16) |
    | launch_vehicle_id | INT | FOREIGN KEY REFERENCES launch_vehicles("id")
    | agency | VARCHAR(16)|

+ #### 🛰️ **satellites**
    | Attribute | Type | Constraint
    | :--- | :--- | :--- |
    | NORAD_ID | INT | PRIMARY KEY
    | obj_name | VARCHAR(64) | NOT NULL
    | COSPAR_ID | VARCHAR(16) | UNIQUE
    | JCAT_ID* | VARCHAR(8) | NOT NULL, UNIQUE
    | launch_id | INT | FOREIGN KEY REFERENCES launch_manifest("id")

+ #### 🌍 **orbital_params**
    | Attribute | Details | Constraint
    | :--- | :--- | :--- |
    | id | SERIAL | PRIMARY KEY
    | satellite_id | INT | FOREIGN KEY REFERENCES satellites("NORAD_ID")
    | apogee_km | INT |
    | perigee_km | INT |
    | inclination_deg | NUMERIC(6,2)|
    | period_minutes | NUMERIC(9,3) |
    | orbit_center | VARCHAR(8)|
    | orbit_class | VARCHAR(8)|
    | orbit_type | ENUM |

 + #### 🔍 **satellite_info**
    | Attribute | Details | Constraint
    | :--- | :--- | :--- |
    | id | SERIAL | PRIMARY KEY
    | satellite_id | INT | FOREIGN KEY REFERENCES satellites("NORAD_ID")
    | country | VARCHAR(8) | NOT NULL
    | sat_owner | VARCHAR(32) |
    | manufacturer | VACHAR(16) |
    | bus | VARCHAR(32) |
    | total_mass_kg | DECIMAL(9,2) |
    | launch_site | VARCHAR(16) | NOT NULL
    | launch_date | DATE | NOT NULL
    | decay_date | DATE |
    | operational_status | CHAR(1) |
    | object_type | ENUM |

+ #### 📦 **sat_payload**
    | Attribute | Type | Constraint
    | :--- | :--- | :--- |
    | PAY_ID | SERIAL | PRIMARY KEY
    | JCAT_ID | VARCHAR(8) | FOREIGN KEY REFERENCES satellites("JCAT_ID")
    | pl_name | VARCHAR(32) |
    | transmission_end_date | VARCHAR(32)|
    | program | VARCHAR(32) |
    | category | VARCHAR(16)|
    | result | CHAR(1)|



### Select Entity Details:

* **`leo_capacity_kg`:** Maximum weight (*kilograms*) of cargo a launch vehicle can carry to Low Earth Orbit
* **`vehicle_class`:** Type of launch vehicle. Link to vehicle codes [table](https://planet4589.org/space/gcat/web/lvs/lv/index.html)
* **`NORAD_ID`:** North American Air Defense Command catalogs objects in space with a sequential 5 digit numebr assigned by USSPACECOM in order of identification
* **`obj_name`:** Name of the satellite that includes identifying characters

    | Code | Satellite Name Component Description |
    | :--- | :--- |
    | R/B(1) | Rocket body, first stage |
    | R/B(2) | Rocket body, second stage |
    | DEB | Debris |
    | PLAT | Platform |
    | (...) | Items in parentheses are alternate names |
    | [...] | Items in brackets indicate type of object (e.g., BREEZE-M DEB [TANK] = tank) |
    | & | An ampersand indicates two or more objects are attached |

* **`COSPAR_ID`:** An internationally agreed upon naming convention for satellites. The designator contains the launch year, the launch number of the year and the part of the launch ("A": payload, "B": rocket booster or second payload)
* **`apogee_km`:** Farthest distance (*kilometers*) between satellite and Earth in the orbit
* **`perigee_km`:** Shortest distance (*kilometers*) between satellite and Earth in the orbit
* **`inclination_deg`:** Angle (*degrees*) between orbital plane of satellite and plane of the celestial body being orbited
* **`period_minutes`:** Total time (*minutes*) it takes for satellite to complete one revolution around a celestial body
* **`eccentricity`:** Measure of how elliptical an orbit is with values ranging from 0 to 1 with 0 being perfect circle and 1 being a total ellipse
* **`orbit_center`:** The celestial body that a satellite orbits

    | Code | Orbit Center |
    | :--- | :--- |
    | AS | Asteroid |
    | CO | Comet |
    | EA | Earth |
    | ELx | Earth Lagrange (EL1 = Earth L1, EL2 = Earth L2) |
    | EM | Earth-Moon Barycenter |
    | JU | Jupiter |
    | MA | Mars |
    | ME | Mercury |
    | MO | Moon (Earth) |
    | NE | Neptune |
    | PL | Pluto |
    | SA | Saturn |
    | SS | Solar System Escape |
    | SU | Sun |
    | UR | Uranus |
    | VE | Venus |
    | NORAD_CAT_ID | for docked objects |

* **`orbit_class`:** Orbit category such as LEO (Low Earth Orbit) or GEO (Geostationary Orbit) defined by period, eccentricity and inclination. Link to orbital codes [table](https://planet4589.org/space/gcat/web/intro/orbits.html)

* **`orbit_type`:**
    | Code | Orbit Type |
    | :--- | :--- |
    | ORB | Orbit |
    | LAN | Landing |
    | IMP | Impact |
    | DOC | Docked to another object in the SATCAT |
    | R/T | Roundtrip |

* **`country`:** Country/agency where satellite is from. Link to counry codes [table](https://celestrak.org/satcat/sources.php)
* **`launch_site`** (satellite_info): Launch range name. Link to launch range codes [key](https://celestrak.org/satcat/launchsites.php)
* **`operational_status`:** Indicator for the operational state of a satellite

    | Code | Operational Status Meaning |
    | :--- | :--- |
    | + | Operational |
    | - | Nonoperational |
    | P | Partially Operational - Partially fulfilling primary mission or secondary mission(s) |
    | B | Backup/Standby - Previously operational satellite put into reserve status |
    | S | Spare - New satellite awaiting full activation |
    | X | Extended Mission |
    | D | Decayed |
    | ? | Unknown |





### Relationships

<figure style="margin: 20px auto 0; width:fit-content;">
  <img src="Satellites DB ER Diagram-2026-02-01-013734.png"
       alt="Screenshot Placeholder"
       width="1140"
       style="display:block;">
  <figcaption style="text-align:center; font-style:italic; color:#ffffff; margin-top:8px;">
    Figure 1: Orbital Grid Database – Entity-Relationship Diagram (2026-02-01)
  </figcaption>
</figure>

 #### Descriptions:
* Each launch manifest should have exactly 1 launch vehicle
* Launch vehicles can have 1 or many launch manifests
* Launch manifests can carry 0 or more satellites
* A satellite can only have 1 launch manifest
* A satellite can only have 1 set of orbital elements
* A satellite can only have 1 set of detailed information
* A satellite can only have 1 payload. This is due to design of database because payloads are considered independent entities with a unique id that corresponds to satellite NORAD ids. Does not limit the database and queries.

---

## ⚡Optimizations

 ### Views:
* **`STARLINK`:** Shows all Starlink satellites ever launched along with orbit information , names, and ops status ordered by launch date
* **`INTERPLANETARY_SPACECRAFT`:** Spacecraft that don't orbit the Earth and are in deep space along with their orbit information and other details ordered by country and launch date
* **`GEO_SPACECRAFT`:** All spacecraft that are in some kind of Geostationary orbit (not including debris) ordered by program and launch date

### Indexes:
* **`Orbit_Id`:** Index on satellite_id in orbital_params table
* **`Sat_Info_Id`:** Index on satellite_id in satellite_info table
* **`Payload_JCAT`:** Index on JCAT_ID in sat_payload table
* **`Satellite_Name`:** Index on obj_name in satellites table
* **`Sat_Info_Covering`:** Covering index on object_type, country, and manufacturer

---

## ⚠️ Limitations

* My database does not represent the payload to satellite relationship well as in real life it is often N:1 instead of 1:1 however, it does not limit the querying ability of this database much
* No support for updating database with new launches and spacecraft daily automatically. This will likely be a lengthy script using Python requests to pull data, pandas to clean data and
SQL code to update the entire database chained together.
* Only a select few orbital elements are included - difficult to obtain all of them

---

## 📚 Data Sources

* Credit to [Jonathan's Space Report](https://planet4589.org/space/index.html) for the TSV data files I used to populate the database.
* Credit to the SATCAT CSV data files and documentation from [Celestrak](https://celestrak.org/satcat/search.php) that I used to populate and document some of my database.
