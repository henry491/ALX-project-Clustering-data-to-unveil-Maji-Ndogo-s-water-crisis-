SELECT *
FROM employee
;
    
  SELECT 
	email,
CONCAT(REPLACE(LOWER(employee_name), " ", "."),'name@ndogowater.gov.')
  FROM employee
;

UPDATE md_water_services.employee
SET email = CONCAT(
	REPLACE(LOWER(employee_name), " ", "."),'@ndogowater.gov.')
;
UPDATE employee
SET phone_number = RTRIM(phone_number)
;

SELECT DISTINCT
	town_name,
    COUNT(employee_name)
    OVER (PARTITION BY town_name) AS num_employees
FROM employee
;

/*
So let's use the database to get the
employee_ids and use those to get the names, email and phone numbers of the three field surveyors with the most location visits.
*/

SELECT DISTINCT
	assigned_employee_id,
    COUNT(record_id)
    -- OVER (PARTITION BY assigned_employee_id) AS number_of_visits -- YOU CAN USE THIS OR
    FROM visits
    GROUP BY assigned_employee_id  -- THIS
    LIMIT 3
    ;
    
    SELECT 
		assigned_employee_id,
        employee_name,
        email,
        phone_number,
	IF( (assigned_employee_id = 0), assigned_employee_id,
		IF(assigned_employee_id = 1, assigned_employee_id,
			IF(assigned_employee_id = 2, assigned_employee_id,
				'NULL'
                )
			)
		) Top_dogs
    FROM employee
    LIMIT 3
;
SELECT DISTINCT
    COUNT(location_type)
    OVER (PARTITION BY province_name) records_per_province,
    province_name
FROM location
ORDER BY records_per_province DESC
;

SELECT DISTINCT
	province_name,
    town_name,
    COUNT(province_name) records_per_town
FROM location
GROUP BY province_name,
		 town_name
ORDER BY province_name, records_per_town DESC
LIMIT 6
 ;
 SELECT 
	COUNT(province_name) AS num_sources,
    location_type
 FROM location
 GROUP BY 
	location_type
 ;
 
 -- OR
 
 SELECT DISTINCT
	location_type,
	COUNT(province_name)
    OVER (PARTITION BY location_type) AS num_sources
 FROM location
 ;
 
 -- OR
 
 SELECT
	location_type,
    IF(location_type = 'Rural',(COUNT(location_type)),
		IF(location_type = 'Urban',(COUNT(location_type)), 'NULL'
		)
	) COUNT_DOWN
 FROM location
 GROUP BY
	location_type
  ;  
  
  -- How many wells, taps and rivers are there
  
 SELECT 
	type_of_water_source,
    COUNT(type_of_water_source) AS diff_water_source
 FROM water_source
GROUP BY
	type_of_water_source
ORDER BY type_of_water_source
 ;
 
 -- How many people did we survey in total
 
 SELECT
    SUM(number_of_people_served)
 FROM water_source
 
 ;
 
-- How many people share particular types of water sources on average 
 
 SELECT DISTINCT
	type_of_water_source,
    ROUND(AVG(number_of_people_served)) AS ave_people_per_source
 FROM water_source
 GROUP BY
	type_of_water_source
;

/*calculate the total number of people served by each type of water source in total, to make it easier to interpret,
order them so the most people served by a source is at the top
*/

SELECT
	type_of_water_source,
    SUM(number_of_people_served) AS population_served
FROM water_source
GROUP BY
	type_of_water_source
ORDER BY population_served DESC
;

/*we need the total number of citizens then use the result of that and divide each of the SUM(number_of_people_served) by
that number, times 100, to get percentages. */

-- NOT ROUNDED
SELECT
	type_of_water_source,
(SUM(number_of_people_served) /
(SELECT SUM(number_of_people_served) FROM water_source) * 100) AS percentage_people_per_source
 FROM water_source
 GROUP BY type_of_water_source
 ORDER BY percentage_people_per_source DESC
 ;

-- ROUNDED
 SELECT
	type_of_water_source,
ROUND(SUM(number_of_people_served) /
(SELECT SUM(number_of_people_served) FROM water_source) * 100) AS percentage_people_per_source
 FROM water_source
 GROUP BY type_of_water_source
 ORDER BY percentage_people_per_source DESC
 ;
 
 /*So let's write a query that ranks each type of source based
on how many people in total use it. RANK() should tell you we are going to need a window function to do this
 */
 
 SELECT
	type_of_water_source,
	SUM(number_of_people_served) people_served,
    RANK() OVER (ORDER BY SUM(number_of_people_served)DESC) AS rank_by_population
 FROM water_source
GROUP BY
	type_of_water_source
LIMIT 2
 ;
 
 
 -- DATE_DIFF

 SELECT
	MIN(time_of_record),
    MAX(time_of_record),
    CONCAT(
    DATEDIFF(MAX(time_of_record),
    MIN(time_of_record)), "  ", 'which is about 2 and a half years!') DATE_DIFF
 FROM visits
 ;
 
 -- Let's see how long people have to queue on average in Maji Ndogo
 
  SELECT
  CONCAT(
ROUND(AVG(NULLIF(time_in_queue, 0))), "  ", 'MIN'
		) AS average
    FROM visits
 ;
 
 -- we need to calculate the average queue time, grouped by day of the week.
 
 SELECT
	DAYNAME(time_of_record) day_of_week,
    ROUND(AVG(NULLIF(time_in_queue, 0))) avg_queue_time
 FROM visits
 GROUP BY
	day_of_week
 ;
 
 -- We can also look at what time during the day people collect water.
 
 SELECT
HOUR(time_of_record) AS hour_of_day,
ROUND(AVG(time_in_queue))
 FROM visits
 GROUP BY
	hour_of_day
 ORDER BY
	hour_of_day
LIMIT 3
 ;
 
 SELECT
 TIME_FORMAT(TIME (time_of_record), '%H:00') AS hour_of_day,
 ROUND(AVG(time_in_queue))
 FROM visits
 GROUP BY
	hour_of_day
ORDER BY 
 hour_of_day
 LIMIT 3
 ;
 
/* 
By adding AVG() around the CASE() function, we calculate the average, but since all of the other days' values are 0, we get an average for Sunday
only, rounded to 0 decimals. To aggregate by the hour, we can group the data by hour_of_day, and to make the table chronological, we also order
by hour_of_day.
 */
 
 SELECT
 TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
 DAYNAME(time_of_record) AS Day,
	CASE
		WHEN DAYNAME(time_of_record) = 'SUNDAY' THEN time_in_queue
		ELSE 'NULL'
	END AS SUNDAY
 FROM visits
 WHERE time_in_queue !=0
 ;

SELECT
	TIME_FORMAT(TIME(time_of_record), '%H:00') hour_of_day,
    ROUND(AVG(
    CASE
		WHEN DAYNAME(time_of_record) = 'SUNDAY' THEN time_in_queue
        ELSE NULL
	END )) AS SUNDAY,
    ROUND(AVG(
    CASE
		WHEN DAYNAME(time_of_record) = 'MONDAY' THEN time_in_queue
        ELSE NULL
	END )) AS MONDAY,
    ROUND(AVG(
    CASE
		WHEN DAYNAME(time_of_record) = 'TUESDAY' THEN time_in_queue
        ELSE NULL
	END )) AS TUESDAY,
    ROUND(AVG(
    CASE
		WHEN DAYNAME(time_of_record) = 'WEDNESDAY' THEN time_in_queue
        ELSE NULL
	END )) AS WEDENSDAY,
    ROUND(AVG(
    CASE
		WHEN DAYNAME(time_of_record) = 'THURSDAY' THEN time_in_queue
        ELSE NULL
	END )) AS THURSDAY,
    ROUND(AVG(
    CASE
		WHEN DAYNAME(time_of_record) = 'FRIDAY' THEN time_in_queue
        ELSE NULL
	END )) AS FRIDAY,
    ROUND(AVG(
    CASE
		WHEN DAYNAME(time_of_record) = 'SATURDAY' THEN time_in_queue
        ELSE NULL
	END )) AS SATURDAY
FROM visits
WHERE time_in_queue != 0
GROUP BY
	hour_of_day
ORDER BY
	hour_of_day
;

SELECT
CONCAT(
DAY(time_of_record), "  ",
MONTHNAME(time_of_record), "  ",
YEAR(time_of_record)
	) AS DAY_MONTH_YEAR
FROM visits
;
SELECT
	name,
    wat_bas_r - LAG(wat_bas_r) OVER (PARTITION BY name ORDER BY year)
FROM global_water_access
WHERE wat_bas_r IS NOT NULL
ORDER BY name
;

-------------------------------------------------------------------------------------------------------

SELECT
	*
FROM
	visits AS vs
JOIN
	water_quality AS wq
ON
	vs.record_id = wq.record_id;
    
DROP TABLE IF EXISTS `auditor_report`;
CREATE TABLE auditor_report (
location_id VARCHAR (32),
type_of_water_source VARCHAR (64),
true_water_source_score INT DEFAULT NULL,
statements VARCHAR (255)
);

SELECT
	location_id,
    true_water_source_score
FROM
	auditor_report
ORDER BY
	location_id;

    
SELECT
	vits.location_id AS audit_location,
    aure.true_water_source_score,
    vits.source_id AS visit_location,
    vits.record_id,
    waqu.subjective_quality_score
FROM
	auditor_report AS aure
JOIN
	visits AS vits
ON
	vits.location_id = aure.location_id
JOIN
	water_quality AS waqu
ON
	waqu.record_id = vits.record_id
    ;

SELECT
	vits.location_id,
    vits.record_id,
    aure.true_water_source_score AS auditor_score,
    waqu.subjective_quality_score AS surveyor_score
-- ROW_NUMBER () OVER () 
FROM
	auditor_report AS aure
JOIN
	visits AS vits
ON
	vits.location_id = aure.location_id
JOIN
	water_quality AS waqu
ON
	waqu.record_id = vits.record_id
WHERE
	aure.true_water_source_score = waqu.subjective_quality_score
AND vits.visit_count = 1
    ;
    
SELECT
	vits.location_id,
    aure.type_of_water_source AS auditor_source,
    waso.type_of_water_source AS survey_source,
    vits.record_id,
    aure.true_water_source_score AS auditor_score,
    waqu.subjective_quality_score AS surveyor_score
-- ROW_NUMBER () OVER () 
FROM
	auditor_report AS aure
JOIN
	visits AS vits
ON
	vits.location_id = aure.location_id
JOIN
	water_quality AS waqu
ON
	waqu.record_id = vits.record_id
JOIN
	water_source AS waso
ON
	aure.type_of_water_source = waso.type_of_water_source
WHERE
	aure.true_water_source_score - waqu.subjective_quality_score
AND vits.visit_count = 1
    ;

SELECT
	vits.location_id,
    vits.record_id,
    vits.assigned_employee_id,
    aure.true_water_source_score AS auditor_score,
    waqu.subjective_quality_score AS surveyor_score
-- ROW_NUMBER () OVER () 
FROM
	auditor_report AS aure
JOIN
	visits AS vits
ON
	vits.location_id = aure.location_id
JOIN
	water_quality AS waqu
ON
	waqu.record_id = vits.record_id
WHERE
	aure.true_water_source_score - waqu.subjective_quality_score
AND vits.visit_count = 1
-- LIMIT 6
    ;
	
CREATE VIEW  Incorrect_records AS (
 SELECT
	vits.location_id,
    vits.record_id,
    empl.employee_name,
    aure.true_water_source_score AS auditor_score,
    waqu.subjective_quality_score AS surveyor_score
-- ROW_NUMBER () OVER () 
FROM
	auditor_report AS aure
JOIN
	visits AS vits
ON
	vits.location_id = aure.location_id
JOIN
	water_quality AS waqu
ON
	waqu.record_id = vits.record_id
JOIN
	employee AS empl
ON
	empl.assigned_employee_id = vits.assigned_employee_id
WHERE
	aure.true_water_source_score != waqu.subjective_quality_score
AND vits.visit_count = 1
 );
 

WITH suspect_list AS (
	SELECT
		employee_name,
	COUNT(employee_name) AS number_of_mistakes
	FROM
		Incorrect_records
	/*
	Incorrect_records is a view that joins the audit report to the database
	for records where the auditor and
	employees scores are different
	*/
	GROUP BY
		employee_name
	),
	avg_error_count_per_empls AS (
	SELECT
		AVG(number_of_mistakes) AS avg_error_count_per_empl
	FROM
		suspect_list),
	 suspect_list_numbers AS (   
	SELECT
		employee_name,
		number_of_mistakes
	FROM
		suspect_list
	WHERE
		number_of_mistakes > (
							SELECT *
							FROM
								avg_error_count_per_empls))
 
   SELECT
	inre.employee_name,
    inre.location_id,
    aure.statements
-- ROW_NUMBER () OVER ()
FROM
	incorrect_records AS inre
JOIN
	 auditor_report AS aure
ON
	inre.location_id = aure.location_id
WHERE
	inre.employee_name = employee_name
AND
	inre.employee_name IN (   
							SELECT
								employee_name
							FROM
								suspect_list AS susl
							WHERE
								number_of_mistakes > (
													SELECT *
													FROM
														avg_error_count_per_empls))
AND
	statements LIKE '%cash%'
;
 
SELECT
	inre.employee_name,
    inre.location_id,
    aure.statements
-- ROW_NUMBER () OVER ()
FROM
	incorrect_records AS inre
JOIN
	 auditor_report AS aure
ON
	inre.location_id = aure.location_id
WHERE
	statements LIKE '%cash%'
AND
	employee_name != 'Zuriel Matembo'
AND
	employee_name <> 'Malachi Mavuso'
AND
	employee_name <> 'Bello Azibo'
AND
	employee_name <> 'Lalitha Kaburi';
   
SELECT
auditorRep.location_id,
visitsTbl.record_id,
auditorRep.true_water_source_score AS auditor_score,
wq.subjective_quality_score AS employee_score,
wq.subjective_quality_score - auditorRep.true_water_source_score  AS score_diff
FROM auditor_report AS auditorRep
JOIN visits AS visitsTbl
ON auditorRep.location_id = visitsTbl.location_id
JOIN water_quality AS wq
ON visitsTbl.record_id = wq.record_id
WHERE (wq.subjective_quality_score - auditorRep.true_water_source_score) > 9;


---------------------------------------------------------------------------------------------------    
   
    
SELECT
	loca.province_name,
    loca.town_name,
    vits.visit_count,
    vits.location_id,
    waso.type_of_water_source,
    waso.number_of_people_served
FROM
	location AS loca
JOIN
	visits AS vits
ON
	loca.location_id = vits.location_id
JOIN
	water_source AS waso
ON
	waso.source_id = vits.source_id
WHERE
	vits.visit_count = 1;
   
/*
Ok, now that we verified that the table is joined correctly,
we can remove the location_id and visit_count columns.
*/   
CREATE VIEW combined_analysis_table AS
-- This view assembles data from different tables into one to simplify analysis
 SELECT
	waso.type_of_water_source AS source_type,
    loca.town_name,
    loca.province_name,
    loca.location_type,
    waso.number_of_people_served AS people_served,
    vits.time_in_queue,
    wepo.results
FROM
	visits AS  vits
LEFT JOIN
	well_pollution AS wepo
ON
	wepo.source_id = vits.source_id
INNER JOIN
	location AS loca
ON
	loca.location_id = vits.location_id
INNER JOIN
	water_source AS waso
ON
	waso.source_id = vits.source_id
WHERE
	vits.visit_count = 1;   



WITH province_totals AS (
SELECT
	province_name,
    SUM(people_served) AS Total_people
FROM
	combined_analysis_table
GROUP BY
	province_name
)

SELECT
	cat.province_name,
-- These case statements create columns for each type of source.
-- The results are aggregated and percentages are calculated
ROUND((SUM(CASE
	WHEN
		source_type = 'river' THEN people_served ELSE 0 END) * 100.0 / prt.Total_people), 0) AS river,
ROUND((SUM(CASE
	WHEN
		source_type = 'well' THEN people_served ELSE 0 END) * 100.0 / prt.Total_people), 0) AS well,
ROUND((SUM(CASE
	WHEN
		source_type = 'shared_tap' THEN people_served ELSE 0 END) * 100.0 / prt.Total_people), 0) AS shared_tap,
ROUND((SUM(CASE
	WHEN
		source_type = 'tap_in_home_broken' THEN people_served ELSE 0 END) * 100.0 / prt.Total_people), 0) AS tap_in_home_broken,
ROUND((SUM(CASE
	WHEN
		source_type = 'tap_in_home' THEN people_served ELSE 0 END) * 100.0 / prt.Total_people), 0) AS tap_in_home

FROM
	combined_analysis_table AS cat
JOIN
	province_totals AS prt
ON
	cat.province_name = prt.province_name
GROUP BY
	cat.province_name
ORDER BY
	cat.province_name;
    
 CREATE TEMPORARY TABLE town_aggregated_water_access    
 WITH town_totals AS (
 SELECT
	province_name,
    town_name,
SUM(people_served) AS Total_people
FROM
	combined_analysis_table
GROUP BY
	province_name
    ,town_name)
SELECT
	cat.province_name,
    cat.town_name,
ROUND((SUM(CASE
	WHEN
		source_type = 'river' THEN people_served ELSE 0 END) * 100.0 / toto.Total_people), 0) AS river,
ROUND((SUM(CASE
	WHEN
		source_type = 'well' THEN people_served ELSE 0 END) * 100.0 / toto.Total_people), 0) AS well,
ROUND((SUM(CASE
	WHEN
		source_type = 'shared_tap' THEN people_served ELSE 0 END) * 100.0 / toto.Total_people), 0) AS shared_tap,
ROUND((SUM(CASE
	WHEN
		source_type = 'tap_in_home_broken' THEN people_served ELSE 0 END) * 100.0 / toto.Total_people), 0) AS tap_in_home_broken,
ROUND((SUM(CASE
	WHEN
		source_type = 'tap_in_home' THEN people_served ELSE 0 END) * 100.0 / toto.Total_people) , 0) AS tap_in_home
FROM
	combined_analysis_table AS cat
JOIN
	town_totals AS toto
ON
	cat.province_name = toto.province_name
AND
	cat.town_name = toto.town_name
GROUP BY
	cat.province_name
    ,cat.town_name;

-- which town has the highest ratio of people who have taps, but have no running water?
    
SELECT
	province_name,
    town_name,
ROUND((tap_in_home_broken / (tap_in_home_broken + tap_in_home) * 100.0), 0) AS Pct_broken_taps
FROM
	town_aggregated_water_access
ORDER BY
	Pct_broken_taps DESC;

 
/*

Insights
Ok, so let's sum up the data we have.
A couple of weeks ago we found some interesting insights:
1. Most water sources are rural in Maji Ndogo.
2. 43% of our people are using shared taps. 2000 people often share one tap.
3. 31% of our population has water infrastructure in their homes, but within that group,
4. 45% face non-functional systems due to issues with pipes, pumps, and reservoirs. Towns like Amina, the rural parts of Amanzi, and a couple
of towns across Akatsi and Hawassa have broken infrastructure.
5. 18% of our people are using wells of which, but within that, only 28% are clean. These are mostly in Hawassa, Kilimani and Akatsi.
6. Our citizens often face long wait times for water, averaging more than 120 minutes:
• Queues are very long on Saturdays.
• Queues are longer in the mornings and evenings.
• Wednesdays and Sundays have the shortest queues.

*/

CREATE TABLE Project_progress (
Project_id SERIAL PRIMARY KEY,
source_id VARCHAR (20) NOT NULL REFERENCES water_source (source_id) ON DELETE CASCADE ON UPDATE CASCADE,
Address VARCHAR (50),
Town VARCHAR (30),
Province VARCHAR (30),
Source_type VARCHAR (50),
Improvement VARCHAR (50),
Source_status VARCHAR (50) DEFAULT 'BACKLOG' CHECK (Source_status IN ('BACKLOG', 'In progress', 'Complete')),
Date_of_completion DATE,
Comments TEXT
);
-- DROP VIEW project_progres
;
CREATE VIEW project_progres  AS
SELECT
	lon.address,
    lon.town_name,
    lon.province_name,
    ws.source_id,
    ws.type_of_water_source,
    wp.results,
-- ROW_NUMBER () OVER() RTY,
CASE
	WHEN
		ws.type_of_water_source = 'well' AND wp.results = 'Contaminated: Biological' 
        THEN 'Install UV and RO filter'
	WHEN
		ws.type_of_water_source = 'well' AND wp.results = 'Contaminated: Chemical' 
        THEN 'Install RO filter'
	WHEN
		type_of_water_source = 'river' THEN 'Drill well'
	WHEN
		type_of_water_source = 'shared_tap' THEN CONCAT('Install', '  ', FLOOR(time_in_queue/30), '  ', 'taps nearby')
	WHEN
		type_of_water_source = 'tap_in_home_broken' THEN 'Diagnose local infrastructure'
		ELSE NULL
	END AS Improvement
FROM
	water_source AS ws
LEFT JOIN
	well_pollution AS wp
ON
	wp.source_id = ws.source_id
INNER JOIN
	visits AS vs
ON
	ws.source_id = vs.source_id
INNER JOIN
	location AS lon
ON
	lon.location_id = vs.location_id
WHERE
	vs.visit_count = 1
AND (
	 ws.type_of_water_source = 'well' AND wp.results != 'Clean'
 OR
	ws.type_of_water_source IN ('river', 'tap_in_home_broken')
OR
	(ws.type_of_water_source = 'shared_tap' AND vs.time_in_queue >= 30)
	);
WITH SUM_people_served AS (
SELECT
	province_name,
    town_name,
    SUM(people_served) AS Total_people_served
FROM
	combined_analysis_table
GROUP BY
	province_name,
    town_name
)
SELECT
	cat.province_name,
    cat.town_name,
    cat.source_type,
ROUND((SUM(CASE
	WHEN
		source_type = 'river' THEN people_served ELSE 0 END) * 100 / Total_people_served), 0) AS river
FROM	
	combined_analysis_table AS cat
JOIN
	SUM_people_served AS sps
ON
	cat.province_name = sps.province_name
AND
	cat.town_name = sps.town_name
WHERE
	cat.province_name = 'Amanzi'
AND
	cat.source_type = 'river'
GROUP BY
	cat.province_name,
    cat.town_name,
    cat.source_type
;
    
SELECT
	province_name,
    town_name,
    tap_in_home_broken,
    tap_in_home,
RANK () over (PARTITION BY province_name ORDER BY town_name)
FROM
	town_aggregated_water_access
WHERE
	tap_in_home_broken < 50
AND
	tap_in_home < 50
GROUP BY
	province_name,
    town_name,
    tap_in_home_broken,
    tap_in_home
ORDER BY
	province_name;


CREATE TABLE project_progress (
-- Project_id SERIAL PRIMARY KEY,
address VARCHAR (50),
town_name VARCHAR (30),
province_name VARCHAR (30),
source_id VARCHAR (20) NOT NULL REFERENCES water_source (source_id) ON DELETE CASCADE ON UPDATE CASCADE,
type_of_water_source VARCHAR (50),
results VARCHAR (50),
Improvement VARCHAR (30)
-- Date_of_completion DATE,
-- Comments TEXT
);

ALTER TABLE project_progress
ADD COLUMN Project_id SERIAL PRIMARY KEY FIRST;

SELECT *, TRIM(SUBSTRING_INDEX(employee_name, ' ', 1)) AS First_Name
FROM
	employee;