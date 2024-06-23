# Understanding Customers' Demographics and Behaviour: Traveltide-Agency
## Project Overview

This data analysis project is aimed at assisting the Traveltide team develop an understanding of their customers in other to provide better service.

Traveltide Agency is an online travel industry. It has experienced steady growth since it was founded at the tail end of the covid pandemic (2021-04) on the strength of its data aggregation and search technology. 
The TravelTide team has recently shifted focus from aggressively acquiring new customers to better serving their existing customers. In order to achieve better service, the team recognizes that it is important to understand customer demographics and behavior.

## Data Sources
Please refer to the attached Microsoft Word document for the Entity Relationship Diagram and Data Dictionary 

## Tools
- Postgres SQL - Used for data analysis

## Data Analysis
Since the aim of this project is to better understand customers, The following questions were answered using POSTGRESQL:
1. Which cross-section of age and gender travels the most?

**Expected columns:** total_no_of_trips, age_group, gender.  
**Explanation:**  
1. Created a temporary table(CTE) named 'age_table' with columns no_of_trips, gender and age.
2. The 'no_of_trips' column is derived from using the COUNT function on the  'trip_id' column in the sessions table.
3. The 'age' column is derived from the 'birthdate' column in the users table using the DATE_PART function.
4. On the temporary table (age_table) created , ages are further grouped into age_groups using the CASE statement, no_of_trips are then summed up to get 'total_no_of_trips' column and grouped by 'age_group' and 'gender' in descending order. 
```sql
WITH age_table AS (
    SELECT 
        COUNT(sessions.trip_id) AS no_of_trips,
        users.gender,
        DATE_PART('year', CURRENT_DATE) - DATE_PART('year', users.birthdate) AS age
    FROM sessions
    LEFT JOIN users ON users.user_id = sessions.user_id
    GROUP BY
        users.gender,
        age
)
SELECT 
    SUM(no_of_trips) AS total_no_of_trips,
    CASE
        WHEN age BETWEEN 18 AND 24 THEN '18-24'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 44 THEN '35-44'
        WHEN age BETWEEN 45 AND 54 THEN '45-54'
        WHEN age BETWEEN 55 AND 64 THEN '55-64'
        WHEN age BETWEEN 65 AND 74 THEN '65-74'
        ELSE '75+'
    END AS age_group,
    gender
FROM 
    age_table
GROUP BY 
    age_group,
    gender
ORDER BY 
    total_no_of_trips DESC;
```
2. Calculate the proportion of sessions abandoned in summer months (June, July, August) and compare it to the proportion of sessions abandoned in non-summer months.
Abandoned session means browsing without booking anything.

**Expected columns:** summer_abandon_rate, other_abandon_rate.  
**Explanation:**  
1. A CTE named SessionByMonths was created.
2. It selects session_start (date of session column in the sessions table) and uses a CASE statement to categorize each session:.
3. If the month extracted from session_start is June (6), July (7) or August (8) and trip_id is NULL,  then it labels the session as 'summer'.
4. If the month is not June, July, or August and trip_id is NULL,  then it labels the session as 'other'.
5. The result is a temporary table with an additional column session_month indicating whether each session was abandoned in summer or other months.
6. trip_id is NULL because we are concerned with only abandoned sessions, that is, sessions that did not result to a booking and therefore has no associated trip_id.
7. On the temporary table (SessionByMonths) created, the abandonment rates for summer and other sessions are then calculated and rounded up by dividing the count of abandoned sessions by the total number of sessions for each period.

```sql
WITH SessionByMonths AS (
    SELECT
     session_id,session_start, 
        CASE
            WHEN EXTRACT(MONTH FROM session_start) IN (6, 7, 8) and trip_id IS NULL THEN 'summer'
  					WHEN EXTRACT(MONTH FROM session_start) NOT IN (6, 7, 8) and trip_id IS NULL THEN 'other'
        END AS session_month
    FROM sessions
)
SELECT 
    ROUND(SUM(CASE WHEN session_month = 'summer' THEN 1 ELSE 0 END) / (SUM(CASE WHEN EXTRACT (MONTH FROM session_start) IN (6, 7, 8) THEN 1 ELSE 0 END)::NUMERIC), 3) AS summer_abandon_rate,
    ROUND(SUM(CASE WHEN session_month = 'other' THEN 1 ELSE 0 END) /(SUM(CASE WHEN EXTRACT (MONTH FROM session_start) NOT IN (6, 7, 8) THEN 1 ELSE 0 END)::NUMERIC), 3) AS other_abandon_rate
FROM 
    SessionByMonths;
```
3. Return users who have booked and completed at least 10 flights, ordered by user_id.

**Expected column:** user_id.  
**Explanation:**  
1. Tables involved are the flights and sessions tables which are joined using LEFT JOIN and connected based on the trip_id column.
2. Using the WHERE function, cancelled flights are filtered out by setting cancellation = 'false'
3. Using the HAVING function, only users that have 10 or more flights are included.
4. The results are grouped by user_id and sorted in ascending order
```sql
SELECT 
    user_id
FROM
    flights
LEFT JOIN
    sessions ON sessions.trip_id = flights.trip_id
WHERE
    cancellation = 'false'
GROUP BY 
    user_id
HAVING 
    COUNT(flights.trip_id) >= 10
ORDER BY
    user_id;
```

4. Write a solution that will, for each user_id of users with greater than 10 flights, find out the largest window of days between the departure time of a flight and the departure time 
of the next departing flight taken by the user.

**Expected Columns**: user_id, biggest_window.  
**Explanation:**  
1. The first Common Table Expression (CTE1) select details of users who have taken more than 10 flights by retrieving the 'user_id', 'trip_id', and 'departure_time' from the flights table.
2. The sessions table is joined to the flights table on 'trip_id' using  the LEFT JOIN function.
3. A subquery is referenced in the WHERE clause to Filter only users (user_id) who have more than 10 flights using the HAVING statement.
4. The main reason for using the subquery is to filter the users based on aggregated data (i.e., the count of their trips) as you cannot directly use aggregate functions in the WHERE clause of the main query. You need to first compute the aggregated data, which is done in the subquery, and then use that result to filter the main query.
5. Results are then ordered user_id and departure_time.
6. The second Common Table Expression (CTE2) is used to calculate the gap in days between consecutive flights for each user by adding a new column 'time_difference_in_days' which calculates the difference in days between the current flight's departure_time and the previous flight's departure_time for each user.
7. This is achieved using the LAG window function to get the previous departure_time for the same user, ordered by departure_time.
8. Finally, to find the largest gap in days between consecutive flights for each user, we select user_id and the maximum value of time_difference_in_days for each user and group the results by user_id.

```sql
WITH cte AS (
    SELECT 
        user_id, 
        flights.trip_id,
        departure_time
    FROM
        flights
    LEFT JOIN
        sessions ON sessions.trip_id = flights.trip_id
    WHERE	
        user_id IN (
            SELECT 
                user_id 
            FROM
                flights
            LEFT JOIN
                sessions ON sessions.trip_id = flights.trip_id
            GROUP BY 
                user_id
            HAVING 
                COUNT(flights.trip_id) > 10
        )
    ORDER BY
        user_id, departure_time
),
cte2 AS (
    SELECT 
        *,
        departure_time::date - LAG(departure_time::date) OVER (PARTITION BY user_id ORDER BY departure_time) AS time_difference_in_days
    FROM 
        cte
)
SELECT 
    USER_ID, 
    MAX(time_difference_in_days) AS biggest_window
FROM 
    cte2
GROUP BY 
    USER_ID;
```

5. Find the user_ids of people whose origin airport is Boston (BOS) and whose first and last flight were to the same destination airport. Only include people who have flown out of Boston at least twice.
**Expected Columns:** user_id.
**Explanation:**
1.	The first CTE (CTE1)selects all flight details for users who departed from 'BOS' (Boston) and whose flights were not canceled. Only includes us  ers who have taken at least two non-canceled flights.
2.	The second CTE (CTE2) adds 2 ranking columns to each user's trips based on departure time, one rank (first_trip_rank) ranks departure from oldest to newest, in ascending order and the other (last_trip_rank) ranks from newest to oldest, in descending order for both the first and last trips.
3.	The final query Joins the CTE2 table to itself to find users where the destination of their first trip is the same as the destination of their last trip.
4.	The output retrieves user IDs of users whose first and last trip destinations are the same.
   
```sql
WITH CTE AS (
    SELECT 
        sessions.user_id, 
        flights.trip_id, 
        destination_airport, 
        departure_time 
    FROM 
        flights 
    JOIN 
        sessions ON flights.trip_id = sessions.trip_id 
    WHERE 
        origin_airport = 'BOS'  
        AND cancellation = 'false' 
        AND sessions.user_id IN (
            SELECT 
                sessions.user_id 
            FROM 
                flights 
            JOIN 
                sessions ON flights.trip_id = sessions.trip_id 
            WHERE 
                cancellation = 'false'         
            GROUP BY 
                sessions.user_id 
            HAVING 
                COUNT(flights.trip_id) >= 2
        ) 
    ORDER BY 
        user_id, departure_time
),
CTE2 AS (
    SELECT
        user_id,
        departure_time,
        destination_airport,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY departure_time) AS first_trip_rank,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY departure_time DESC) AS last_trip_rank
    FROM
        cte
)
SELECT
    t1.user_id
FROM
    CTE2 t1
JOIN
    CTE2 t2
ON
    t1.user_id = t2.user_id
WHERE
    t1.first_trip_rank = 1
    AND t2.last_trip_rank = 1
    AND t1.destination_airport = t2.destination_airport;
```
6.  How much session abandonment do we see? Session abandonment means they browsed but did not book anything.  
**Expected columns:** session_status, no_of_sessions.
**Explanation:**    
1. session_status: A CASE statement is used to assign 'abandoned' if trip_id is NULL, otherwise assigns 'trip_booked'.
2. no_of_sessions:This column counts the number of sessions for each session_status.
3. The result is grouped by the session_status category.
```sql
SELECT 
		CASE WHEN trip_id IS NULL THEN 'abandoned' ELSE 'trip_booked' END AS session_status,
    COUNT(session_id) AS no_of_sessions
FROM 
		sessions
GROUP BY 
		session_status;
```


## Results/Findings

1. Customers of age 34- 45 of all genders are the most travellers
2. Session abandonement is higher in non-summer months.

## Recommendations
1. Target High-Travel Demographics: Based on the first query, the travel company can focus its marketing efforts on the age and gender groups that travel the most, gearing promotions and offers towards these demographics.

2. Seasonal Marketing Strategies: The second query shows how session abandonment rates vary by season. The company can use this information to adjust its marketing strategies, offering promotions and incentives during periods of higher session abandonment rate, like the non-summer months, to encourage customers to complete their bookings.

3. Customer loyalty programs: The third query returns frequent flyers, a strategy to reward their loyalty can be put in place, such as exclusive discounts, upgrades, etc so as to retain their loyalty and not lose them to other competitors. 

