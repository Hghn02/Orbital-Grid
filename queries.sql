\copy launch_vehicles(lv_name, lv_family, lv_manufacturer, max_stage, length_m, diameter_m, launch_mass_tonnes, leo_capacity_kg, launch_thrust_kn, vehicle_class) FROM '/workspaces/93231704/project/CSV_Clean_Data/lv_cleaned.csv' DELIMITER ',' CSV HEADER;

\copy launch_staging(launch_tag, launch_date, launch_vehicle, launch_site, agency) FROM '/workspaces/93231704/project/CSV_Clean_Data/launch_cleaned.csv' DELIMITER ',' CSV HEADER;

INSERT INTO "launch_manifest"(launch_tag, launch_date, launch_site, launch_vehicle_id, agency)
SELECT "launch_tag", "launch_date", "launch_site", "launch_vehicles"."id", "agency" FROM "launch_staging"
JOIN "launch_vehicles" ON "launch_staging"."launch_vehicle" = "launch_vehicles"."lv_name";

-- Copy csv file data into staging tables

\copy satcat_celestrak_staging(obj_name, cospar_id, norad_id, object_type, ops_status, country, launch_date, launch_site, decay_date, period_min, inclination, apogee, perigee, orbit_center, orbit_type) FROM '/workspaces/93231704/project/CSV_Clean_Data/satcat_celestrak_cleaned.csv' DELIMITER ',' CSV HEADER;

\copy satcat_staging(jcat_num, norad_id, launch_tag, sat_owner, manufacturer, bus, total_mass, orbit_class) FROM '/workspaces/93231704/project/CSV_Clean_Data/satcat_cleaned.csv' DELIMITER ',' CSV HEADER;

\copy payload_staging(jcat, pl_name, transmission_end_date, program, category, result) FROM '/workspaces/93231704/project/CSV_Clean_Data/payload_cleaned.csv' DELIMITER ',' CSV HEADER;


INSERT INTO "satellites"("NORAD_ID", "obj_name", "COSPAR_ID", "JCAT_ID", "launch_id")
SELECT "satcat_celestrak_staging"."norad_id", "satcat_celestrak_staging"."obj_name", "satcat_celestrak_staging"."cospar_id", "satcat_staging"."jcat_num","launch_manifest"."id" FROM "satcat_staging"
JOIN "satcat_celestrak_staging" ON "satcat_staging"."norad_id" = "satcat_celestrak_staging"."norad_id"
LEFT JOIN "launch_manifest" ON TRIM("satcat_staging"."launch_tag") = TRIM("launch_manifest"."launch_tag");

INSERT INTO "orbital_params"(satellite_id, apogee_km, perigee_km, inclination_deg, period_minutes, orbit_center, orbit_class, orbit_type)
SELECT "satcat_celestrak_staging"."norad_id", "apogee", "perigee", "inclination", "period_min", "orbit_center", "satcat_staging"."orbit_class", "orbit_type" FROM "satcat_celestrak_staging"
JOIN "satcat_staging" ON "satcat_celestrak_staging"."norad_id" = "satcat_staging"."norad_id";

INSERT INTO "satellite_info"(satellite_id, country, sat_owner, manufacturer, bus, total_mass_kg, launch_site, launch_date, decay_date, operational_status, object_type)
SELECT "satcat_celestrak_staging"."norad_id", "country", "satcat_staging"."sat_owner", "satcat_staging"."manufacturer", "satcat_staging"."bus", "satcat_staging"."total_mass", "launch_site", "launch_date", "decay_date", "ops_status", "object_type" FROM "satcat_celestrak_staging"
JOIN "satcat_staging" ON "satcat_celestrak_staging"."norad_id" = "satcat_staging"."norad_id";

INSERT INTO "sat_payload"("JCAT_ID", "pl_name", "transmission_end_date", "program", "category", "result")
SELECT "satellites"."JCAT_ID", "pl_name", "transmission_end_date", "program", "category", "result" FROM "payload_staging"
JOIN "satellites" ON "payload_staging"."jcat" = "satellites"."JCAT_ID";

-- Add eccentricity column inside of orbital_params
ALTER TABLE "orbital_params"
ADD "eccentricity" real;

UPDATE "orbital_params"
SET "eccentricity" = ABS(ROUND(((6378.0 + "apogee_km") - (6378.0 + "perigee_km")) / ((6378.0 + "apogee_km") + (6378.0 + "perigee_km")),4));

-- Creating Views

CREATE VIEW "STARLINK" AS
    SELECT "launch_id","obj_name", "orbital_params"."period_minutes", "orbital_params"."orbit_class", "satellite_info"."total_mass_kg", "satellite_info"."launch_site", "satellite_info"."launch_date", "satellite_info"."operational_status" FROM "satellites"
    JOIN "orbital_params" ON "satellites"."NORAD_ID" = "orbital_params"."satellite_id"
    JOIN "satellite_info" ON "satellites"."NORAD_ID" = "satellite_info"."satellite_id"
    WHERE "obj_name" LIKE 'STARLINK%'
    ORDER BY "satellite_info"."launch_date" ASC;

CREATE VIEW "INTERPLANETARY_SPACECRAFT" AS
    SELECT "obj_name", "orbital_params"."orbit_center", "orbital_params"."orbit_type", "orbital_params"."orbit_class", "satellite_info"."country", "satellite_info"."sat_owner", "satellite_info"."manufacturer", "satellite_info"."bus","satellite_info"."launch_site", "satellite_info"."launch_date", "sat_payload"."program", "sat_payload"."result" FROM "satellites"
    JOIN "orbital_params" ON "satellites"."NORAD_ID" = "orbital_params"."satellite_id"
    JOIN "satellite_info" ON "satellites"."NORAD_ID" = "satellite_info"."satellite_id"
    JOIN "sat_payload" ON "satellites"."JCAT_ID" = "sat_payload"."JCAT_ID"
    WHERE "orbital_params"."orbit_center" NOT IN('EA','EL1', 'EL2', 'EM') AND "orbital_params"."orbit_type" <> 'DOC' AND "orbit_class" IN('DSO', 'CLO', 'EEO', 'HCO', 'PCO', 'SSE') AND "satellite_info"."object_type" = 'PAY'
    ORDER BY "satellite_info"."country" ASC, "satellite_info"."launch_date" ASC;

CREATE VIEW "GEO_SPACECRAFT" AS
    SELECT "NORAD_ID", "satellites"."obj_name", "orbital_params"."orbit_class",ROUND("orbital_params"."period_minutes",2), "orbital_params"."eccentricity","orbital_params"."inclination_deg","satellite_info"."country","satellite_info"."sat_owner", "satellite_info"."manufacturer", "satellite_info"."launch_site", "satellite_info"."launch_date", "sat_payload"."program", "sat_payload"."category" FROM "satellites"
    JOIN "satellite_info" ON "satellites"."NORAD_ID" = "satellite_info"."satellite_id"
    JOIN "orbital_params" ON "satellites"."NORAD_ID" = "orbital_params"."satellite_id"
    JOIN "sat_payload" ON "satellites"."JCAT_ID" = "sat_payload"."JCAT_ID"
    WHERE "orbital_params"."orbit_class" LIKE 'GEO%' AND "satellite_info"."object_type" <> 'DEB'
    ORDER BY "sat_payload"."program" ASC, "satellite_info"."launch_date" DESC;

-- Creating Indexes for Optimization

CREATE INDEX "Sat_Info_Covering"
ON "satellite_info"("object_type","country", "manufacturer");

CREATE INDEX "Satellite_Name"
ON "satellites"("obj_name");

CREATE INDEX "Payload_JCAT"
ON "sat_payload"("JCAT_ID");

CREATE INDEX "Sat_Info_Id"
ON "satellite_info"("satellite_id");

CREATE INDEX "Orbit_Id"
ON "orbital_params"("satellite_id");

-- Queries

-- What are the dominant satellite categories in GEO orbit and what are their average inclination and eccentricities ?
SELECT "category", COUNT("obj_name") AS "Number of Satellites", ROUND(AVG("eccentricity")::numeric,4) AS "Average Eccentricity", ROUND(AVG("inclination_deg")::numeric,2) AS "Average Inclination_deg" FROM "GEO_SPACECRAFT"
GROUP BY "category"
ORDER BY COUNT("obj_name") DESC LIMIT 5;

-- Find the spacecraft that have visisted the outer parts of solar system (past Mars) including flybys
SELECT "obj_name", "orbit_center", "orbit_type", "orbit_class", "country", "sat_owner","launch_date", "program", "result" FROM "INTERPLANETARY_SPACECRAFT"
WHERE "orbit_center" IN('SU','JU', 'SA', 'NE', 'UR', 'PL', 'SS') AND "orbit_class" <> 'CLO'
ORDER BY "sat_owner" ASC, "launch_date" ASC;

-- Find the total starlink mass launched into orbit for 2024
SELECT SUM("total_mass_kg") AS "Total Mass in Orbit (kg)" FROM "STARLINK"
WHERE "launch_date" BETWEEN '2024-01-01' AND '2024-12-31'

-- Which orbital launch vehicles have the most launches ?
SELECT "lv_name", COUNT("launch_manifest"."id") AS "Number of launches" FROM "launch_vehicles"
JOIN "launch_manifest" ON "launch_vehicles"."id" = "launch_manifest"."launch_vehicle_id"
WHERE "vehicle_class" = 'O'
GROUP BY "lv_name"
ORDER BY "Number of launches" DESC LIMIT 10;

-- What was the most recent launch of the Molniya 8K78M rocket and what was it carrying ?
SELECT * FROM "launch_manifest" WHERE "launch_vehicle_id" = (
    SELECT "id" FROM "launch_vehicles" WHERE "lv_name" = 'Molniya 8K78M')
    ORDER BY "launch_manifest"."id" DESC LIMIT 1;

SELECT "NORAD_ID", "obj_name", "orbital_params"."period_minutes", "orbital_params"."orbit_class", "satellite_info"."country", "satellite_info"."sat_owner", "satellite_info"."total_mass_kg", "sat_payload"."category", "sat_payload"."program" FROM "satellites"
JOIN "launch_manifest" ON "satellites"."launch_id" = "launch_manifest"."id"
JOIN "orbital_params" ON "satellites"."NORAD_ID" = "orbital_params"."satellite_id"
JOIN "satellite_info" On "satellites"."NORAD_ID" = "satellite_info"."satellite_id"
JOIN "sat_payload" ON "satellites"."JCAT_ID" = "sat_payload"."JCAT_ID"
WHERE "launch_manifest"."id" = 70805 AND "satellite_info"."object_type" NOT IN('DEB', 'R/B');

-- Find all the Sentinel missions
SELECT "obj_name","satellite_info"."country", "satellite_info"."sat_owner", "satellite_info"."manufacturer", "satellite_info"."total_mass_kg", "satellite_info"."operational_status", "satellite_info"."launch_date", "sat_payload"."category" FROM "satellites"
JOIN "satellite_info" On "satellites"."NORAD_ID" = "satellite_info"."satellite_id"
JOIN "sat_payload" ON "satellites"."JCAT_ID" = "sat_payload"."JCAT_ID"
WHERE "satellites"."obj_name" LIKE 'SENTINEL-%'
ORDER BY "launch_date" ASC;

-- Find ICESAT orbital params
SELECT * FROM "orbital_params" WHERE "satellite_id" = (
    SELECT "NORAD_ID" FROM "satellites" WHERE "obj_name" = 'ICESAT'
);

-- Find payload details of ICESAT
SELECT * FROM "sat_payload" WHERE "JCAT_ID" = (
    SELECT "JCAT_ID" FROM "satellites" WHERE "obj_name" = 'ICESAT'
);

-- Find LANDSAT 8 info
SELECT * FROM "satellite_info" WHERE "satellite_id" = (
    SELECT "NORAD_ID" FROM "satellites" WHERE "obj_name" = TRIM('LANDSAT 8')
);

-- Which manufacturers from U.S or Europe have built the most satellites ?
SELECT "manufacturer", COUNT("satellite_id") AS "Number of Satellites Built" FROM "satellite_info"
WHERE "object_type" = 'PAY' AND "country" = 'US' OR "country" = 'ESA'
GROUP BY "manufacturer"
ORDER BY "Number of Satellites Built" DESC LIMIT 4;



