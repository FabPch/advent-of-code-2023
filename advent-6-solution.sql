IF OBJECT_ID('tempdb..#advent_6_input') IS NOT NULL
    DROP TABLE #advent_6_input

IF OBJECT_ID('tempdb..#advent_6') IS NOT NULL
    DROP TABLE #advent_6

IF OBJECT_ID('tempdb..#number_serie') IS NOT NULL
    DROP TABLE #number_serie

----------------- PART 1 -----------------
CREATE TABLE #advent_6_input ([name] VARCHAR(MAX), number VARCHAR(MAX))
BULK INSERT #advent_6_input FROM 'C:\Users\Fabien\Documents\rise-again\advent-of-code-2023\advent-6-input.txt'
WITH (FIELDTERMINATOR = ':')

;WITH INPUT AS (
	SELECT A.[name]
		, CAST(N.[value] AS INT) AS [value]
		, ROW_NUMBER() OVER(PARTITION BY A.[name] ORDER BY N.ordinal) AS line_number 

	FROM #advent_6_input A
		CROSS APPLY string_split(number, ' ', 1) N 
	WHERE N.[value] != ' '
)

SELECT CAST(P.[time] AS BIGINT) AS [time]
    , CAST(P.distance AS BIGINT) AS distance
	, P.line_number

INTO #advent_6

FROM
(
  SELECT
    [name]
    , [value]
	, line_number
  FROM INPUT
) E
PIVOT(
  MAX([value])
  FOR [name] IN ([distance], [time])
) P


DECLARE @max_number INT = (SELECT MAX([time]) FROM #advent_6)

;WITH NUMBER_SERIE AS
(
SELECT 1 AS my_number

UNION ALL

SELECT my_number + 1
FROM NUMBER_SERIE
WHERE my_number < @max_number
)

SELECT my_number INTO #number_serie FROM NUMBER_SERIE
OPTION(MAXRECURSION  1000);

WITH NUMBER_OF_WAY AS (
	SELECT COUNT(1) AS number_of_way
	FROM #advent_6 A
	JOIN #number_serie NS ON A.[time] >= NS.my_number
	WHERE NS.my_number * (A.[time] - NS.my_number) > A.distance
	GROUP BY A.[time]
)
SELECT EXP(SUM(LOG(number_of_way))) AS solution_part_1
FROM NUMBER_OF_WAY

----------------- PART 2 -----------------
-- Second part: done solving quadratic equation -x^2 + time*x - distance_record > 0 
TRUNCATE TABLE #advent_6_input
BULK INSERT #advent_6_input FROM 'C:\Users\Fabien\Documents\rise-again\advent-of-code-2023\advent-6-input.txt'
WITH (FIELDTERMINATOR = ':')

DECLARE @time DECIMAL(28, 10) = (SELECT CAST(REPLACE(number, ' ', '') AS BIGINT) FROM #advent_6_input WHERE [name] = 'Time')
DECLARE @distance DECIMAL(28, 10) = (SELECT CAST(REPLACE(number, ' ', '') AS BIGINT) FROM #advent_6_input WHERE [name] = 'Distance')

DECLARE @delta DECIMAL(28, 10) = (SELECT SQUARE(@time) - (4 * (-1) * (-@distance)))
DECLARE @x_1 DECIMAL(28, 10) = (SELECT -@time - SQRT(@delta) / (-2))
DECLARE @x_2 DECIMAL(28, 10) = (SELECT -@time + SQRT(@delta) / (-2))

SELECT CAST(ABS(@x_1 - @x_2) AS BIGINT) AS solution_part_2

IF OBJECT_ID('tempdb..#advent_6_input') IS NOT NULL
    DROP TABLE #advent_6_input

IF OBJECT_ID('tempdb..#advent_6') IS NOT NULL
    DROP TABLE #advent_6

IF OBJECT_ID('tempdb..#number_serie') IS NOT NULL
    DROP TABLE #number_serie
