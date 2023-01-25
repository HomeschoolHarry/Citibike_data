--Wrangle Data - pull limited columns from 2019 in order to union 2022, drop irrelavent data
--- create export file with retitiles colunmns and value types to union with 2022 on local host

-- create table for reference in query with just id and station name

SELECT COUNT(start_time)
FROM public.citibike_2019
--404947

SELECT COUNT(name)
FROM public.citibike_stations
WHERE name = null


SELECT COUNT(*)
FROM public.citibike_stations
WHERE id = 3183
LIMIT 100

SELECT distinct end_station_id
FROM public.citibike_2019
ORDER BY 1 DESC

SELECT DISTINCT start_station_id, end_station_id
FROM public.citibike_2019

SELECT *
FROM public.citibike_stations
ORDER BY 1 desc

-- CREATE NEW TABLE, save the conent and load into local host

SELECT cb.start_station_id::text, 
cs1.name as start_station_name,
start_time,
cb.end_station_id::text,
cs2.name as end_station_name,
stop_time,
CASE
	WHEN user_type ILIKE 'Subscriber' THEN 'Subscriber'
	WHEN user_type ILIKE 'Customer' THEN 'Non Member'
	ELSE 'Unknown'
	END AS membership
FROM public.citibike_2019 as cb 
	JOIN public.citibike_stations as cs1 
	ON cb.start_station_id = cs1.id
	JOIN public.citibike_stations as cs2
	ON cb.end_station_id = cs2.id
WHERE cs1.id IN (start_station_id)



---

SELECT start_station_id,
(
	SELECT cs.name
	FROM public.citibike_2019 as cb
	JOIN public.citibike_stations as cs
	ON cb.start_station_id = cs.id
	GROUP BY 1
) as start_station_name,
start_time,
end_station_id,
(
	SELECT cs.name
	FROM public.citibike_2019 as cb
	JOIN public.citibike_stations as cs
	ON cb.start_station_id = cs.id
	GROUP BY 1
) as end_station_name,
stop_time,
user_type
FROM public.citibike_2019



-- check names vs id
SELECT end_station_id, cs.name
FROM public.citibike_2019 as cb 
	JOIN public.citibike_stations as cs 
	ON cb.start_station_id = cs.id
GROUP BY 2, 1





/*
Business Issues: Direct Questions 
(Data Exploration, Answer First, copy to PGAdmin)
-	Expansion Engineering
o	Are there business or Tourists hubs that suggest locations for adding stations?
	What are the estimated costs and revenues based on the location?
	What’s the estimated break even?
-	Post COVID
o	Pre and post patterns based on 
	year over year metric on volume
	customer type (M/F)
	customer type (subscriber vs guest)
	supply & demand (bikes leaving vs returning)
o	Broaden activity level? Meaning ways to increase ridership?
-	Product Availability
o	Rider Patterns Types
	Temporal Patterns (spikes in days, times, weekends, hubs, etc)
	Examples: Supply and Demand at Each Station
	Number of stations with start = end locations
•	Ave Trip Time/Duration
	1 Way Routes: start_station != end_station
•	Ave Trip Time/Duration
•	Ave Length/Distance traveled
-	Conversion Campaign Incentives
o	What can we glean from gender and subscription models?
o	Which makes more money? Overlap pricing from that year with riding metrics
o	Rider Demographics: 
	Limitations of defining tourists, working commuters or residents. 
o	Assumptions to Pursue: Are Subscription models (frequency x lower rate) more profitable than Short Term guest or customer (24h or 3 day passes)?
*/



-- total bike and station counts between years




-- get list of stations to export and map

SELECT *
FROM baywheels_stations as s


--total rows (trips) in baywheels 19
SELECT COUNT(*)
FROM baywheels_2019
-- 2,506,983


--trip length between station id's

SELECT bw19.start_station_id, (end_time-start_time) AS ttl_trip_time, bw19.end_station_id
FROM baywheels_2019 as bw19
	JOIN baywheels_stations AS bws ON bws.id = bw19.start_station_id
	JOIN baywheels_stations AS bws2 ON bws2.id = bw19.end_station_id
LIMIT 200

--# of trips where start station = end station
SELECT COUNT(*)
FROM baywheels_2019 as bw19
	JOIN baywheels_stations AS bws ON bws.id = bw19.start_station_id
	JOIN baywheels_stations AS bws2 ON bws2.id = bw19.end_station_id
WHERE bw19.start_station_id != bw19.end_station_id;
--2,167,348 (86% of trips return to same station).

-- ave trip time on the same vs dif station
SELECT AVG(end_time-start_time) AS  ave_ttl_trip_time_same_station
FROM baywheels_2019 as bw19
	JOIN baywheels_stations AS bws ON bws.id = bw19.start_station_id
	JOIN baywheels_stations AS bws2 ON bws2.id = bw19.end_station_id
WHERE bw19.start_station_id != bw19.end_station_id;
--12:59.53

-- ave trip time on the same vs same station
SELECT AVG(end_time-start_time) AS  ave_ttl_trip_time_same_station
FROM baywheels_2019 as bw19
	JOIN baywheels_stations AS bws ON bws.id = bw19.start_station_id
	JOIN baywheels_stations AS bws2 ON bws2.id = bw19.end_station_id
WHERE bw19.start_station_id = bw19.end_station_id;
--35:36.98

-- group by user type Customer
SELECT 
	AVG(same_station.ave_ttl_trip_time_same_station) AS ave_time_same_station_customer,
	AVG(dif_station.ave_ttl_trip_time_dif_station) AS ave_time_dif_station_customer
FROM
(SELECT AVG(end_time-start_time) AS ave_ttl_trip_time_same_station
FROM baywheels_2019 as bw19
	JOIN baywheels_stations AS bws ON bws.id = bw19.start_station_id
	JOIN baywheels_stations AS bws2 ON bws2.id = bw19.end_station_id
WHERE 
 	bw19.start_station_id = bw19.end_station_id
	AND bw19.user_type = 'Customer') AS same_station,

(SELECT AVG(end_time-start_time) AS ave_ttl_trip_time_dif_station
FROM baywheels_2019 as bw19
	JOIN baywheels_stations AS bws ON bws.id = bw19.start_station_id
	JOIN baywheels_stations AS bws2 ON bws2.id = bw19.end_station_id
WHERE 
 	bw19.start_station_id != bw19.end_station_id 
	AND bw19.user_type = 'Customer') AS dif_station
--customer same station = 46:49.75 AND dif stations = 21:04.09

-- group by user type Subscriber
SELECT 
	AVG(same_station.ave_ttl_trip_time_same_station) AS ave_time_same_station_subscriber,
	AVG(dif_station.ave_ttl_trip_time_dif_station) AS ave_time_dif_station_subscriber
FROM
(SELECT AVG(end_time-start_time) AS ave_ttl_trip_time_same_station
FROM baywheels_2019 as bw19
	JOIN baywheels_stations AS bws ON bws.id = bw19.start_station_id
	JOIN baywheels_stations AS bws2 ON bws2.id = bw19.end_station_id
WHERE 
 	bw19.start_station_id = bw19.end_station_id
	AND bw19.user_type = 'Subscriber') AS same_station,

(SELECT AVG(end_time-start_time) AS ave_ttl_trip_time_dif_station
FROM baywheels_2019 as bw19
	JOIN baywheels_stations AS bws ON bws.id = bw19.start_station_id
	JOIN baywheels_stations AS bws2 ON bws2.id = bw19.end_station_id
WHERE 
 	bw19.start_station_id != bw19.end_station_id 
	AND bw19.user_type = 'Subscriber') AS dif_station
--subscriber same station = 24:14.76 AND dif stations = 11:03.81

--Double Check Total Rides by user_type
SELECT user_type, COUNT(*)
FROM baywheels_2019
GROUP BY user_type
-- 485,817: Customer
-- Subscriber: 2,021,166

SELECT COUNT(user_type)
FROM baywheels_2019
--2,506,983 matches total


--# of trips starting_ending from each station
--START AND END ARE SAME< think of different approach
SELECT bw19.bike_id,
	bws.id, 
	bws.latitude, 
	bws.longitude, 
	bws.name, 
	COUNT(bw19.start_station_id) as num_start_trips, 
	COUNT(bw19.end_station_id) as num_end_trips
FROM baywheels_2019 as bw19
	JOIN baywheels_stations AS bws ON bws.id = bw19.start_station_id
	JOIN baywheels_stations AS bws2 ON bws2.id = bw19.end_station_id
GROUP BY 1,2
-- export to excel

-- list of most popular start stations


--# of trips starting_ending from each station
SELECT bw19.start_station_id, COUNT(bw19.start_station_id), bws.latitude, bws.longitude
FROM baywheels_2019 as bw19
	JOIN baywheels_stations AS bws ON bws.id = bw19.start_station_id
	JOIN baywheels_stations AS bws2 ON bws2.id = bw19.end_station_id
WHERE bw19.start_station_id = bw19.end_station_id
GROUP BY 1, 3, 4
-- export to excel

-- look at ONLY the routes with different start and end ID
SELECT bw19.start_station_id, bw19.end_station_id, bw19.user_type, bw19.bike_share_for_all_trip 
FROM baywheels_2019 as bw19
	JOIN baywheels_stations AS bws ON bws.id = bw19.start_station_id
	JOIN baywheels_stations AS bws2 ON bws2.id = bw19.end_station_id
WHERE bw19.start_station_id != bw19.end_station_id
-- 2,167,348

-- bike share for all trip = did the bike get 
-- them from A to B or did they mix with other form of transportation?


