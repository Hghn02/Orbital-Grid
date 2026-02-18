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

UPDATE "orbital_params"
SET "eccentricity" = ABS(ROUND(((6378.0 + "apogee_km") - (6378.0 + "perigee_km")) / ((6378.0 + "apogee_km") + (6378.0 + "perigee_km")),4));
