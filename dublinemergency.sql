/*==============================================================================
PROJECT: Dublin Emergency Services GIS
DATABASE: PostgreSQL + PostGIS

AUTHOR: Sreya Mohanan

DESCRIPTION
-----------
Spatial analysis of emergency incidents, hospital accessibility,
Fire station coverage and flood risk across Dublin City.

This script creates:

• Districts
• Hospitals
• Fire Stations
• Flood Zones

Coordinate System:
EPSG:4326 (WGS84)

==============================================================================*/


/*============================================================================
 Enable PostGIS
============================================================================*/

CREATE EXTENSION IF NOT EXISTS postgis;

/*============================================================================
Drop Existing Tables
============================================================================*/

DROP TABLE IF EXISTS incidents CASCADE;
DROP TABLE IF EXISTS flood_zones CASCADE;
DROP TABLE IF EXISTS fire_stations CASCADE;
DROP TABLE IF EXISTS hospitals CASCADE;
DROP TABLE IF EXISTS districts CASCADE;

/*============================================================================
Create Tables
===========================================================================*/

CREATE TABLE districts (
    district_id SERIAL PRIMARY KEY,
    district_name VARCHAR(100),
    population INT,
    geom GEOMETRY(POLYGON,4326)
);


CREATE TABLE hospitals (
    hospital_id SERIAL PRIMARY KEY,
    hospital_name VARCHAR(150),
    bed_capacity INT,
    geom GEOMETRY(POINT,4326)
);


CREATE TABLE fire_stations (
    station_id SERIAL PRIMARY KEY,
    station_name VARCHAR(150),
    crews INT,
    geom GEOMETRY(POINT,4326)
);


CREATE TABLE flood_zones (
    flood_id SERIAL PRIMARY KEY,
    risk_level VARCHAR(20),
    geom GEOMETRY(POLYGON,4326)
);


CREATE TABLE incidents (
    incident_id SERIAL PRIMARY KEY,
    incident_type VARCHAR(50),
    severity VARCHAR(20),
    incident_date DATE,
    geom GEOMETRY(POINT,4326)
);

/*============================================================================
Insert Dublin Districts
===========================================================================*/

INSERT INTO districts
(district_name, population, geom)

VALUES

(
'North Inner City',
85000,
ST_GeomFromText(
'POLYGON((
-6.31 53.36,
-6.22 53.36,
-6.22 53.40,
-6.31 53.40,
-6.31 53.36
))',4326)
),

(
'South Inner City',
92000,
ST_GeomFromText(
'POLYGON((
-6.31 53.32,
-6.22 53.32,
-6.22 53.36,
-6.31 53.36,
-6.31 53.32
))',4326)
),

(
'Dublin West',
115000,
ST_GeomFromText(
'POLYGON((
-6.42 53.32,
-6.31 53.32,
-6.31 53.40,
-6.42 53.40,
-6.42 53.32
))',4326)
),

(
'Dublin East',
78000,
ST_GeomFromText(
'POLYGON((
-6.22 53.32,
-6.11 53.32,
-6.11 53.40,
-6.22 53.40,
-6.22 53.32
))',4326)
);

/*============================================================================
Insert Hospitals
===========================================================================*/

INSERT INTO hospitals (hospital_name,bed_capacity,geom)
VALUES
('St James''s Hospital', 1010, ST_SetSRID(ST_MakePoint(-6.294,53.339),4326)),
('Mater Misericordiae University Hospital', 600, ST_SetSRID(ST_MakePoint(-6.264,53.359),4326)),
('Beaumont Hospital', 820, ST_SetSRID(ST_MakePoint(-6.223,53.389),4326)),
('Tallaght University Hospital', 640, ST_SetSRID(ST_MakePoint(-6.377,53.291),4326)),
('Connolly Hospital', 350, ST_SetSRID(ST_MakePoint(-6.379,53.389),4326));

/*============================================================================
Insert Fire Stations
===========================================================================*/

INSERT INTO fire_stations (station_name,crews,geom)
VALUES
('Tara Street Fire Station', 10, ST_SetSRID(ST_MakePoint(-6.252,53.347),4326)),
('Dolphin''s Barn Fire Station', 9, ST_SetSRID(ST_MakePoint(-6.292,53.336),4326)),
('Finglas Fire Station', 8, ST_SetSRID(ST_MakePoint(-6.298,53.390),4326)),
('Kilbarrack Fire Station', 8, ST_SetSRID(ST_MakePoint(-6.153,53.397),4326)),
('Tallaght Fire Station', 9, ST_SetSRID(ST_MakePoint(-6.374,53.286),4326));

/*============================================================================
Insert Flood Zones
===========================================================================*/

INSERT INTO flood_zones
(risk_level,geom)

VALUES

(
'High',
ST_GeomFromText(
'POLYGON((
-6.31 53.343,
-6.20 53.343,
-6.20 53.351,
-6.31 53.351,
-6.31 53.343
))',4326)
),

(
'Medium',
ST_GeomFromText(
'POLYGON((
-6.19 53.334,
-6.12 53.334,
-6.12 53.355,
-6.19 53.355,
-6.19 53.334
))',4326)
),

(
'High',
ST_GeomFromText(
'POLYGON((
-6.29 53.300,
-6.20 53.300,
-6.20 53.325,
-6.29 53.325,
-6.29 53.300
))',4326)
);

/*============================================================================
Generate_Incident_Data

DESCRIPTION
-----------
Generates 1,000 realistic emergency incidents across Dublin City.

Spatial Distribution
--------------------
• 40% City Centre
• 20% South Dublin
• 20% North Dublin
• 20% Random across Dublin

Time Period
-----------
2021 - 2025
===========================================================================*/

INSERT INTO incidents (incident_type, severity, incident_date, geom)
SELECT
    -- Incident Type
    CASE
        WHEN r1 < 0.35 THEN 'Medical'
        WHEN r1 < 0.55 THEN 'Road Traffic Collision'
        WHEN r1 < 0.72 THEN 'Crime'
        WHEN r1 < 0.87 THEN 'Fire'
        ELSE 'Flood Alert'
    END,

    -- Severity
    CASE
        WHEN r2 < 0.50 THEN 'Low'
        WHEN r2 < 0.85 THEN 'Medium'
        ELSE 'High'
    END,

    DATE '2021-01-01' + FLOOR(RANDOM() * 1825)::INT,
    ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)
FROM (
    SELECT
        RANDOM() AS r1,
        RANDOM() AS r2,
        
        -- Longitude regional probability
        CASE
            WHEN RANDOM() < 0.40 THEN -6.275 + RANDOM() * 0.05 -- Dublin City Centre (40%)
            WHEN RANDOM() < 0.60 THEN -6.330 + RANDOM() * 0.09 -- South Dublin (20%)
            WHEN RANDOM() < 0.80 THEN -6.320 + RANDOM() * 0.10 -- North Dublin (20%)
            ELSE -6.42 + RANDOM() * 0.31                       -- Anywhere in Dublin (20%)
        END AS longitude,
        
        -- Latitude regional probability
        CASE
            WHEN RANDOM() < 0.40 THEN 53.340 + RANDOM() * 0.03
            WHEN RANDOM() < 0.60 THEN 53.300 + RANDOM() * 0.05
            WHEN RANDOM() < 0.80 THEN 53.370 + RANDOM() * 0.05
            ELSE 53.28 + RANDOM() * 0.15
        END AS latitude
    FROM GENERATE_SERIES(1, 1000)
) x;

/*============================================================================
View and Verify Data 
===========================================================================*/

SELECT * FROM districts;
SELECT * FROM hospitals;
SELECT * FROM fire_stations;
SELECT * FROM flood_zones;
SELECT * FROM incidents;

/*============================================================================
Check Incident Types
===========================================================================*/

SELECT 
	incident_type,
	COUNT(*) AS total
FROM incidents
GROUP BY incident_type
ORDER BY total DESC;

/*============================================================================
Check Severity
===========================================================================*/

SELECT
	severity,
	COUNT(*)
FROM incidents
GROUP BY severity;

/*============================================================================
Check Date Distribution
===========================================================================*/

SELECT
EXTRACT(YEAR FROM incident_date) AS year,
COUNT(*)
FROM incidents
GROUP BY year
ORDER BY year;

/*============================================================================
Create a Spatial Index (Performance Improvement)
===========================================================================*/

CREATE INDEX idx_incidents_geom
ON incidents
USING GIST (geom);

CREATE INDEX idx_hospitals_geom
ON hospitals
USING GIST (geom);

CREATE INDEX idx_firestations_geom
ON fire_stations
USING GIST (geom);

CREATE INDEX idx_districts_geom
ON districts
USING GIST (geom);

CREATE INDEX idx_floodzones_geom
ON flood_zones
USING GIST (geom);

/*============================================================================
1. Calculate Area and Population Density of Each District
=============================================================================*/

SELECT
    district_name,
    population,

    -- Cast the area calculation to numeric
    ROUND(
        (ST_Area(geom::geography) / 1000000)::numeric,
        2
    ) AS area_sq_km,

    -- Cast the density calculation to numeric
    ROUND(
        (population / NULLIF(ST_Area(geom::geography) / 1000000, 0))::numeric,
        2
    ) AS population_density

FROM districts
ORDER BY population_density DESC;

/*============================================================================
2. Find Which District Each Hospital Belongs To
=============================================================================*/

SELECT
    d.district_name,
    h.hospital_name,
    h.bed_capacity
FROM districts d
JOIN hospitals h
	ON ST_Contains(d.geom,h.geom)
ORDER BY district_name;

/*============================================================================
3. Count Number of Incidents in Each District
=============================================================================*/

SELECT
    d.district_name,
    COUNT(i.incident_id) AS incidents
FROM districts d
LEFT JOIN incidents i
	ON ST_Within(i.geom,d.geom)
GROUP BY d.district_name
ORDER BY incidents DESC;

/*============================================================================
4. Find Top Districts with Highest Incident Density
=============================================================================*/

SELECT
    d.district_name,
    COUNT(i.incident_id) AS incidents,
    ROUND(
        COUNT(i.incident_id)::numeric / d.population *10000, 
		2
    ) AS incidents_per_10000
FROM districts d
LEFT JOIN incidents i
	ON ST_Within(i.geom,d.geom)
GROUP BY d.district_name, d.population
ORDER BY incidents_per_10000 DESC;

/*============================================================================
5. Create 1 KM Emergency Service Buffer Around Hospitals
=============================================================================*/

SELECT
	hospital_name,
	ST_Buffer(geom::geography, 1000)::geometry
FROM hospitals;

/*============================================================================
6. Find Incidents Within 1 KM of Any Hospital
=============================================================================*/

SELECT
    COUNT(DISTINCT i.incident_id) AS incidents_within_1km
FROM incidents i
JOIN hospitals h
    ON ST_DWithin(i.geom::geography, h.geom::geography, 1000);

/*============================================================================
7. Find Nearest Hospital For Every Incident
=============================================================================*/

SELECT
    i.incident_id,
    i.incident_type,
    nearest.hospital_name,
    ROUND(nearest.distance_m) AS distance_meters
FROM incidents i
CROSS JOIN LATERAL (
    SELECT
        hospital_name,
        ST_Distance(i.geom::geography, geom::geography) AS distance_m
    FROM hospitals
    ORDER BY i.geom <-> geom
    LIMIT 1
) nearest;

/*============================================================================
8. Find Incidents Occurring Inside Flood Zones
=============================================================================*/

SELECT
    i.incident_id,
    i.incident_type,
    i.severity,
    f.risk_level
FROM incidents i
JOIN flood_zones f
    ON ST_Intersects(i.geom, f.geom);

/*============================================================================
9. Count Flood Zone Overlaps by District
=============================================================================*/

SELECT
    d.district_name,
    COUNT(f.flood_id) AS flood_zones
FROM districts d
LEFT JOIN flood_zones f
    ON ST_Intersects(d.geom, f.geom)
GROUP BY d.district_name
ORDER BY flood_zones DESC;

/*============================================================================
10. Find Percentage of Incidents by District
=============================================================================*/

SELECT
    incident_type,
    COUNT(*) AS total,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM incidents),
        2
    ) AS percentage
FROM incidents
GROUP BY incident_type
ORDER BY total DESC;

/*============================================================================
11. Find High Severity Incidents
=============================================================================*/

SELECT *
FROM incidents
WHERE severity='High'
ORDER BY incident_date DESC;

/*============================================================================
12. Find Districts Without Hospitals
=============================================================================*/

SELECT
    d.district_name    
FROM districts d
LEFT JOIN hospitals h
    ON ST_Contains(d.geom, h.geom)
WHERE h.hospital_id IS NULL;

/*============================================================================
13. Find Fire Incidents During Last 3 Years
=============================================================================*/

SELECT *
FROM incidents
WHERE incident_type = 'Fire'
  AND incident_date >= CURRENT_DATE - INTERVAL '3 years';

/*============================================================================
14. Top 10 Most Common Incident Locations (Hotspot Clusters)
=============================================================================*/

WITH clusters AS (
    SELECT
        incident_id,
        ST_ClusterDBSCAN(geom, eps := 0.003, minpoints := 10) OVER() AS cluster_id
    FROM incidents
)
SELECT
    cluster_id,
    COUNT(*) AS incidents
FROM clusters
WHERE cluster_id IS NOT NULL
GROUP BY cluster_id
ORDER BY incidents DESC;

/*============================================================================
15. Create District Risk Score
=============================================================================*/

WITH incident_stats AS (
    SELECT
        d.district_id,
        COUNT(i.incident_id) AS incidents
    FROM districts d
    LEFT JOIN incidents i 
        ON ST_Within(i.geom, d.geom)
    GROUP BY d.district_id
),

flood_stats AS (
    SELECT
        d.district_id,
        COUNT(f.flood_id) AS floods
    FROM districts d
    LEFT JOIN flood_zones f 
        ON ST_Intersects(d.geom, f.geom)
    GROUP BY d.district_id
),

hospital_distance AS (
    SELECT
        d.district_id,
        AVG(ST_Distance(ST_Centroid(d.geom)::geography, h.geom::geography)) AS avg_distance
    FROM districts d
    CROSS JOIN hospitals h
    GROUP BY d.district_id
)

SELECT
    d.district_name,
    i.incidents,
    f.floods,
    ROUND(h.avg_distance) AS avg_distance_m,
    ROUND(
        (i.incidents * 0.5) + (f.floods * 20.0) + (h.avg_distance / 1000.0),
        2
    ) AS risk_score
FROM districts d
JOIN incident_stats i USING (district_id)
JOIN flood_stats f USING (district_id)
JOIN hospital_distance h USING (district_id)
ORDER BY risk_score DESC;

/*============================================================================
BONUS ANALYSIS
Creates reporting views for dashboards and business intelligence tools such as
Power BI, Tableau or QGIS.
=============================================================================*/

/*============================================================================
1. District Risk Dashboard
=============================================================================*/

CREATE OR REPLACE VIEW vw_district_risk AS
SELECT
    d.district_name,
    d.population,
    COUNT(i.incident_id) AS incident_count,
    COUNT(DISTINCT f.flood_id) AS flood_zone_count,
    ROUND(
        (COUNT(i.incident_id)::numeric / d.population * 10000),
        2
    ) AS incidents_per_10000
FROM districts d
LEFT JOIN incidents i 
    ON ST_Within(i.geom, d.geom)
LEFT JOIN flood_zones f 
    ON ST_Intersects(d.geom, f.geom)
GROUP BY 
    d.district_name, 
    d.population;

/*============================================================================
2. Nearest Hospital View
=============================================================================*/

CREATE OR REPLACE VIEW vw_nearest_hospital AS
SELECT
    i.incident_id,
    i.incident_type,
    i.severity,
    nearest.hospital_name,
    ROUND(nearest.distance_m) AS distance_meters
FROM incidents i
CROSS JOIN LATERAL (
    SELECT
        hospital_name,
        ST_Distance(i.geom::geography, geom::geography) AS distance_m
    FROM hospitals
    ORDER BY i.geom <-> geom
    LIMIT 1
) nearest;

/*============================================================================
3. Emergency Coverage View
=============================================================================*/

CREATE OR REPLACE VIEW vw_hospital_coverage AS
SELECT
    h.hospital_name,
    COUNT(i.incident_id) AS incidents_within_1km
FROM hospitals h
LEFT JOIN incidents i
    ON ST_DWithin(h.geom::geography, i.geom::geography, 1000)
GROUP BY h.hospital_name;

/*============================================================================
4. Fire Station Coverage
=============================================================================*/

CREATE OR REPLACE VIEW vw_fire_station_coverage AS
SELECT
    f.station_name,
    COUNT(i.incident_id) AS nearby_incidents
FROM fire_stations f
LEFT JOIN incidents i
    ON ST_DWithin(f.geom::geography, i.geom::geography, 1500)
GROUP BY f.station_name;

/*============================================================================
5. Flood Exposure View
=============================================================================*/

CREATE OR REPLACE VIEW vw_flood_exposure AS
SELECT
    risk_level,
    COUNT(i.incident_id) AS incidents
FROM flood_zones f
LEFT JOIN incidents i
    ON ST_Intersects(f.geom, i.geom)
GROUP BY risk_level;

/*============================================================================
6. Incident Trends by Year
=============================================================================*/

CREATE OR REPLACE VIEW vw_incident_trends AS
SELECT
    EXTRACT(YEAR FROM incident_date) AS year,
    incident_type,
    COUNT(*) AS incidents
FROM incidents
GROUP BY 
    EXTRACT(YEAR FROM incident_date), 
    incident_type
ORDER BY 
    year, 
    incident_type;

/*============================================================================
7. Emergency KPI Dashboard
=============================================================================*/

CREATE OR REPLACE VIEW vw_emergency_kpis AS
SELECT
    COUNT(*) AS total_incidents,
    
    COUNT(*) FILTER (WHERE severity = 'High') AS high_severity,
    COUNT(*) FILTER (WHERE incident_type = 'Medical') AS medical_incidents,
    
    ROUND(AVG(distance_meters)) AS average_distance_to_hospital
FROM vw_nearest_hospital;

/*============================================================================
8. Best Location for a New Hospital
=============================================================================*/

WITH district_score AS (
    SELECT
        d.district_id,
        d.district_name,
        COUNT(i.incident_id) AS incidents,
        AVG(ST_Distance(ST_Centroid(d.geom)::geography, h.geom::geography)) AS avg_distance
    FROM districts d
    LEFT JOIN incidents i 
        ON ST_Within(i.geom, d.geom)
    CROSS JOIN hospitals h
    GROUP BY 
        d.district_id,
        d.district_name,
        d.geom
)
SELECT
    district_name,
    incidents,
    ROUND(avg_distance) AS avg_distance_m
FROM district_score
ORDER BY
    incidents DESC,
    avg_distance DESC
LIMIT 3;

/*============================================================================
Useful Dashboard Queries
=============================================================================*/

/*============================================================================
Top 10 busiest days
=============================================================================*/

SELECT
    incident_date,
    COUNT(*) AS total_incidents
FROM incidents
GROUP BY incident_date
ORDER BY total_incidents DESC
LIMIT 10;

/*============================================================================
Monthly emergency trend
=============================================================================*/

SELECT
    DATE_TRUNC('month', incident_date) AS month,
    COUNT(*) AS incidents
FROM incidents
GROUP BY month
ORDER BY month;

/*============================================================================
Incident severity by district
=============================================================================*/

SELECT
    d.district_name,
    i.severity,
    COUNT(*) AS total_incidents
FROM districts d
JOIN incidents i 
    ON ST_Within(i.geom, d.geom)
GROUP BY 
    d.district_name, 
    i.severity
ORDER BY 
    d.district_name, 
    total_incidents DESC;

/*============================================================================
Average hospital bed capacity
=============================================================================*/

SELECT 
    ROUND(AVG(bed_capacity), 0) AS average_capacity
FROM hospitals;

/*============================================================================
End Report
=============================================================================*/
