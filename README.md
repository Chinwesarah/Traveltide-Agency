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

Expected columns: total_no_of_trips, age_group, gender.
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

Expected columns: summer_abandon_rate, other_abandon_rate.
```sql
WITH SessionByMonths AS (
    SELECT
     session_id,session_start, session_end,
        CASE
            WHEN EXTRACT(MONTH FROM session_start) IN (6, 7, 8) and trip_id IS NULL THEN 'summer'
  					WHEN EXTRACT(MONTH FROM session_start) NOT IN (6, 7, 8) and trip_id IS NULL THEN 'other'
        END AS session_month
    FROM sessions
  	ORDER BY session_end DESC
)
SELECT 
    ROUND(SUM(CASE WHEN session_month = 'summer' THEN 1 ELSE 0 END) / (SUM(CASE WHEN EXTRACT (MONTH FROM session_END) IN (6, 7, 8) THEN 1 ELSE 0 END)::NUMERIC), 3) AS summer_abandon_rate,
    ROUND(SUM(CASE WHEN session_month = 'other' THEN 1 ELSE 0 END) /(SUM(CASE WHEN EXTRACT (MONTH FROM session_END) NOT IN (6, 7, 8) THEN 1 ELSE 0 END)::NUMERIC), 3) AS other_abandon_rate
FROM 
    SessionByMonths;
```
3. Return users who have booked and completed at least 10 flights, ordered by user_id.

Expected column: user_id.
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

Expected Columns: user_id, biggest_window.

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
Expected Columns: user_id.
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


#### Note: Kindly refer to the attached SQL file for more questions and answers.

## Results/Findings

1. Customers of age 34- 45 of all genders are the most travellers
2. Session abandonement is higher in non-summer months.

## Recommendations
1. Target High-Travel Demographics: Based on the first query, the travel company can focus its marketing efforts on the age and gender groups that travel the most, gearing promotions and offers towards these demographics.

2. Seasonal Marketing Strategies: The second query shows how session abandonment rates vary by season. The company can use this information to adjust its marketing strategies, offering promotions and incentives during periods of higher session abandonment rate, like the non-summer months, to encourage customers to complete their bookings.

3. Customer loyalty programs: The third query returns frequent flyers, a strategy to reward their loyalty can be put in place, such as exclusive discounts, upgrades, etc so as to retain their loyalty and not lose them to other competitors. 

