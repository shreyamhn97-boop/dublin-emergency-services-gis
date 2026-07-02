# dublin-emergency-services-gis
Spatial analysis of emergency incidents, hospital accessibility, fire station coverage, and flood risk in Dublin City using PostgreSQL and PostGIS.

## Project Overview

This project demonstrates how PostgreSQL and PostGIS can be used to perform advanced Geographic Information System (GIS) analysis for emergency service planning in Dublin City, Ireland. 
The database models hospitals, fire stations, flood-prone areas, and emergency incidents to answer real-world spatial business questions such as:

- Which hospital is closest to an emergency?
- Which districts have the highest emergency demand?
- Which incidents occur inside flood-risk areas?
- Where should a new emergency facility be located?
- Which districts have the highest overall risk?

The project combines spatial SQL techniques with business-oriented analytics that could support emergency planning and urban decision-making.

## Technologies

- PostgreSQL
- PostGIS
- SQL
- Spatial SQL
- GIS
- Geographic Coordinate Systems (EPSG:4326)

## Database Model

The project consists of five spatial tables.

| Table | Description |
|-------|-------------|
| `districts` | Stores simplified Dublin administrative district polygons and population data. |
| `hospitals` | Stores hospital locations, bed capacity, and spatial coordinates. |
| `fire_stations` | Stores Dublin Fire Brigade station locations and crew information. |
| `flood_zones` | Stores flood-risk polygons classified by risk level. |
| `incidents` | Stores emergency incidents with type, severity, date, and geographic location. |

## Features - Spatial Analysis

- Point-in-Polygon Analysis
- Nearest Neighbour Search
- Buffer Analysis
- Flood Risk Assessment
- Spatial Joins
- Geographic Distance Calculations
- Hotspot Detection (DBSCAN)
- Emergency Coverage Analysis
- District Risk Scoring

## Business Questions Answered
The project answers fifteen practical GIS questions.

- Population density by district
- Hospital locations within districts
- Incident count by district
- Incident rate per 10,000 residents
- Hospital service coverage
- Incidents within 1 km of hospitals
- Nearest hospital to every incident
- Incidents inside flood zones
- Flood exposure by district
- Incident type distribution
- High-severity incidents
- Districts without hospitals
- Fire incidents in the last three years
- Emergency hotspot clusters
- District emergency risk score

## Reporting Views

The project creates reusable SQL views for dashboards.
- District Risk Dashboard
- Hospital Coverage Dashboard
- Fire Station Coverage Dashboard
- Flood Exposure Dashboard
- Incident Trend Dashboard
- Emergency KPI Dashboard

## Example Analysis

Find the nearest hospital for every emergency

```sql
SELECT
    i.incident_id,
    nearest.hospital_name,
    ROUND(nearest.distance_m) AS distance_meters
FROM incidents i
CROSS JOIN LATERAL
(
    SELECT
        hospital_name,
        ST_Distance(
            i.geom::geography,
            geom::geography
        ) AS distance_m
    FROM hospitals
    ORDER BY i.geom <-> geom
    LIMIT 1
) nearest;
```
