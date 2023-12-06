CREATE OR ALTER FUNCTION dbo.extract_special_char_with_index(@word VARCHAR(MAX), @pattern NVARCHAR(100))
RETURNS @indexes TABLE ([index] INT)
AS
BEGIN
DECLARE @index INT = PATINDEX(@pattern, @word)

WHILE @index > 0
BEGIN
	SET @word = STUFF(@word, @index, 1, '.')
	INSERT INTO @indexes ([index]) VALUES(@index)
	SET @index = PATINDEX(@pattern, @word)
END

RETURN
END
GO

CREATE OR ALTER FUNCTION dbo.extract_number_with_index_and_size(@word VARCHAR(MAX))
RETURNS @numbers TABLE ([index] INT, size INT, [value] INT)
AS
BEGIN
DECLARE @pattern VARCHAR(MAX) = '%[0-9]%'
DECLARE @index INT = PATINDEX(@pattern, @word)
DECLARE @previous_index INT = @index
DECLARE @pos INT = @index
DECLARE @size INT = 0
DECLARE @number VARCHAR(100) = ''

WHILE @index > 0
BEGIN
	IF @index - @previous_index > 1
	BEGIN
		INSERT INTO @numbers ([index], size, [value]) VALUES(@pos, @size, CAST(@number AS INT))
		SET @size = 0
		SET @number = ''
		SET @pos = -1
	END
	SET @number = CONCAT(@number, SUBSTRING(@word, @index, 1))
	SET @size = @size + 1
	SET @previous_index = @index
	IF @pos = -1
	    SET @pos = PATINDEX(@pattern, @word)
	SET @word = STUFF(@word, @index, 1, '.')
	SET @index = PATINDEX(@pattern, @word)
END

IF @number != ''
    INSERT INTO @numbers ([index], size, [value]) VALUES(@pos, @size, CAST(@number AS INT))

RETURN
END
GO

---------------------- SOLUTION ----------------------

--SELECT * FROM dbo.extract_number_with_index_and_size('14...5!..6')

IF OBJECT_ID('tempdb..#special_char_indexes') IS NOT NULL
    DROP TABLE #special_char_indexes

IF OBJECT_ID('tempdb..#star_indexes') IS NOT NULL
    DROP TABLE #star_indexes

IF OBJECT_ID('tempdb..#numbers_indexed') IS NOT NULL
    DROP TABLE #numbers_indexed

IF OBJECT_ID('tempdb..#advent_3') IS NOT NULL
    DROP TABLE #advent_3

CREATE TABLE #advent_3
(
    line_number INT
	, word NVARCHAR(MAX)
)

CREATE TABLE #special_char_indexes (line_number INT, [index] INT)
CREATE TABLE #star_indexes (line_number INT, [index] INT)
CREATE TABLE #numbers_indexed (line_number INT, [index] INT, size INT, [value] INT)

DECLARE @max_red INT = 12
DECLARE @max_green INT = 13
DECLARE @max_blue INT = 14

BULK INSERT #advent_3
   FROM 'C:\Users\Fabien\Documents\rise-again\advent-of-code-2023\advent-3-input-nb-test.txt'
   WITH (
      ROWTERMINATOR = '\n'
	  , FIELDTERMINATOR = 'A'
   );

--SELECT TOP 10 * FROM #advent_3

INSERT INTO #special_char_indexes (line_number, [index])
SELECT CAST(line_number AS INT) AS line_number
    , [index]
FROM #advent_3
    CROSS APPLY dbo.extract_special_char_with_index(word, '%[^0-9\.]%')

--SELECT TOP 10 * FROM #special_char_indexes

INSERT INTO #numbers_indexed (line_number, [index], size, [value])
SELECT CAST(line_number AS INT) AS line_number
    , [index]
	, size
	, [value]
FROM #advent_3
    CROSS APPLY dbo.extract_number_with_index_and_size(word)

--SELECT TOP 10 * FROM #numbers_indexed WHERE line_number = 2

;WITH SPARE_NUMBER AS ( 
	SELECT NI.[value]
		, NI.line_number
		, NI.[index]
	FROM #numbers_indexed NI
	JOIN #special_char_indexes SCI ON NI.line_number = SCI.line_number
	WHERE SCI.[index] = NI.[index] - 1 OR SCI.[index] = NI.[index] + size

	UNION

	SELECT NI.[value]
		, NI.line_number
		, NI.[index]
	FROM #numbers_indexed NI
	JOIN #special_char_indexes SCI ON NI.line_number + 1 = SCI.line_number
	WHERE SCI.[index] >= NI.[index] - 1 AND SCI.[index] <= NI.[index] + size

	UNION

	SELECT NI.[value]
		, NI.line_number
		, NI.[index]
	FROM #numbers_indexed NI
	JOIN #special_char_indexes SCI ON NI.line_number + -1 = SCI.line_number
	WHERE SCI.[index] >= NI.[index] - 1 AND SCI.[index] <= NI.[index] + size
)

SELECT SUM([value]) AS solution_part_1
FROM SPARE_NUMBER


INSERT INTO #star_indexes (line_number, [index])
SELECT CAST(line_number AS INT) AS line_number
    , [index]
FROM #advent_3
    CROSS APPLY dbo.extract_special_char_with_index(word, '%*%')

;WITH STAR_NUMBER AS ( 
	SELECT NI.[value]
		, NI.line_number
		, NI.[index]
		, SCI.line_number AS star_line_number
		, SCI.[index] AS star_index
	FROM #numbers_indexed NI
	JOIN #star_indexes SCI ON NI.line_number = SCI.line_number
	WHERE SCI.[index] = NI.[index] - 1 OR SCI.[index] = NI.[index] + size

	UNION

	SELECT NI.[value]
		, NI.line_number
		, NI.[index]
		, SCI.line_number AS star_line_number
		, SCI.[index] AS star_index
	FROM #numbers_indexed NI
	JOIN #star_indexes SCI ON NI.line_number + 1 = SCI.line_number
	WHERE SCI.[index] >= NI.[index] - 1 AND SCI.[index] <= NI.[index] + size

	UNION

	SELECT NI.[value]
		, NI.line_number
		, NI.[index]
		, SCI.line_number AS star_line_number
		, SCI.[index] AS star_index
	FROM #numbers_indexed NI
	JOIN #star_indexes SCI ON NI.line_number + -1 = SCI.line_number
	WHERE SCI.[index] >= NI.[index] - 1 AND SCI.[index] <= NI.[index] + size
)

, STAR_NUMBER_COUNT AS (
	SELECT [value]
	    , star_line_number
		, star_index
		, COUNT(1) OVER(PARTITION BY star_line_number, star_index) AS total_number
		, ROW_NUMBER() OVER(PARTITION BY star_line_number, star_index ORDER BY [value]) AS id_number
	FROM STAR_NUMBER
)

, GEAR_NUMBER AS (
	SELECT S1.[value] * S2.[value] AS gear_ratio
		, S1.id_number

	FROM STAR_NUMBER_COUNT S1
	LEFT JOIN STAR_NUMBER_COUNT S2 ON S1.star_line_number = S2.star_line_number 
		AND S1.star_index = S2.star_index
		AND S1.id_number = S2.id_number - 1
	WHERE S1.total_number = 2
)

SELECT SUM(gear_ratio) AS solution_part_2
FROM GEAR_NUMBER
WHERE id_number = 1


IF OBJECT_ID('tempdb..#special_char_indexes') IS NOT NULL
    DROP TABLE #special_char_indexes

IF OBJECT_ID('tempdb..#star_indexes') IS NOT NULL
    DROP TABLE #star_indexes

IF OBJECT_ID('tempdb..#advent_3') IS NOT NULL
    DROP TABLE #advent_3
