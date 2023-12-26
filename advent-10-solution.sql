CREATE OR ALTER FUNCTION dbo.extract_special_char_with_index(@word VARCHAR(MAX), @pattern NVARCHAR(100))
RETURNS @indexes TABLE ([index] INT)
AS
BEGIN
DECLARE @index INT = PATINDEX(@pattern, @word)

WHILE @index > 0
BEGIN
	SET @word = STUFF(@word, @index, 1, 'A')
	INSERT INTO @indexes ([index]) VALUES(@index)
	SET @index = PATINDEX(@pattern, @word)
END

RETURN
END
GO

IF OBJECT_ID('tempdb..#advent_10_input') IS NOT NULL
    DROP TABLE #advent_10_input

IF OBJECT_ID('tempdb..#advent_10_raw') IS NOT NULL
    DROP TABLE #advent_10_raw

IF OBJECT_ID('tempdb..#advent_9') IS NOT NULL
    DROP TABLE #advent_9

IF OBJECT_ID('tempdb..#advent_10_iterative') IS NOT NULL
    DROP TABLE #advent_10_iterative


IF OBJECT_ID('tempdb..#number_tmp') IS NOT NULL
    DROP TABLE #number_tmp

----------------- DATA CLEANING -----------------
CREATE TABLE #advent_10_raw ([line_number] INT, [line] VARCHAR(MAX))
--CREATE TABLE #advent_10_raw ([line] VARCHAR(MAX))
BULK INSERT #advent_10_raw FROM 'C:\Users\Fabien\Documents\rise-again\advent-of-code-2023\advent-10-input-ln.txt'
WITH (FIELDTERMINATOR = 'A')

SELECT RAW_INPUT.*
INTO #advent_10_input
FROM (
SELECT line_number
    , DOT.[index]   AS [index]
	, '.'           AS [value]
FROM #advent_10_raw A
	CROSS APPLY dbo.extract_special_char_with_index(A.line, '%.%') DOT
UNION
SELECT line_number
    , SEVEN.[index]   AS [index]
	, '7'             AS [value]
FROM #advent_10_raw A
	CROSS APPLY dbo.extract_special_char_with_index(A.line, '%7%') SEVEN
UNION
SELECT line_number
    , PIPE.[index]   AS [index]
	, '|'            AS [value]
FROM #advent_10_raw A
	CROSS APPLY dbo.extract_special_char_with_index(A.line, '%|%') PIPE
UNION
SELECT line_number
    , DASH.[index]   AS [index]
	, '-'            AS [value]
FROM #advent_10_raw A
	CROSS APPLY dbo.extract_special_char_with_index(A.line, '%-%') DASH
UNION
SELECT line_number
    , J.[index]   AS [index]
	, 'J'         AS [value]
FROM #advent_10_raw A
	CROSS APPLY dbo.extract_special_char_with_index(A.line, '%J%') J
UNION
SELECT line_number
    , F.[index]   AS [index]
	, 'F'         AS [value]
FROM #advent_10_raw A
	CROSS APPLY dbo.extract_special_char_with_index(A.line, '%F%') F
UNION
SELECT line_number
    , L.[index]   AS [index]
	, 'L'         AS [value]
FROM #advent_10_raw A
	CROSS APPLY dbo.extract_special_char_with_index(A.line, '%L%') L
UNION
SELECT line_number
    , S.[index]   AS [index]
	, 'S'         AS [value]
FROM #advent_10_raw A
	CROSS APPLY dbo.extract_special_char_with_index(A.line, '%S%') S
) RAW_INPUT
	
--SELECT MAX(line_number) * MAX([index]) FROM #advent_10_input

DECLARE @value VARCHAR(1)
DECLARE @index INT
DECLARE @line_number INT
DECLARE @previous_index INT
DECLARE @previous_line_number INT
DECLARE @previous_value VARCHAR(1)
DECLARE @index_tmp INT
DECLARE @line_number_tmp INT
DECLARE @value_tmp VARCHAR(1)
DECLARE @step_number INT = 0

SELECT @value = [value]
    , @index = [index]
	, @line_number = line_number
	, @previous_index = [index]
	, @previous_line_number = line_number
	, @previous_value = [value]
FROM #advent_10_input
WHERE [value] = 'S'

SELECT TOP 1 @value = POSITIONS.[value]
    , @index = POSITIONS.[index]
	, @line_number = POSITIONS.line_number
FROM
(
	SELECT [value]
		, [index]
		, line_number
	FROM #advent_10_input A
	WHERE line_number = @line_number
		AND (([index] = @index + 1 AND [value] IN ('-', '7', 'J', 'S')) 
			OR ([index] = @index - 1) AND [value] IN ('-', 'L', 'F', 'S'))
	UNION ALL
	SELECT [value]
		, [index]
		, line_number
	FROM #advent_10_input A
	WHERE line_number = @line_number - 1
		AND [index] = @index 
		AND [value] IN ('|', '7', 'F', 'S')
	UNION ALL
	SELECT[value]
		, [index]
		, line_number
	FROM #advent_10_input A
	WHERE line_number = @line_number + 1
		AND [index] = @index 
		AND [value] IN ('|', 'L', 'J', 'S')
) POSITIONS

SET @step_number = @step_number + 1

--SELECT @value, @index, @line_number

WHILE @value != 'S'
BEGIN
    SET @index_tmp = @index
	SET @line_number_tmp = @line_number
	SET @value_tmp = @value

	SELECT TOP 1 @value = POSITIONS.[value]
		, @index = POSITIONS.[index]
		, @line_number = POSITIONS.line_number
	FROM
	(
		SELECT [value]
			, [index]
			, line_number
		FROM #advent_10_input A
		WHERE line_number = @line_number
			AND (([index] = @index + 1 AND [value] IN ('-', '7', 'J', 'S') AND @value_tmp NOT IN ('7', '|', 'J')) 
				OR ([index] = @index - 1) AND [value] IN ('-', 'L', 'F', 'S') AND @value_tmp NOT IN ('|', 'L', 'F'))
		UNION ALL
		SELECT [value]
			, [index]
			, line_number
		FROM #advent_10_input A
		WHERE line_number = @line_number -1
			AND [index] = @index 
			AND [value] IN ('|', '7', 'F', 'S') AND @value_tmp NOT IN ('-', '7', 'F')
		UNION ALL
		SELECT[value]
			, [index]
			, line_number
		FROM #advent_10_input A
		WHERE line_number = @line_number + 1
			AND [index] = @index 
			AND [value] IN ('|', 'L', 'J', 'S') AND @value_tmp NOT IN ('-', 'L', 'J')
	) POSITIONS
    WHERE ([index] != @previous_index OR line_number != @previous_line_number)
	
	--PRINT(CONCAT(@value, ', line: ', @line_number, ', index: ', @index))

	IF @index = @index_tmp AND @line_number = @line_number_tmp
	    BEGIN
		PRINT(CONCAT('Blocked at step number: ', @step_number))
		PRINT(CONCAT('Index: ', @index, ', line_number: ', @line_number))
		END


	SET @step_number = @step_number + 1
	SET @previous_index = @index_tmp
	SET @previous_line_number = @line_number_tmp
	
	IF @step_number % 1000 = 0
	    PRINT (@step_number)
END


SELECT @step_number/2 AS solution_part_1
