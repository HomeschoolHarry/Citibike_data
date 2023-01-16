


---create Tables for all months (2019 and 2022)
create table cb_oct_2022 (
ride_id text,
rideable_type text,
started_at text,
ended_at text,
start_station_name text,
start_station_id text,
end_station_name text,
end_station_id text,
start_lat numeric,
start_lng numeric,
end_lat numeric,
end_lng numeric,
member_casual text
)

--Load or Copy data from each month

-- Union All months for 2019 and 2022 (manually adjust tables and names for each year)
create table cb_2022_NYC_FINAL as 
SELECT *
FROM public.cb_22_jan_nyc
	UNION ALL
SELECT *
FROM public.cb_22_feb_nyc
	UNION ALL
SELECT *
FROM public.cb_22_mar_nyc
	UNION ALL
SELECT *
FROM public.cb_22_apr_nyc
	UNION ALL
SELECT *
FROM public.cb_22_may_nyc
	UNION ALL
SELECT *
FROM public.cb_22_june_nyc
	UNION ALL
SELECT *
FROM public.cb_22_jul_nyc
	UNION ALL
SELECT *
FROM public.cb_22_aug_nyc
	UNION ALL
SELECT *
FROM public.cb_22_sep_nyc
	UNION ALL
SELECT *
FROM public.cb_22_oct_nyc
	UNION ALL
SELECT *
FROM public.cb_22_nov_nyc
	UNION ALL
SELECT *
FROM public.cb_22_dec_nyc

-- Check total count for each to make sure it migrates over

	--2019
	SELECT COUNT(*)
	FROM public.citibike_2019
	--393122
	
	--202
	SELECT COUNT(*)
	FROM public.citibike_2022
	-- 31585406
	
	SELECT 393122 + 31585406 --31978528
	
	
--because in change in reporting types, create new queiries that pull only relatable information between 2019 & 2022
--use those quesries to union all into master / cleaned table

CREATE TABLE citibike_19_20_final_cleaned AS
SELECT
SUBSTRING(start_station_id, 0, STRPOS(start_station_id, '.')) as start_station_id, -- text_type has decimals, rounded to integers, Jersey City data is text
start_station_name,
started_at as start_time,
SUBSTRING(end_station_id, 0, STRPOS(end_station_id, '.')) as end_station_id, -- text_type has decimals, rounded to integers, Jersey City data is text
end_station_name,
ended_at as stop_time,
CASE WHEN member_casual ILIKE 'member' THEN 'Subscriber' --adjusted to create new category member = subscriber, else non-member
	 WHEN member_casual ILIKE 'casual' THEN 'Non Member'
	 ELSE 'Unknown'
	 END AS membership
FROM public.citibike_2022
WHERE 
	rideable_type NOT ILIKE 'electric_bike' --electric bikes introduced May 2022 and is incomplete for comparison, pulled out to examine seperately
	OR start_station_name NOT LIKE null --any data missing from star or end station is incomplete trip
	OR end_station_name NOT LIKE NULL 
UNION ALL
SELECT 
SUBSTRING(start_station_id, 0, STRPOS(start_station_id, '.')) as start_station_id, -- text_type has decimals, rounded to integers, Jersey City data is text
start_station_name,
start_time,
SUBSTRING(end_station_id, 0, STRPOS(end_station_id, '.')) as end_station_id, -- text_type has decimals, rounded to integers, Jersey City data is text
end_station_name,
stop_time,
membership --2022 data was aliased in orde to match this value member/non member
FROM public.citibike_2019
WHERE 
	start_station_name NOT LIKE null --any data missing from star or end station is incomplete trip
	OR end_station_name NOT LIKE nULL 

-- Check for dropped rows
SELECT EXTRACT('YEAR' FROM start_time), COUNT(*)
FROM public.citibike_19_20_final_cleaned
GROUP BY 1

SELECT 23394797 + 393122 = 23787919 --2019 remains the same
SELECT 31585406 - 23787919 --7,797,487 ebike rides dropped from record

--counts all types
SELECT rideable_type, COUNT(*)
FROM public.citibike_2022
GROUP BY 1
--"classic_bike"	23119679
--"docked_bike"	275118
--"electric_bike"	8190609

SELECT 8190609 - 7797487 -- difference of 393122




-- CREATE NEW CATEGORY = Rider_type
-- Group the data by Unique Types
-- same start and end station = Casual Ride
-- dif start and end station = commute

CREATE TABLE citibike_master_load AS
SELECT
start_station_id,
start_station_name,
start_time,
end_station_id,
end_station_name,
stop_time,
membership,
CASE
	WHEN start_station_name LIKE end_station_name THEN 'Casual'
	WHEN start_station_name NOT LIKE end_station_name THEN 'Commuter'
	ELSE 'Commuter'
	END AS rider_type,
stop_time-start_time AS ride_time
FROM public.citibike_19_20_final_cleaned




-- CREATE MASTER STATION LIST
--		Grab all start_station_name, id, lat, long
--		remove duplicated (group)
--		spit out to excel and change types to below. Round lat and lon to 4 decimals

CREATE TABLE master_station_list_geo (
station_name text,
station_id text,
latitude numeric,
longitude numeric)
-- import CSV
SELECT COUNT(station_name)
FROM public.master_station_list_geo
--1858 stations

--create table with lat_long

CREATE TABLE geo_table as
SELECT
cm.start_station_id,
cm.start_station_name,
str.latitude as start_lat,
str.longitude as start_long,
cm.start_time,
cm.end_station_id,
cm.end_station_name,
en.latitude as end_lat,
en.longitude as end_long,
cm.stop_time,
cm.membership,
cm.ride_time
FROM public.citibike_master_load cm
	JOIN public.master_station_list_geo str ON cm.start_station_name = str.station_name
	JOIN public.master_station_list_geo en ON cm.end_station_name = en.station_name 

--GEOSPACIAL ADDITIONS, create final table for upload
-- EUCLIDEAN GEOMETRY
-- 		Longitude = X and Latitude = Y
-- 		Euclidean formula: distance = SQRT( POWER((X2 - X1),2)+POWER(Y2 - Y1),2))
-- 		reference https://www.cuemath.com/euclidean-distance-formula/
-- 		use radians() function on each lat/long
-- 		radius of the earth in miles is 3959
-- 		take final euclidean distance convert to radians () and multiply by 3959 to get distance in miles
-- MANHATTAN DISTANCE Distance
--		https://www.101computing.net/manhattan-distance-calculator/
-- 		ACOS( SIN(LAT1) * SIN(LAT2) + COS(LAT1)*COS(LAT2) * COS(LONG2 - LONG1)) * Radius
-- 		|x1-x2| + |y1-y2| = 
-- 		ALL results in KM: 1KM = .68 miles

CREATE TABLE citibike_final_geo as
SELECT
start_station_id,
start_station_name,
start_lat,
start_long,
start_time,
end_station_id,
end_station_name,
end_lat,
end_long,
stop_time,
membership,
ride_time,
SQRT( POWER(start_long - end_long, 2) + POWER(start_lat - end_lat, 2)) * 100 as euc_dist,
ROUND((ABS(start_long- end_long) + ABS(start_lat-end_lat)*1000)* 0.06214,4) as man_dist
FROM public.geo_table

--count of starts (trips)
SELECT start_station_id, start_station_name, COUNT(*)
FROM public.citibike_final_geo
GROUP BY 1, 2
--23,937,325


--count of starts (trips)
SELECT COUNT(start_station_name)
FROM public.citibike_final_geo
--23,937,325

-- geo added_load
SELECT COUNT(start_station_id)
FROM public.geo_table
-- 23,937,325

--clean load
SELECT COUNT(start_station_id)
FROM public.citibike_19_20_final_cleaned
-- 23,787,878

--count of starts (trips) --prev master
SELECT COUNT(start_station_id)
FROM public.citibike_master_load
-- 23,787,878

---REMOVED Start and end station ID 








--------ADDITIONAL FORMULAS FOR GEO CALCULATIONS NOT USED -------
/*SELECT
start_station_id,
start_station_name,
start_lat,
start_long,
start_time,
end_station_id,
end_station_name,
end_lat,
end_long,
stop_time,
membership,
ride_time,
SQRT
(POWER(
	(RADIANS(end_long)-RADIANS(start_long)), 2) 
 + POWER((RADIANS(end_lat)-RADIANS(start_lat)), 2))* 3959 as euc_dist,
ACOS(SIN(RADIANS(start_lat)) * SIN(RADIANS(end_lat))
		+ COS(RADIANS(start_lat))
		* COS(RADIANS(end_lat))
		* COS(RADIANS(end_long)-RADIANS(start_long))) * 3959 as man_dist
FROM public.geo_table
LIMIT 100

SELECT
ACOS(SIN(RADIANS(start_lat)) * 
		SIN(RADIANS(end_lat)) 
		+ COS(RADIANS(start_lat))
		* COS(RADIANS(end_lat))
		* COS(RADIANS(end_long)-RADIANS(start_long)) * 3959) as man_dist
FROM public.geo_table
LIMIT 100


--GEOSPACIAL ADDITIONS
-- EUCLIDEAN GEOMETRY
-- 		Euclidean formula: distance = SQRT( POWER((end_lat-start_lat),2)+POWER(end_lng-start_lng),2))
-- 		reference https://www.cuemath.com/euclidean-distance-formula/
-- 		use radians() function on each lat/long
-- 		radius of the earth in miles is 3959
-- 		take final euclidean distance convert to radians () and multiply by 3959 to get distance in miles
-- MANHATTAN DISTANCE Distance
--		ACOS(SIN(LAT1)*SIN(LAT2)) + COS (LAT1) * COS(LAT2) * COS(LONG2 - LONG1)) * Radius

CREATE TABLE 
SELECT
start_station_id,
start_station_name,
start_time,
end_station_id,
end_station_name,
stop_time,
membership,
ride_time,
(SELECT
SQRT
(POWER(
	(RADIANS(en.latitude)-RADIANS(str.latitude)), 2) 
 + POWER((RADIANS(en.longitude)-RADIANS(str.longitude)), 2))* 3959
FROM public.citibike_master_load cm
	JOIN public.master_station_list_geo str ON cm.start_station_name = str.station_name
	JOIN public.master_station_list_geo en ON cm.end_station_name = en.station_name
	GROUP BY 1) as euc_dist,
(SELECT 
		ACOS(SIN(RADIANS(str.latitude)) * 
		SIN(RADIANS(en.latitude)) 
		+ COS(RADIANS(str.latitude))
		* COS(RADIANS(en.latitude))
		* COS(RADIANS(en.longitude)-RADIANS(str.longitude)) * 3959)
FROM public.citibike_master_load cm
	JOIN public.master_station_list_geo str ON cm.start_station_name = str.station_name
	JOIN public.master_station_list_geo en ON cm.end_station_name = en.station_name 
	GROUP BY 1) as man_dist
FROM public.citibike_master_load 

(SELECT
SQRT
(POWER(
	(RADIANS(en.latitude)-RADIANS(str.latitude)), 2) 
 + POWER((RADIANS(en.longitude)-RADIANS(str.longitude)), 2))* 3959
FROM public.citibike_master_load cm
	JOIN public.master_station_list_geo str ON cm.start_station_name = str.station_name
	JOIN public.master_station_list_geo en ON cm.end_station_name = en.station_name) as euc_dist,
(SELECT str.station_name, en.station_name,
			ACOS(SIN(RADIANS(str.latitude)) * 
			SIN(RADIANS(en.latitude)) 
			+ COS(RADIANS(str.latitude))
			* COS(RADIANS(en.latitude))
			* COS(RADIANS(en.longitude)-RADIANS(str.longitude)) * 3959) as man_dist
FROM public.citibike_master_load cm
	JOIN public.master_station_list_geo str ON cm.start_station_name = str.station_name
	JOIN public.master_station_list_geo en ON cm.end_station_name = en.station_name) as man_dist
FROM public.citibike_master_load
LIMIT 10
 


 
--extra code, did not provide correct measurement
--Euclidean distance: code wrapped in radians, vs radian conversion prior to calculation
	 SELECT str.station_name, en.station_name,
	RADIANS(ACOS(SIN(str.latitude) * 
	SIN(en.latitude) 
	+ COS(str.latitude) 
	* COS(en.latitude) 
	* COS(en.longitude-str.longitude))) * 3959 as man_dist
	FROM public.citibike_master_load cm
		JOIN public.master_station_list_geo str ON cm.start_station_name = str.station_name
		JOIN public.master_station_list_geo en ON cm.end_station_name = en.station_name) as man_dist

-- Manhattan Distance: code wrapped in radians, vs radian conversion prior to calculation
	(SELECT
	(SQRT(POWER((RADIANS(en.latitude)-RADIANS(str.latitude), 2) + POWER((RADIANS(en.longitude)-RADIAN(str.longitude),2)))* 3959
	FROM public.citibike_master_load cm
		JOIN public.master_station_list_geo str ON cm.start_station_name = str.station_name
		JOIN public.master_station_list_geo en ON cm.end_station_name = en.station_name) as euc_dist,

	*/


	 












