IF OBJECT_ID('tempdb..#advent_7_input') IS NOT NULL
    DROP TABLE #advent_7_input

IF OBJECT_ID('tempdb..#advent_7') IS NOT NULL
    DROP TABLE #advent_7

IF OBJECT_ID('tempdb..#card_value') IS NOT NULL
    DROP TABLE #card_value

IF OBJECT_ID('tempdb..#hand_ordering_value') IS NOT NULL
    DROP TABLE #hand_ordering_value

IF OBJECT_ID('tempdb..#hand_value') IS NOT NULL
    DROP TABLE #hand_value

IF OBJECT_ID('tempdb..#hand_card_to_replace') IS NOT NULL
    DROP TABLE #hand_card_to_replace

IF OBJECT_ID('tempdb..#new_hand') IS NOT NULL
	DROP TABLE #new_hand

----------------- PART 1 -----------------
CREATE TABLE #card_value ([card] VARCHAR(2), [value] INT)
INSERT INTO #card_value ([card], [value]) VALUES ('A', 13)
	, ('K', 12)
	, ('Q', 11)
	, ('J', 10)
	, ('T', 9)
	, ('9', 8)
	, ('8', 7)
	, ('7', 6)
	, ('6', 5)
	, ('5', 4)
	, ('4', 3)
	, ('3', 2)
	, ('2', 1)

CREATE TABLE #advent_7_input ([hand] VARCHAR(MAX), number INT)
BULK INSERT #advent_7_input FROM 'C:\Users\Fabien\Documents\rise-again\advent-of-code-2023\advent-7-input.txt'
WITH (FIELDTERMINATOR = ' ')


-- Set the score for each hand based on the ordering rule
-- We use a base 13 space (maximum power 4 because there are 5 cards)
SELECT A.hand AS hand
	, SUM(C.[value] * POWER(13, (4-S.number))) AS hand_value

INTO #hand_ordering_value

FROM #advent_7_input A
JOIN master..spt_values S ON S.number < LEN(A.hand)
JOIN #card_value C ON SUBSTRING(A.hand, S.number+1, 1) = C.[card]
WHERE S.[type] = 'P'
GROUP BY hand

-- Set the score for each hand based on the type rule (five of a kind, full house, etc...)
-- We use a count per card to from a key:
--   five of a kind is 5
--   four of a kind is 41
--   2 pairs is 221
--   etc...
-- Because this rule is the most important, we add the score to the base 14 power 5 (more points than the ordering rule)
;WITH CTE_SPLIT AS (
	SELECT A.hand AS hand
		, SUBSTRING(A.hand, S.number+1, 1) AS hand_card

	FROM #advent_7_input A
	JOIN master..spt_values S ON S.number < LEN(A.hand)
	JOIN #card_value C ON SUBSTRING(A.hand, S.number+1, 1) = C.[card]
	WHERE S.[type] = 'P'
)
, CTE_COUNT AS (
	SELECT hand, COUNT(hand_card) AS card_count
	FROM CTE_SPLIT
	GROUP BY hand, hand_card
)
SELECT hand
    , CASE STRING_AGG(card_count, '') WITHIN GROUP (ORDER BY card_count DESC) 
	      WHEN '5'     THEN 6
		  WHEN '41'    THEN 5
		  WHEN '32'    THEN 4
		  WHEN '311'   THEN 3
		  WHEN '221'   THEN 2
		  WHEN '2111'  THEN 1
		  WHEN '11111' THEN 0
		  ELSE CONVERT(INT, 'A different hand has been found')

	  END * POWER(13, 5) AS hand_type_point

INTO #hand_value

FROM CTE_COUNT
GROUP BY hand

-- Then we add the scores together, rank it and calculate the total winning
;WITH CTE_RANK AS (
SELECT HOV.hand
	, A.number AS bid
	, ROW_NUMBER() OVER(ORDER BY HOV.hand_value + HV.hand_type_point ASC) AS hand_rank
FROM #hand_ordering_value HOV
JOIN #hand_value HV ON HOV.hand = HV.hand
JOIN #advent_7_input A ON HOV.hand = A.hand
)

SELECT SUM(bid * hand_rank) AS solution_part_1
FROM CTE_RANK
GO

----------------- PART 2 -----------------
TRUNCATE TABLE #card_value
INSERT INTO #card_value ([card], [value]) VALUES ('A', 13)
	, ('K', 12)
	, ('Q', 11)
	, ('T', 10)
	, ('9', 9)
	, ('8', 8)
	, ('7', 7)
	, ('6', 6)
	, ('5', 5)
	, ('4', 4)
	, ('3', 3)
	, ('2', 2)
	, ('J', 1)

-- Again, set the score for each hand based on the ordering rule
DROP TABLE #hand_ordering_value
SELECT A.hand AS hand
	, SUM(C.[value] * POWER(13, (4-S.number))) AS hand_value

INTO #hand_ordering_value

FROM #advent_7_input A
JOIN master..spt_values S ON S.number < LEN(A.hand)
JOIN #card_value C ON SUBSTRING(A.hand, S.number+1, 1) = C.[card]
WHERE S.[type] = 'P'
GROUP BY hand

-- Build table with hand card to replace for Joker
;WITH CTE_SPLIT AS (
	SELECT A.hand AS hand
		, SUBSTRING(A.hand, S.number+1, 1) AS hand_card

	FROM #advent_7_input A
	JOIN master..spt_values S ON S.number < LEN(A.hand)
	JOIN #card_value C ON SUBSTRING(A.hand, S.number+1, 1) = C.[card]
	WHERE S.[type] = 'P' AND A.hand LIKE '%J%'
)
, CTE_COUNT AS (
	SELECT hand, hand_card, COUNT(hand_card) AS card_count
	FROM CTE_SPLIT
	GROUP BY hand, hand_card
)
, CTE_CARD_MAX_COUNT AS (
	SELECT hand, hand_card
	    , ROW_NUMBER() OVER(PARTITION BY hand ORDER BY card_count DESC) AS count_rank
	FROM CTE_COUNT
	WHERE hand_card != 'J'
)

SELECT hand, hand_card AS hand_card_to_replace 

INTO #hand_card_to_replace

FROM CTE_CARD_MAX_COUNT
WHERE count_rank = 1

-- Build table with new hand
SELECT A.hand AS original_hand
    , COALESCE(REPLACE(A.hand, 'J', hand_card_to_replace), A.hand) AS hand

INTO #new_hand

FROM #advent_7_input A
LEFT JOIN #hand_card_to_replace HCTR ON A.hand = HCTR.hand

DROP TABLE #hand_value
;WITH CTE_SPLIT AS (
	SELECT A.hand AS hand
		, SUBSTRING(A.hand, S.number+1, 1) AS hand_card
		, A.original_hand AS original_hand

	FROM #new_hand A
	JOIN master..spt_values S ON S.number < LEN(A.hand)
	JOIN #card_value C ON SUBSTRING(A.hand, S.number+1, 1) = C.[card]
	WHERE S.[type] = 'P'
)
, CTE_COUNT AS (
	SELECT hand, original_hand, COUNT(hand_card) AS card_count
	FROM CTE_SPLIT
	GROUP BY hand, hand_card, original_hand
)
SELECT hand
    , original_hand
    , CASE STRING_AGG(card_count, '') WITHIN GROUP (ORDER BY card_count DESC) 
	      WHEN '5'     THEN 6
		  WHEN '41'    THEN 5
		  WHEN '32'    THEN 4
		  WHEN '311'   THEN 3
		  WHEN '221'   THEN 2
		  WHEN '2111'  THEN 1
		  WHEN '11111' THEN 0
		  ELSE CONVERT(INT, 'A different hand has been found')

	  END * POWER(13, 5) AS hand_type_point

INTO #hand_value

FROM CTE_COUNT
GROUP BY hand, original_hand
GO


;WITH CTE_RANK AS (
SELECT HOV.hand
	, A.number AS bid
	, ROW_NUMBER() OVER(ORDER BY HOV.hand_value + HV.hand_type_point ASC) AS hand_rank

FROM #hand_ordering_value HOV
JOIN #hand_value HV ON HOV.hand = HV.original_hand
JOIN #advent_7_input A ON HOV.hand = A.hand

)
SELECT SUM(bid * hand_rank) AS solution_part_2
FROM CTE_RANK


IF OBJECT_ID('tempdb..#advent_7_input') IS NOT NULL
    DROP TABLE #advent_7_input

IF OBJECT_ID('tempdb..#advent_7') IS NOT NULL
    DROP TABLE #advent_7

IF OBJECT_ID('tempdb..#card_value') IS NOT NULL
    DROP TABLE #card_value

IF OBJECT_ID('tempdb..#hand_ordering_value') IS NOT NULL
    DROP TABLE #hand_ordering_value

IF OBJECT_ID('tempdb..#hand_value') IS NOT NULL
    DROP TABLE #hand_value

IF OBJECT_ID('tempdb..#hand_card_to_replace') IS NOT NULL
    DROP TABLE #hand_card_to_replace

IF OBJECT_ID('tempdb..#new_hand') IS NOT NULL
	DROP TABLE #new_hand
