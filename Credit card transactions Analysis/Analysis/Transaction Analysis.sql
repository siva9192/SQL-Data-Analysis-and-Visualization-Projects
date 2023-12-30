--1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
DECLARE @TotalAmount Float = (SELECT sum(amount) FROM [dbo].[credit_card_transcations])
SELECT TOP 5 *
FROM (
	SELECT city
		,sum(amount) AS Amount
		,(sum(amount) /@TotalAmount * 100) AS 'Percentage%'
	FROM [dbo].[credit_card_transcations]
	Group by city) a
ORDER BY amount desc
--2- write a query to print highest spend month and amount spent in that month for each card type
WITH cte as(
SELECT 
	card_type
	,MONTH(transaction_date) AS 'month'
	,SUM(amount) as total_amount,
ROW_NUMBER() OVER(PARTITION BY card_type ORDER BY SUM(amount) DESC) rnk
FROM
	credit_card_transcations
GROUP BY  
	card_type
	, MONTH(transaction_date)
)
SELECT 
	card_type
	,MONTH
	,total_amount 
FROM cte
WHERE rnk=1

--3- write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)

with cte as (
select
	  card_type
	, transaction_id
	, amount
	, SUM(amount) over( partition by card_type order by amount desc) totalsum
from credit_card_transcations)
,cte1 as (
select *
	,ROW_NUMBER() over(partition by card_type order by totalsum asc) rnk
from cte
where totalsum> 1000000
)
select cr.*
from cte1 c
inner join credit_card_transcations cr on c.transaction_id=cr.transaction_id and c.rnk=1
--4- write a query to find city which had lowest percentage spend for gold card type
DECLARE @TotalAmount1 Float = (SELECT sum(amount) FROM [dbo].[credit_card_transcations])
SELECT top 1 *
FROM (
	SELECT city,sum(amount) AS Amount,(sum(amount) /@TotalAmount1 * 100) AS 'Percentage%'
	FROM [dbo].[credit_card_transcations]
	WHERE card_type='Gold'
	Group by city) a
ORDER BY [Percentage%] asc
--5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
with cte as 
(SELECT  City
	,exp_type
	,SUM(AMOUNT) amount
	, row_number() OVER(PARTITION BY city ORDER BY Sum(amount) ASC) lowest_exp
	,row_number() OVER(PARTITION BY city ORDER BY Sum(amount) DESC) highest_exp
FROM credit_card_transcations
GROUP BY city,exp_type)

SELECT  city 
	, max(CASE WHEN lowest_exp=1 THEN (exp_type) END) AS lowest
	, max(CASE WHEN highest_exp=1 THEN exp_type END) AS highest
FROM 
	cte
WHERE
	lowest_exp=1 or highest_exp=1
GROUP BY 
	city
--6- write a query to find percentage contribution of spends by females for each expense type
DECLARE @TotalAmount3 Float = (SELECT sum(amount) FROM [dbo].[credit_card_transcations])
SELECT *
FROM (
	SELECT gender
		,exp_type
		,sum(amount) AS Amount
		,(sum(amount) /@TotalAmount3 * 100) AS 'Percentage%'
	FROM [dbo].[credit_card_transcations]
	WHERE gender = 'F'
	GROUP BY gender,exp_type) a
ORDER BY amount DESC
--7- which card and expense type combination saw highest month over month growth in Jan-2014

SELECT TOP 1 card_type,exp_type
	,SUM(amount) as amount
	,lAG(SUM(amount),1,0) 
	over(PARTITION BY MONTH(transaction_date),YEAR(transaction_date) ORDER BY MONTH(transaction_date),YEAR(transaction_date) ) MOM
FROM 
	credit_card_transcations
WHERE 
	MONTH(transaction_date)= 1 and YEAR(transaction_date)= 2014
GROUP BY 
	card_type,exp_type,MONTH(transaction_date),YEAR(transaction_date)
ORDER BY MOM DESC
--8- during weekends which city has highest total spend to total no of transcations ratio 
SELECT top 1 city
	,SUM(amount) AS amount
	,COUNT(*) As NUMOFTRA
	,SUM(amount) / COUNT(*) AS ratio
FROM 
	credit_card_transcations
where 
	DATEPART(DW,transaction_date) in (1,7)
GROUP BY 
	city
Order by ratio DESC
--9- which city took least number of days to reach its 500th transaction after the first transaction in that city
; WITH cte AS (
SELECT city
	,transaction_date,transaction_id
	,ROW_NUMBER() over(PARTITION BY city ORDER BY transaction_date) AS rnk
FROM credit_card_transcations
)
SELECT top 1 cte.city
	,cte.transaction_id
	,cte.transaction_date AS maxdate
	,MIN(c.transaction_date) AS mindate
	,DATEDIFF(dd,MIN(c.transaction_date),cte.transaction_date ) diff
FROM cte
	LEFT JOIN credit_card_transcations c ON cte.city = c.city AND cte.rnk IN (500) 
WHERE 
	cte.rnk IN (500) AND c.transaction_id is not null
GROUP BY 
	cte.city,cte.transaction_id,cte.transaction_date
order by diff 
