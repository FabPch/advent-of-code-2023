CREATE OR ALTER FUNCTION dbo.extract_numbers(@word VARCHAR(MAX), @with_pattern VARCHAR(100))
RETURNS INT
AS
BEGIN
DECLARE @pattern VARCHAR(MAX) = '%[^0-9]%'
DECLARE @index INT = PATINDEX(@pattern, @word)

IF @with_pattern IS NOT NULL AND PATINDEX(@with_pattern, @word) = 0
    RETURN 0

WHILE @index > 0
BEGIN
	SET @word = STUFF(@word, @index, 1, '')
	SET @index = PATINDEX(@pattern, @word)
END

RETURN COALESCE(CAST(@word AS INT), 0)
END
GO

--------- SOLUTION --------------
IF OBJECT_ID('tempdb..#advent_2') IS NOT NULL
    DROP TABLE #advent_2

IF OBJECT_ID('tempdb..#advent_2_cleaned') IS NOT NULL
    DROP TABLE #advent_2_cleaned

CREATE TABLE #advent_2
(
    [index] NVARCHAR(15)
	, word NVARCHAR(MAX)
)

DECLARE @max_red INT = 12
DECLARE @max_green INT = 13
DECLARE @max_blue INT = 14

BULK INSERT #advent_2
   FROM 'C:\Users\Fabien\Documents\rise-again\advent-of-code-2023\advent-2-input.txt'
   WITH (
      ROWTERMINATOR = '\n'
	  , FIELDTERMINATOR = ':'
   );


;WITH GAME_OUTPUT AS (
	SELECT 
		 [index], 
		[value] AS game_hint
	FROM #advent_2
		CROSS APPLY STRING_SPLIT(word, ';')
)

SELECT dbo.extract_numbers([index], NULL) AS [index]
    , dbo.extract_numbers([value], '%red%') AS game_hint_red
	, dbo.extract_numbers([value], '%blue%') AS game_hint_blue
	, dbo.extract_numbers([value], '%green%') AS game_hint_green
	, [value]

INTO #advent_2_cleaned

FROM GAME_OUTPUT
    CROSS APPLY STRING_SPLIT(game_hint, ',')

;WITH IMPOSSIBLE_GAME AS (
SELECT DISTINCT [index]
FROM #advent_2_cleaned
WHERE game_hint_blue > @max_blue
    OR game_hint_green > @max_green
	OR game_hint_red > @max_red
)

SELECT SUM(DISTINCT A2C.[index]) AS solution_part_1
FROM #advent_2_cleaned A2C
LEFT JOIN IMPOSSIBLE_GAME IG ON A2C.[index] = IG.[index]
WHERE IG.[index] IS NULL


;WITH GAME_POWER AS (
SELECT [index] 
    , MAX(game_hint_red) AS red_number
    , MAX(game_hint_green) AS green_number
	, MAX(game_hint_blue) AS blue_number

FROM #advent_2_cleaned
GROUP BY [index]
)

SELECT SUM(red_number * green_number * blue_number) AS solution_part_2
FROM GAME_POWER

IF OBJECT_ID('tempdb..#advent_2') IS NOT NULL
    DROP TABLE #advent_2

IF OBJECT_ID('tempdb..#advent_2_cleaned') IS NOT NULL
    DROP TABLE #advent_2_cleaned
