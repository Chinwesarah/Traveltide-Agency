{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang2057{\fonttbl{\f0\fmodern\fprq1\fcharset0 Courier New;}{\f1\fnil\fcharset0 Courier New;}{\f2\fnil\fcharset0 Calibri;}}
{\*\generator Riched20 10.0.22621}\viewkind4\uc1 
\pard\widctlpar\b\f0\fs22 --Question 1. Session Analysis\b0\par
\b /*1a. How much session abandonment do we see? Session abandonment means they browsed but did not book anything. Expected columns: session_status, no_of_sessions.*/\b0\par
\par
SELECT \par
\tab\tab CASE WHEN trip_id IS NULL THEN 'abandoned' ELSE 'trip_booked' END AS session_status,\par
    COUNT(session_id) AS no_of_sessions\par
FROM \par
\tab\tab sessions\par
GROUP BY \par
\tab\tab session_status;\par
\b\par
\par
/*1b. Which demographics abandon sessions the most?*/\par
\par
/*Age demographic: Answer - 18 -24 years\par
Expected columns: avg_session_abandonment_rate, age_group*/\par
\b0\par
WITH abandoned_sessions_table AS (\par
    SELECT \par
        DATE_PART('year', CURRENT_DATE) - DATE_PART('year', users.birthdate) AS age,\par
        ROUND(SUM(CASE WHEN trip_id IS NULL THEN 1 ELSE 0 END) / COUNT(session_id)::numeric, 3) AS session_abandonment_rate\par
    FROM \par
        sessions\par
    LEFT JOIN \par
        users ON sessions.user_id = users.user_id\par
    GROUP BY \par
        age\par
)\par
\par
SELECT \par
    ROUND(AVG(session_abandonment_rate), 3) AS avg_session_abandonment_rate,\par
    CASE\par
        WHEN age BETWEEN 18 AND 24 THEN '18-24'\par
        WHEN age BETWEEN 25 AND 34 THEN '25-34'\par
        WHEN age BETWEEN 35 AND 44 THEN '35-44'\par
        WHEN age BETWEEN 45 AND 54 THEN '45-54'\par
        WHEN age BETWEEN 55 AND 64 THEN '55-64'\par
        WHEN age BETWEEN 65 AND 74 THEN '65-74'\par
        ELSE '75+'\par
    END AS age_group\par
FROM \par
    abandoned_sessions_table\par
GROUP BY \par
    age_group;\par
ORDER BY \par
    avg_session_abandonment_rate DESC;\par
\par
\b /*Gender demographic:Answer - Female\par
Expected columns: gender, session_abandonement_rate*/\b0\par
\par
SELECT \par
\tab\tab users.gender,\par
    ROUND(SUM(CASE WHEN trip_id IS NULL THEN 1 ELSE 0 END) / COUNT(session_id)::numeric, 3) AS session_abandonment_rate\par
FROM \par
\tab\tab sessions\par
LEFT JOIN \par
    users ON sessions.user_id = users.user_id\par
GROUP BY \par
\tab\tab users.gender\par
ORDER BY\par
\tab\tab session_abandonment_rate DESC;\par
\b\par
/*Married and 'has children' demographic: Answer: Single with children. \par
Expected columns: married, has_children, session_abandonement_rate.*/\par
\b0\par

\pard SELECT\par
    users.married,\par
    users.has_children,\par
    ROUND(SUM(CASE WHEN trip_id IS NULL THEN 1 ELSE 0 END) / COUNT(*)::numeric, 3) AS session_abandonment_rate\par
FROM\par
    sessions\par
JOIN\par
    users ON sessions.user_id = users.user_id\par
GROUP BY\par
   \par
    users.married,\par
    users.has_children\par
ORDER BY \par
\tab\tab session_abandonment_rate DESC;\par
\f1\par
\par
\b --Question 2:\par
/*Write a solution to report the trip_id of sessions where:\par
\par
1. session resulted in a booked flight\par
2. booking occurred in May, 2022\par
3. booking has the maximum flight discount on that respective day.\par
\par
If in one day there are multiple such transactions, return all of them. Expected column:trip_id.\par
*/\b0\par
\par
WITH CTE AS (\par
    SELECT\par
        trip_id, \par
        session_start, \par
        flight_discount_amount,\par
        RANK() OVER (PARTITION BY session_start::date ORDER BY flight_discount_amount DESC) AS RANK\par
    FROM\par
        sessions\par
    WHERE\par
        flight_discount_amount IS NOT NULL AND\par
        flight_booked = 'true' AND\par
        EXTRACT(MONTH FROM session_start) = 5 AND\par
        EXTRACT(YEAR FROM session_start) = 2022\par
)\par
\par
SELECT \par
    trip_id\par
FROM\par
    CTE\par
WHERE\par
    RANK = 1\par
ORDER BY\par
    trip_id;\par
\par
\par
\par
\b --Question 3: \par
/*Find the user_ids of people whose origin airport is Boston (BOS) \par
and whose first and last flight were to the same destination airport. \par
Only include people who have flown out of Boston at least twice.\par
Expected Columns: user_id.\par
*/\b0\par
\par
WITH CTE AS (\par
    SELECT \par
        sessions.user_id, \par
        flights.trip_id, \par
        destination_airport, \par
        departure_time \par
    FROM \par
        flights \par
    JOIN \par
        sessions ON flights.trip_id = sessions.trip_id \par
    WHERE \par
        origin_airport = 'BOS'  \par
        AND cancellation = 'false' \par
        AND sessions.user_id IN (\par
            SELECT \par
                sessions.user_id \par
            FROM \par
                flights \par
            JOIN \par
                sessions ON flights.trip_id = sessions.trip_id \par
            WHERE \par
                cancellation = 'false'         \par
            GROUP BY \par
                sessions.user_id \par
            HAVING \par
                COUNT(flights.trip_id) >= 2\par
        ) \par
    ORDER BY \par
        user_id, departure_time\par
),\par
CTE2 AS (\par
    SELECT\par
        user_id,\par
        departure_time,\par
        destination_airport,\par
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY departure_time) AS first_trip_rank,\par
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY departure_time DESC) AS last_trip_rank\par
    FROM\par
        cte\par
)\par
SELECT\par
    t1.user_id\par
FROM\par
    CTE2 t1\par
JOIN\par
    CTE2 t2\par
ON\par
    t1.user_id = t2.user_id\par
WHERE\par
    t1.first_trip_rank = 1\par
    AND t2.last_trip_rank = 1\par
    AND t1.destination_airport = t2.destination_airport;\par
\par
\par

\pard\sa200\sl276\slmult1\f2\lang9\par
}
 