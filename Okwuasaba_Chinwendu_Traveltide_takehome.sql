--1a. Which cross-section of age and gender travels the most?
SELECT 
		COUNT(sessions.trip_id) AS no_of_trips,
    users.gender,
    DATE_PART('year', CURRENT_DATE) - DATE_PART('year', users.birthdate) AS age
FROM sessions
		LEFT JOIN users ON users.user_id = sessions.user_id
GROUP BY
		users.gender,
    age
ORDER BY 
    no_of_trips DESC;


--1b. How does the travel behavior of customers married with children compare to childless single customers?
/*In the 2 groups,we are comparing the:
total sessions 
average page clicks 
what percentage of the sessions resulted to a flight and hotel booking
what percentage cancelled
average trip duration*/
SELECT
    CASE WHEN married AND has_children = true THEN 'married_with_children'
    ELSE 'single_and_childless' END AS marital_parental_status,
    COUNT(session_id) AS total_sessions,
    SUM(sessions.page_clicks) AS total_page_clicks,
    ROUND(AVG(sessions.page_clicks), 2) AS avg_page_clicks,
    ROUND(AVG(CASE WHEN sessions.hotel_booked = 'true' THEN 1 ELSE 0 END),2)*100 AS percentage_hotel_booked,
    ROUND(AVG(CASE WHEN sessions.flight_booked = 'true' THEN 1 ELSE 0 END),2)*100 AS percentage_flight_booked,
    ROUND(AVG(CASE WHEN sessions.cancellation = 'true' THEN 1 ELSE 0 END), 4)*100 AS percentage_cancellation,
    ROUND(AVG(EXTRACT(EPOCH FROM (return_time - departure_time)) / 86400), 2) AS avg_trip_duration_in_days 
FROM
    sessions
LEFT JOIN
    users ON users.user_id = sessions.user_id
LEFT JOIN
    flights ON sessions.trip_id = flights.trip_id
GROUP BY
   marital_parental_status


--2a. How much session abandonment do we see? Session abandonment means they browsed but did not book anything.

SELECT 
		CASE WHEN flight_booked AND hotel_booked = 'false' THEN 'abandoned' ELSE 'trip_booked' END AS session_status,
    COUNT(session_id) AS no_of_sessions
FROM 
		sessions
GROUP BY 
		session_status


--2b. Which demographics abandon sessions disproportionately more than average?
/*Gender demographic: No disproportionality seen*/
SELECT 
		users.gender,
    COUNT(session_id) AS no_of_sessions,
	  CASE WHEN flight_booked AND hotel_booked = 'false' THEN 'abandoned' ELSE 'trip_booked' END AS session_status   
FROM 
		sessions
LEFT JOIN 
    users ON sessions.user_id = users.user_id
GROUP BY 
		users.gender, session_status

/*Age demographic*/
WITH new_table AS (SELECT 
                       DATE_PART('year', CURRENT_DATE) - DATE_PART('year', users.birthdate) AS age,
                       COUNT(session_id) AS no_of_sessions,
	                     CASE WHEN flight_booked AND hotel_booked = 'false' THEN 'abandoned' 
                       ELSE 'trip_booked' END AS session_status   
                   FROM 
		                   sessions
LEFT JOIN 
       users ON sessions.user_id = users.user_id
GROUP BY 
		   Age, session_status)
    
SELECT 
		age,
		ROUND((SUM(CASE WHEN session_status = 'abandoned' THEN no_of_sessions ELSE 0 END) / SUM(no_of_sessions)),5)  AS avg_no_of_session_abandonement   
FROM
		new_table
GROUP BY
		age
ORDER BY 
    avg_no_of_session_abandonement DESC;




--3a. Explore how customer origin (e.g. home city) influences travel preferences.
/*We want to compare the folowing:
--total number of trips
--average trip duration
--total number of customers per home_city that booked return flight and hotel
--average cost spent on hotel per night(first, we modify the hotel table to change the rows with 0 nights to 1 night)*/

WITH new_hotel_table AS (
    SELECT 
         trip_id, 
         hotel_name,
         CASE WHEN nights= 0 THEN 1 ELSE nights END AS nights, 
         rooms,
         hotel_per_room_usd
				 FROM hotels
)
SELECT
		home_city,
		COUNT(flights.trip_id) AS total_no_of_trips,
    AVG(DATE_PART('day', RETURN_TIME - departure_time)) AS avg_trip_duration_days,
		SUM(CASE WHEN return_flight_booked = 'true' THEN 1 ELSE 0 END) AS total_return_flight_booked,
		SUM(CASE WHEN hotel_booked = 'true' THEN 1 ELSE 0 END) AS total_hotel_booked,
  	AVG(new_hotel_table.hotel_per_room_usd/new_hotel_table.nights)  AS avg_hotel_cost_per_night              

FROM
    flights
LEFT JOIN
    sessions ON sessions.trip_id = flights.trip_id
LEFT JOIN
    users ON users.user_id = sessions.user_id
LEFT JOIN 
    new_hotel_table ON new_hotel_table.trip_id = flights.trip_id		
GROUP BY
		home_city                       
ORDER BY 
		total_no_of_trips  DESC
		
GROUP BY
		home_city, destination



/*3a. Here we compare the 2 most popular trip destinations of customers per home_city*/

WITH Destination_ranking AS (
    SELECT
        users.home_city,
        flights.destination,
        COUNT(flights.trip_id) AS total_no_of_trips,
        ROW_NUMBER() OVER (PARTITION BY users.home_city ORDER BY COUNT(flights.trip_id) DESC) AS rank
    FROM
        flights 
    LEFT JOIN
  			sessions ON flights.trip_id = sessions.trip_id
    LEFT JOIN
    		users ON sessions.user_id = users.user_id
    GROUP BY
        users.home_city, flights.destination
)
SELECT
    home_city,
    destination,
    total_no_of_trips,
    rank
FROM
    Destination_ranking
WHERE
    rank = 1 OR rank = 2;


--4a.Can you make any strategic recommendations based on your answers to the questions above?
/*Based on all the analysis carried out, what really stand out are the top 2 most popular travel destinations for customers from different home cities(new york and los angeles) and the age range of both females and males that travel the most(ages 37 - 46) These information can help guide marketing strategies*/

