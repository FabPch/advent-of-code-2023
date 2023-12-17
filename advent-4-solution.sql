IF OBJECT_ID('tempdb..#advent_4') IS NOT NULL
    DROP TABLE #advent_4

IF OBJECT_ID('tempdb..#advent_4_winning') IS NOT NULL
    DROP TABLE #advent_4_winning

IF OBJECT_ID('tempdb..#advent_4_number') IS NOT NULL
    DROP TABLE #advent_4_number

IF OBJECT_ID('tempdb..#advent_4_part_2') IS NOT NULL
    DROP TABLE #advent_4_part_2

CREATE TABLE #advent_4([card_number] NVARCHAR(15), word NVARCHAR(MAX))

BULK INSERT #advent_4
   FROM 'C:\Users\Fabien\Documents\rise-again\advent-of-code-2023\advent-4-input.txt'
   WITH (
      ROWTERMINATOR = '\n'
	  , FIELDTERMINATOR = ':'
   );

-- Table with numbers before the pipe. The numbers after the pipe should match at least one of these numbers.
SELECT card_number, CAST(B.[value] AS INT) AS [value]

INTO #advent_4_winning

FROM #advent_4
CROSS APPLY STRING_SPLIT(word, '|', 1) A
CROSS APPLY STRING_SPLIT(A.[value], ' ') B
WHERE A.ordinal % 2 = 1 AND B.value != ' '

-- Table with numbers after the pipe. We need to verify if those numbers match one of the input number (before the pipe)
SELECT card_number, CAST(B.[value] AS INT) AS [value]

INTO #advent_4_number

FROM #advent_4
CROSS APPLY STRING_SPLIT(word, '|', 1) A
CROSS APPLY STRING_SPLIT(A.[value], ' ') B
WHERE A.ordinal % 2 = 0 AND B.value != ' '

;WITH TOTAL_NUMBER AS (
SELECT W.card_number
    , POWER(2, COUNT(1) - 1) AS points
FROM #advent_4_winning W
JOIN #advent_4_number N ON W.card_number = N.card_number
WHERE W.[value] = N.[value]
GROUP BY W.card_number
)

SELECT SUM(points) AS solution_part_1
FROM TOTAL_NUMBER

-- Table with number of winning cards and number of instances
SELECT W.card_number
    , COUNT(N.[value]) AS winning_card_number
	, 1                AS instance
	, ROW_NUMBER() OVER(ORDER BY W.card_number) AS row_card_number

INTO #advent_4_part_2

FROM #advent_4_winning W
LEFT JOIN #advent_4_number N ON W.card_number = N.card_number AND W.[value] = N.[value]
GROUP BY W.card_number

DECLARE @row_number INT = (SELECT MIN(row_card_number) FROM #advent_4_part_2)
DECLARE @max_number INT = (SELECT MAX(row_card_number) FROM #advent_4_part_2)
DECLARE @winning_card_number INT = (SELECT winning_card_number FROM #advent_4_part_2 WHERE row_card_number = @row_number)
DECLARE @instance INT = (SELECT instance FROM #advent_4_part_2 WHERE row_card_number = @row_number)

WHILE @row_number <= @max_number
BEGIN
    -- For each line, add to the line below the number of instances of the current line (if winning cards)
	UPDATE #advent_4_part_2
	SET instance = instance + @instance
	WHERE @winning_card_number > 0
		AND row_card_number > @row_number
		AND row_card_number <= @row_number + @winning_card_number
    
	SET @row_number = (SELECT MIN(row_card_number) FROM #advent_4_part_2 WHERE row_card_number > @row_number)
	SET @winning_card_number = (SELECT winning_card_number FROM #advent_4_part_2 WHERE row_card_number = @row_number)
	SET @instance = (SELECT instance FROM #advent_4_part_2 WHERE row_card_number = @row_number)
END

SELECT SUM(instance) AS solution_part_2
FROM #advent_4_part_2

IF OBJECT_ID('tempdb..#advent_4') IS NOT NULL
    DROP TABLE #advent_4

IF OBJECT_ID('tempdb..#advent_4_winning') IS NOT NULL
    DROP TABLE #advent_4_winning

IF OBJECT_ID('tempdb..#advent_4_number') IS NOT NULL
    DROP TABLE #advent_4_number

IF OBJECT_ID('tempdb..#advent_4_part_2') IS NOT NULL
    DROP TABLE #advent_4_part_2
