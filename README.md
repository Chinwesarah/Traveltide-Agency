# Understanding customer demographics and behaviour: Traveltide-Agency
## Project Overview

This data analysis project is aimed at assisting the Traveltide team develop an understanding of their customers in other to provide better service.

Traveltide Agency is an online travel industry. It has experienced steady growth since it was founded at the tail end of the covid pandemic (2021-04) on the strength of its data aggregation and search technology. 
The TravelTide team has recently shifted focus from aggressively acquiring new customers to better serving their existing customers. In order to achieve better service, the team recognizes that it is important to understand customer demographics and behavior.

## Data Sources
postgresql://Test:bQNxVzJL4g6u@ep-noisy-flower-846766.us-east-2.aws.neon.tech/TravelTide?sslmode=require

## Tools
- Postgres SQL - Used for data analysis
- Tableau - Used for data visualization

## Data Analysis
Since the aim of this project is to better understand customers, some of the uestions that  were answered using SQL are as follows:

1. Which cross-section of age and gender travels the most?
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
2. Calculate the proportion of sessions abandoned in summer months (June, July, August) and compare it to the proportion of sessions abandoned in non-summer months
```sql
WITH SessionByMonths AS (
    SELECT
        session_id,
        CASE
            WHEN EXTRACT(MONTH FROM session_end) IN (6, 7, 8) THEN 'summer'
            ELSE 'other'
        END AS session_month
    FROM sessions
  WHERE trip_id IS NULL
)
SELECT 
    ROUND(SUM(CASE WHEN session_month = 'summer' THEN 1 ELSE 0 END) / 3162887::numeric, 3) AS summer_abandon_rate,
    ROUND(SUM(CASE WHEN session_month = 'other' THEN 1 ELSE 0 END) / 3072218::numeric, 3) AS other_abandon_rate
FROM 
    SessionByMonths;	
```

