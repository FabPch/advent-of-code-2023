IF OBJECT_ID('tempdb..#advent_9_input') IS NOT NULL
    DROP TABLE #advent_9_input

IF OBJECT_ID('tempdb..#advent_9_raw') IS NOT NULL
    DROP TABLE #advent_9_raw

IF OBJECT_ID('tempdb..#advent_9') IS NOT NULL
    DROP TABLE #advent_9

IF OBJECT_ID('tempdb..#advent_9_iterative') IS NOT NULL
    DROP TABLE #advent_9_iterative


IF OBJECT_ID('tempdb..#number_tmp') IS NOT NULL
    DROP TABLE #number_tmp

----------------- DATA CLEANING -----------------
CREATE TABLE #advent_9_raw ([line] VARCHAR(MAX))
BULK INSERT #advent_9_raw FROM 'C:\Users\Fabien\Documents\rise-again\advent-of-code-2023\advent-9-input.txt'

-- first, we add a line_number
SELECT line, ROW_NUMBER() OVER(ORDER BY line) AS line_number INTO #advent_9_input FROM #advent_9_raw --WHERE line = '26 50 93 161 274 481 872 1581 2775 4628 7286 10839 15329 20839 27727 37091 51576 76662 122603 207221 359796'

-- second, we split each number and add a list_number
SELECT A.line
    , CAST(N.[value] AS INT) AS number
    , A.line_number
    , ROW_NUMBER() OVER(PARTITION BY A.line ORDER BY N.ordinal DESC) list_order
INTO #advent_9 
FROM #advent_9_input A
	CROSS APPLY STRING_SPLIT(line, ' ', 1) N 

----------------- PART 1 -----------------
-- table and variable for first loop
--SELECT * FROM #advent_9

DECLARE @row_number INT = (SELECT MIN(line_number) FROM #advent_9)
CREATE TABLE #advent_9_iterative (number INT, list_order INT)

-- table and variables for nested loop
CREATE TABLE #number_tmp (number INT, diff INT, list_order INT)
DECLARE @last_number INT
DECLARE @sum_of_last_number INT = 0
DECLARE @sum_of_all_diff INT

-- first loop to iterate on all lines
WHILE @row_number IS NOT NULL
BEGIN
    TRUNCATE TABLE #advent_9_iterative
	INSERT INTO #advent_9_iterative (number, list_order)
	SELECT number, list_order FROM #advent_9 WHERE line_number = @row_number

	-- before each nested loop
	SET @sum_of_all_diff = -1
	SET @last_number = 0
	
	WHILE @sum_of_all_diff != 0
		BEGIN
			TRUNCATE TABLE #number_tmp
	
			INSERT INTO #number_tmp (number, diff, list_order)
			SELECT LAG(number) OVER(ORDER BY list_order DESC) AS number
				, number - CAST(LAG(number) OVER(ORDER BY list_order DESC) AS INT) AS diff
				, list_order
			FROM #advent_9_iterative

			-- To debug:
			--SELECT * FROM #number_tmp ORDER BY list_order
			--SELECT * FROM #advent_9_iterative ORDER BY list_order
			SELECT @last_number = @last_number + number FROM #advent_9_iterative WHERE list_order = 1
			--SELECT @sum_of_last_number = @sum_of_last_number + number FROM #advent_9_iterative WHERE list_order = 1
			SELECT @sum_of_all_diff = SUM(diff) FROM #number_tmp --WHERE diff IS NOT NULL

			TRUNCATE TABLE #advent_9_iterative
			INSERT INTO #advent_9_iterative (number, list_order)
			SELECT diff, list_order FROM #number_tmp WHERE number IS NOT NULL
		END

	-- To debug:
	UPDATE #advent_9 SET line = CONCAT(line, ' ', @last_number) WHERE line_number = @row_number
	SET @sum_of_last_number = @sum_of_last_number + @last_number
	
	SELECT @row_number = MIN(line_number) FROM #advent_9 WHERE line_number > @row_number
END

SELECT @sum_of_last_number AS solution_part_1
-- 1 974 232 257 is too high
-- 1 980 453 340 is too high

-- To debug:
--SELECT DISTINCT line FROM #advent_9

IF OBJECT_ID('tempdb..#advent_9_input') IS NOT NULL
    DROP TABLE #advent_9_input

IF OBJECT_ID('tempdb..#advent_9_raw') IS NOT NULL
    DROP TABLE #advent_9_raw

IF OBJECT_ID('tempdb..#advent_9') IS NOT NULL
    DROP TABLE #advent_9

IF OBJECT_ID('tempdb..#number_tmp') IS NOT NULL
    DROP TABLE #number_tmp

IF OBJECT_ID('tempdb..#advent_9_iterative') IS NOT NULL
    DROP TABLE #advent_9_iterative
