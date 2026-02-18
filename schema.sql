CREATE TABLE "launch_vehicles" (
    "id" SERIAL PRIMARY KEY,
    "lv_name"  VARCHAR(32) NOT NULL UNIQUE,
    "lv_family" VARCHAR(32) NOT NULL,
    "lv_manufacturer" VARCHAR(16),
    "max_stage" smallint NOT NULL,
    "length_m" decimal(6,2),
    "diameter_m" decimal(5,2),
    "launch_mass_tonnes" decimal(6,2),
    "leo_capacity_kg" integer,
    "launch_thrust_kn" integer,
    "vehicle_class" char(1)

);


CREATE TABLE "launch_manifest" (
    "id" SERIAL PRIMARY KEY,
    "launch_tag" VARCHAR(16),
    "launch_date" VARCHAR(32) NOT NULL,
    "launch_site" VARCHAR(16),
    "launch_vehicle_id" INT,
    "agency" VARCHAR(16),
    CONSTRAINT "fk_launch_vehicle_id"
        FOREIGN KEY("launch_vehicle_id")
            REFERENCES "launch_vehicles"("id")
            ON DELETE RESTRICT

);

CREATE TABLE "satellites" (
    "NORAD_ID" INT PRIMARY KEY,
    "obj_name" VARCHAR(64) NOT NULL,
    "COSPAR_ID" VARCHAR(16) UNIQUE,
    "JCAT_ID" VARCHAR(8) NOT NULL UNIQUE,
    "launch_id" INT,
    CONSTRAINT "fk_launch_id"
        FOREIGN KEY("launch_id")
            REFERENCES "launch_manifest"("id")
            ON DELETE SET NULL
);

CREATE TYPE "type_of_orbit" AS ENUM('ORB', 'LAN', 'IMP', 'DOC', 'R/T');

CREATE TABLE "orbital_params" (
    "id" SERIAL PRIMARY KEY,
    "satellite_id" INT,
    "apogee_km" INT,
    "perigee_km" INT,
    "inclination_deg" NUMERIC(6,2),
    "period_minutes" NUMERIC(9,3),
    "orbit_center" VARCHAR(8),
    "orbit_class" VARCHAR(8),
    "orbit_type" "type_of_orbit",
    CONSTRAINT "fk_noradid1"
        FOREIGN KEY("satellite_id")
            REFERENCES "satellites"("NORAD_ID")
            ON DELETE CASCADE

);


CREATE TYPE "type_of_object" AS ENUM('PAY', 'R/B', 'DEB', 'UNK');

CREATE TABLE "satellite_info" (
    "id" SERIAL PRIMARY KEY,
    "satellite_id" INT,
    "country" VARCHAR(8) NOT NULL,
    "sat_owner" VARCHAR(32),
    "manufacturer" VARCHAR(16),
    "bus" VARCHAR(32),
    "total_mass_kg" decimal(9,2),
    "launch_site" VARCHAR(16) NOT NULL,
    "launch_date" DATE NOT NULL,
    "decay_date" DATE,
    "operational_status" CHAR(1),
    "object_type" "type_of_object" NOT NULL,
    CONSTRAINT "fk_noradid2"
        FOREIGN KEY("satellite_id")
            REFERENCES "satellites"("NORAD_ID")
            ON DELETE CASCADE

);


CREATE TABLE "sat_payload" (
    "PAY_ID" SERIAL PRIMARY KEY,
    "JCAT_ID" VARCHAR(8),
    "pl_name" VARCHAR(32),
    "transmission_end_date" VARCHAR(32),
    "program" VARCHAR(32),
    "category" VARCHAR(16),
    "result" CHAR(1),
    CONSTRAINT "fk_jcat"
        FOREIGN KEY("JCAT_ID")
            REFERENCES "satellites"("JCAT_ID")
            ON DELETE CASCADE
);

CREATE TEMPORARY TABLE "launch_staging" (
    "launch_tag" VARCHAR(16) NOT NULL,
    "launch_date" VARCHAR(32) NOT NULL,
    "launch_vehicle" VARCHAR(32) NOT NULL,
    "launch_site" VARCHAR(16),
    "agency" VARCHAR(16)

);

CREATE TEMPORARY TABLE "satcat_celestrak_staging" (
    "obj_name" VARCHAR(64) NOT NULL,
    "cospar_id" VARCHAR(16) NOT NULL,
    "norad_id" INT NOT NULL UNIQUE,
    "object_type" "type_of_object" NOT NULL,
    "ops_status" CHAR(1),
    "country" VARCHAR(8) NOT NULL,
    "launch_date" DATE NOT NULL,
    "launch_site" VARCHAR(16) NOT NULL,
    "decay_date" DATE,
    "period_min" NUMERIC(9,3),
    "inclination" NUMERIC(6,2),
    "apogee" INT,
    "perigee" INT,
    "orbit_center" VARCHAR(8),
    "orbit_type" "type_of_orbit"


);


CREATE TEMPORARY TABLE "satcat_staging" (
    "jcat_num" VARCHAR(8) NOT NULL UNIQUE,
    "norad_id" INT UNIQUE,
    "launch_tag" VARCHAR(16),
    "sat_owner" VARCHAR(32),
    "manufacturer" VARCHAR(16),
    "bus" VARCHAR(32),
    "total_mass" DECIMAL(9,2),
    "orbit_class" VARCHAR(8)


);

CREATE TEMPORARY TABLE "payload_staging" (
    "jcat" VARCHAR(8) NOT NULL UNIQUE,
    "pl_name" VARCHAR(32),
    "transmission_end_date" VARCHAR(32),
    "program" VARCHAR(32),
    "category" VARCHAR(16),
    "result" CHAR(1)
);

-- Add eccentricity column inside of orbital_params
ALTER TABLE "orbital_params"
ADD "eccentricity" real;


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
