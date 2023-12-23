IF OBJECT_ID('tempdb..#advent_8_input') IS NOT NULL
    DROP TABLE #advent_8_input

IF OBJECT_ID('tempdb..#map') IS NOT NULL
    DROP TABLE #map

IF OBJECT_ID('tempdb..#direction') IS NOT NULL
    DROP TABLE #direction

IF OBJECT_ID('tempdb..#node_to_move') IS NOT NULL
    DROP TABLE #node_to_move

IF OBJECT_ID('tempdb..#node_tmp') IS NOT NULL
    DROP TABLE #node_tmp

----------------- DATA CLEANING -----------------
CREATE TABLE #advent_8_input ([line] VARCHAR(MAX))
BULK INSERT #advent_8_input FROM 'C:\Users\Fabien\Documents\rise-again\advent-of-code-2023\advent-8-input.txt'
--BULK INSERT #advent_8_input FROM 'C:\Users\Fabien\Documents\rise-again\advent-of-code-2023\advent-8-input-sample-part-2.txt'

-- We build the direction table with index in order to iterate on this table to find the position
-- The direction column stores the move (R OR L) to process, and the index is used for the order
SELECT SUBSTRING(A.line, S.number+1, 1) AS letter
	, S.number+1 AS [index]

INTO #direction

FROM #advent_8_input A
JOIN master..spt_values S ON S.number < LEN(A.line)
WHERE A.line IS NOT NULL AND A.line NOT LIKE '%=%'
    AND S.[type] = 'P'

/*
We build the map table with each position, their right move and their left move
  col:    position left_move right_move
  value:  AAA      BBB       CCC
  From AAA = (BBB, CCC)
*/
CREATE TABLE #map (position VARCHAR(3), left_move VARCHAR(3), right_move VARCHAR(3))
INSERT INTO #map (position, left_move, right_move)
SELECT P.[0] AS position
    , P.[1]  AS left_move
	, P.[2]  AS right_move 

FROM (
	SELECT A.line
		, CASE WHEN N.ordinal = 1 THEN N.[value]
			   ELSE M.[value]
		  END                    AS [value]
		, COALESCE(M.ordinal, 0) AS ordinal
	FROM #advent_8_input A
		CROSS APPLY STRING_SPLIT(REPLACE(REPLACE(REPLACE(A.line, ')', ''), '(', ''), ' ', ''), '=', 1) N
		OUTER APPLY (SELECT * FROM STRING_SPLIT(N.[value], ',', 1) WHERE N.ordinal = 2) M
	WHERE A.line LIKE '%=%'
) T
PIVOT(
	MAX([value])
	FOR [ordinal] IN ([0], [1], [2])
) P


----------------- PART 1 -----------------
-- LOOP on the #direction table to find the position
DECLARE @position VARCHAR(3) = 'AAA'
DECLARE @cpt INT = 1
DECLARE @cpt_max INT = (SELECT COUNT(1) FROM #direction)
DECLARE @total_move INT = 0
DECLARE @move VARCHAR(1)

WHILE @position != 'ZZZ'
BEGIN
	-- Which direction to go ?
	SELECT @move = letter FROM #direction WHERE [index] = @cpt
	
	-- In which position are we after that move ?
	SELECT @position = CASE @move WHEN 'L' THEN left_move
	                              WHEN 'R' THEN right_move
                       END
    FROM #map
	WHERE position = @position
	
	-- Iterate to find the next direction to go, or reset the index if index = MAX(index)
	SET @cpt = CASE @cpt WHEN @cpt_max THEN 1 ELSE @cpt + 1 END
	SET @total_move = @total_move + 1
END

SELECT @total_move AS solution_part_1

-- DOES NOT WORK, need to calculate LCM because the compute is too long
----------------- PART 2 -----------------
/*
CREATE TABLE #node_tmp (position VARCHAR(3))
SELECT position INTO #node_to_move FROM #map WHERE position LIKE '%A'

DECLARE @node_number_in_Z INT = 0
DECLARE @node_number INT = (SELECT COUNT(1) FROM #map WHERE position LIKE '%A')
DECLARE @nodes_init VARCHAR(MAX)
DECLARE @nodes VARCHAR(MAX)
SELECT @nodes_init = STRING_AGG(position, ', ') FROM #node_to_move

CREATE CLUSTERED INDEX index1 ON #map (position)

DECLARE @t1 DATETIME
SET @t1 = GETDATE()
WHILE @node_number_in_Z != @node_number
BEGIN
	-- Which direction to go ?
	SELECT @move = letter FROM #direction WHERE [index] = @cpt
	
	-- In which position are we after that move ?
	INSERT INTO #node_tmp (position)
	SELECT CASE @move WHEN 'L' THEN M.left_move
	                  WHEN 'R' THEN M.right_move
           END AS position
	FROM #map M
	JOIN #node_to_move NTM ON M.position = NTM.position
	
	TRUNCATE TABLE #node_to_move
	INSERT INTO #node_to_move (position) SELECT position FROM #node_tmp
	TRUNCATE TABLE #node_tmp

	-- Iterate to find the next direction to go, or reset the index if index = MAX(index)
	SET @cpt = CASE @cpt WHEN @cpt_max THEN 1 ELSE @cpt + 1 END
	SET @total_move = @total_move + 1
	SELECT @node_number_in_Z = COUNT(1) FROM #node_to_move WHERE position LIKE '%Z'
END

SELECT @total_move AS solution_part_2
*/

IF OBJECT_ID('tempdb..#advent_8_input') IS NOT NULL
    DROP TABLE #advent_8_input

IF OBJECT_ID('tempdb..#map') IS NOT NULL
    DROP TABLE #map

IF OBJECT_ID('tempdb..#direction') IS NOT NULL
    DROP TABLE #direction

IF OBJECT_ID('tempdb..#node_to_move') IS NOT NULL
    DROP TABLE #node_to_move

IF OBJECT_ID('tempdb..#node_tmp') IS NOT NULL
    DROP TABLE #node_tmp
