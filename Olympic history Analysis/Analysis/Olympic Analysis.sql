
--1 which team has won the maximum gold medals over the years.
;WITH cte as (
SELECT 
ae.year
	,count(ae.athlete_id) no_gold_medals 
	,a.team
	,ROW_NUMBER() OVER(PARTITION BY year ORDER BY count(ae.athlete_id)desc) rwn
FROM [dbo].[athlete_events] ae 
INNER JOIN [dbo].[athletes] a ON ae.athlete_id=a.id
WHERE ae.medal='gold'
GROUP BY ae.year ,a.team
)

SELECT
	year,team
FROM cte
WHERE 
	rwn=1

--2 for each team print total silver medals and year in which they won maximum silver medal..output 3 columns
-- team,total_silver_medals, year_of_max_silver

WITH cte AS (
SELECT 
	ae.year
	,count(ae.athlete_id) no_silver_medals 
	,a.team
	,ROW_NUMBER() OVER(PARTITION BY team ORDER BY count(ae.athlete_id)DESC) rwn
FROM [dbo].[athlete_events] ae 
INNER JOIN [dbo].[athletes] a ON ae.athlete_id=a.id
WHERE ae.medal='silver'
GROUP BY ae.year ,a.team
)

SELECT
	 team
	 ,no_silver_medals   AS  total_silver_medals
	 ,year               AS  year_of_max_silver ,rwn
FROM cte
WHERE rwn=1
ORDER BY team,year


--3 which player has won maximum gold medals  amongst the players 
--which have won only gold medal (never won silver or bronze) over the years.
WITH cte as
(
SELECT ae.athlete_id,count(1) no_of_medals
FROM 
	dbo.athlete_events ae
WHERE 
	medal ='Gold' 
AND ae.athlete_id NOT IN (SELECT athlete_id FROM dbo.athlete_events  WHERE medal IN ('silver','bronze') )
GROUP BY 
	ae.athlete_id)
SELECT TOP 1 c.athlete_id,no_of_medals,a.name
FROM
	cte c
	INNER JOIN dbo.athletes a ON c.athlete_id=a.id
ORDER BY no_of_medals DESC

--4 in each year which player has won maximum gold medal . Write a query to print year,player name 
--and no of golds won in that year . In case of a tie print comma separated player names.
WITH CTE AS
(
SELECT athlete_id,year,count(1) no_of_medals,dense_rank() OVER(PARTITION BY YEAR ORDER BY COUNT(1)desc) drnk 
FROM
	dbo.athlete_events
WHERE medal='gold'
GROUP BY athlete_id,year
)

SELECT year,no_of_medals,string_agg(name,' , ')
FROM
	CTE c 
	JOIN  dbo.athletes a ON c.athlete_id=a.id

WHERE drnk=1
GROUP BY  year,no_of_medals
ORDER BY year

--5 in which event and year India has won its first gold medal,first silver medal and first bronze medal
--print 3 columns medal,year,sport

;WITH CTE AS(
SELECT 
	medal
	,min([YEAR]) First_year
	,[event]
	,sport
	,DENSE_Rank() OVER(PARTITION BY medal ORDER BY [Year] ASC) rnk
FROM 
	dbo.athletes a
	INNER JOIN dbo.athlete_events ae ON a.id = ae.athlete_id AND team = 'India' and medal <> 'NA'
GROUP BY [EVENT],medal,sport,year
)
SELECT * 
FROM 
	CTE
WHERE 
	rnk = 1


--6 find players who won gold medal in summer and winter olympics both.
SELECT DISTINCT [name]
FROM
	dbo.athletes a
	INNER JOIN dbo.athlete_events ae ON a.id = ae.athlete_id AND medal = 'GOLD' AND season IN ('summer','Winter')


--7 find players who won gold, silver and bronze medal in a single olympics. print player name along with year.
SELECT  [name],year
FROM
	dbo.athletes a
	INNER JOIN dbo.athlete_events ae ON a.id = ae.athlete_id and medal <> 'NA'
GROUP BY name,year
HAVING COUNT(distinct medal)=3

--8 find players who have won gold medals in consecutive 3 summer olympics in the same event . Consider only olympics 2000 onwards. 
--Assume summer olympics happens every 4 year starting 2000. print player name and event name.

WITH CTE AS(
SELECT  name, event,year
FROM
	dbo.athletes a
	INNER JOIN dbo.athlete_events ae ON a.id = ae.athlete_id AND year>=2000 AND medal='gold' and season='summer'
GROUP BY name, year,event
)
SELECT DISTINCT *
FROM (
SELECT *,
	LAG(year,1) OVER(PARTITION BY [name],[event] ORDER BY year) consecutive_prev
	,LEAD(year,1) OVER(PARTITION BY [name],[event] ORDER BY year) consecutive_next
FROM CTE
) a
WHERE year=consecutive_prev+4 AND year=consecutive_next-4





