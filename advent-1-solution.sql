CREATE OR ALTER FUNCTION dbo.replace_word_by_number(@word AS NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
BEGIN

DECLARE @len INT= LEN(@word)
DECLARE @iter INT = 5
DECLARE @to_replace NVARCHAR(MAX)

WHILE @iter < @len
BEGIN
    SET @to_replace = SUBSTRING(@word, 1, @iter)
	SET @to_replace = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@to_replace, 'one', '1'), 'two', '2'), 'three', '3'), 'four', '4'), 'five', '5'), 'six', '6'), 'seven', '7'), 'eight', '8'), 'nine', '9')
	SET @word = CONCAT(@to_replace, SUBSTRING(@word, @iter + 1, @len))
	SET @iter = @iter + 1
END

RETURN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@word, 'one', '1'), 'two', '2'), 'three', '3'), 'four', '4'), 'five', '5'), 'six', '6'), 'seven', '7'), 'eight', '8'), 'nine', '9')
END
GO

--------------

CREATE OR ALTER FUNCTION dbo.replace_word_by_number_reverse(@word AS NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
BEGIN

DECLARE @len INT= LEN(@word)
DECLARE @iter INT = 5
DECLARE @to_replace NVARCHAR(MAX)
SET @word = REVERSE(@word)

WHILE @iter < @len
BEGIN
    SET @to_replace = SUBSTRING(@word, 1, @iter)
	SET @to_replace = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@to_replace, REVERSE('one'), '1'), REVERSE('two'), '2'), REVERSE('three'), '3'), REVERSE('four'), '4'), REVERSE('five'), '5'), REVERSE('six'), '6'), REVERSE('seven'), '7'), REVERSE('eight'), '8'), REVERSE('nine'), '9')
	SET @word = CONCAT(@to_replace, SUBSTRING(@word, @iter + 1, @len))
	SET @iter = @iter + 1
END

SET @word = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@word, REVERSE('one'), '1'), REVERSE('two'), '2'), REVERSE('three'), '3'), REVERSE('four'), '4'), REVERSE('five'), '5'), REVERSE('six'), '6'), REVERSE('seven'), '7'), REVERSE('eight'), '8'), REVERSE('nine'), '9')

RETURN REVERSE(@word)
END
GO

--------------------------------------------------

IF OBJECT_ID('tempdb..#advent_1') IS NOT NULL
    DROP TABLE #advent_1

IF OBJECT_ID('tempdb..#advent_1_part_2') IS NOT NULL
    DROP TABLE #advent_1_part_2

CREATE TABLE #advent_1
(
    word NVARCHAR(MAX)
)

BULK INSERT #advent_1
   FROM 'C:\Users\Fabien\Documents\rise-again\advent-of-code-2023\advent-1-input.txt'
   WITH (
      ROWTERMINATOR = '\n'
   );

DECLARE @pattern VARCHAR(MAX) = '%[0-9]%'

SELECT SUM(TRY_CONVERT(INT, CONCAT(SUBSTRING(word, PATINDEX(@pattern, word), 1), SUBSTRING(REVERSE(word), PATINDEX(@pattern, REVERSE(word)), 1)))) AS solution_part_1
FROM #advent_1

--- PART 2 ---

SELECT dbo.replace_word_by_number(word) AS word
    , dbo.replace_word_by_number_reverse(word) AS word_reverse
INTO #advent_1_part_2
FROM #advent_1

SELECT SUM(TRY_CONVERT(INT, CONCAT(SUBSTRING(word, PATINDEX(@pattern, word), 1), SUBSTRING(REVERSE(word_reverse), PATINDEX(@pattern, REVERSE(word_reverse)), 1)))) AS solution_part_2
FROM #advent_1_part_2

IF OBJECT_ID('tempdb..#advent_1') IS NOT NULL
    DROP TABLE #advent_1

IF OBJECT_ID('tempdb..#advent_1_part_2') IS NOT NULL
    DROP TABLE #advent_1_part_2


