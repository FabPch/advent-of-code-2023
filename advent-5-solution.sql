-- First you need to split the file in several parts (seeds, seed-to-soil, etc...)
IF OBJECT_ID('dbo.advent_5_input') IS NOT NULL
    DROP TABLE dbo.advent_5_input

CREATE TABLE dbo.advent_5_input (number VARCHAR(MAX));
GO

CREATE OR ALTER FUNCTION dbo.get_clean_input()
RETURNS TABLE
AS
RETURN
(WITH CTE AS (
	SELECT number, ROW_NUMBER() OVER(ORDER BY number) AS line_number 
	FROM dbo.advent_5_input
)

, CTE_2 AS (
    SELECT CTE.line_number
		, N.[value]
		, CASE N.ordinal WHEN 1 THEN 'destination'
						 WHEN 2 THEN 'source'
						 WHEN 3 THEN 'range'
		  END AS [type]

	FROM CTE
		CROSS APPLY STRING_SPLIT(number, ' ', 1) N
)


SELECT CAST(P.destination AS BIGINT) AS destination
    , CAST(P.[source] AS BIGINT) AS [source]
	, CAST(P.[range] AS BIGINT) AS [range]
	, P.line_number

FROM
(
  SELECT
    [type]
    , [value]
	, line_number
  FROM CTE_2
) E
PIVOT(
  MAX([value])
  FOR [type] IN ([destination], [source], [range])
) P
)

GO

IF OBJECT_ID('tempdb..#advent_5') IS NOT NULL
    DROP TABLE #advent_5

IF OBJECT_ID('tempdb..#advent_5_seed') IS NOT NULL
    DROP TABLE #advent_5_seed

IF OBJECT_ID('tempdb..#advent_5_seed_to_soil') IS NOT NULL
    DROP TABLE #advent_5_seed_to_soil

IF OBJECT_ID('tempdb..#advent_5_soil_to_fertilizer') IS NOT NULL
    DROP TABLE #advent_5_soil_to_fertilizer

IF OBJECT_ID('tempdb..#advent_5_fertilizer_to_water') IS NOT NULL
    DROP TABLE #advent_5_fertilizer_to_water

IF OBJECT_ID('tempdb..#advent_5_water_to_light') IS NOT NULL
    DROP TABLE #advent_5_water_to_light

IF OBJECT_ID('tempdb..#advent_5_light_to_temperature') IS NOT NULL
    DROP TABLE #advent_5_light_to_temperature

IF OBJECT_ID('tempdb..#advent_5_temperature_to_humidity') IS NOT NULL
    DROP TABLE #advent_5_temperature_to_humidity

IF OBJECT_ID('tempdb..#advent_5_humidity_to_location') IS NOT NULL
    DROP TABLE #advent_5_humidity_to_location

BULK INSERT advent_5_input FROM 'C:\Users\Fabien\Documents\rise-again\advent-of-code-2023\advent-5-input-seeds.txt'
SELECT N.* INTO #advent_5_seed FROM advent_5_input CROSS APPLY string_split(number, ' ', 1) N

--SELECT * FROM #advent_5_seed

TRUNCATE TABLE advent_5_input
BULK INSERT advent_5_input FROM 'C:\Users\Fabien\Documents\rise-again\advent-of-code-2023\advent-5-input-seed-to-soil.txt' WITH(ROWTERMINATOR = '\n');
SELECT * INTO #advent_5_seed_to_soil FROM dbo.get_clean_input()

TRUNCATE TABLE advent_5_input
BULK INSERT advent_5_input FROM 'C:\Users\Fabien\Documents\rise-again\advent-of-code-2023\advent-5-input-soil-to-fertilizer.txt' WITH(ROWTERMINATOR = '\n');
SELECT * INTO #advent_5_soil_to_fertilizer FROM dbo.get_clean_input()

TRUNCATE TABLE advent_5_input
BULK INSERT advent_5_input FROM 'C:\Users\Fabien\Documents\rise-again\advent-of-code-2023\advent-5-input-fertilizer-to-water.txt' WITH(ROWTERMINATOR = '\n');
SELECT * INTO #advent_5_fertilizer_to_water FROM dbo.get_clean_input()

TRUNCATE TABLE advent_5_input
BULK INSERT advent_5_input FROM 'C:\Users\Fabien\Documents\rise-again\advent-of-code-2023\advent-5-input-water-to-light.txt' WITH(ROWTERMINATOR = '\n');
SELECT * INTO #advent_5_water_to_light FROM dbo.get_clean_input()

TRUNCATE TABLE advent_5_input
BULK INSERT advent_5_input FROM 'C:\Users\Fabien\Documents\rise-again\advent-of-code-2023\advent-5-input-light-to-temperature.txt' WITH(ROWTERMINATOR = '\n');
SELECT * INTO #advent_5_light_to_temperature FROM dbo.get_clean_input()

TRUNCATE TABLE advent_5_input
BULK INSERT advent_5_input FROM 'C:\Users\Fabien\Documents\rise-again\advent-of-code-2023\advent-5-input-temperature-to-humidity.txt' WITH(ROWTERMINATOR = '\n');
SELECT * INTO #advent_5_temperature_to_humidity FROM dbo.get_clean_input()

TRUNCATE TABLE advent_5_input
BULK INSERT advent_5_input FROM 'C:\Users\Fabien\Documents\rise-again\advent-of-code-2023\advent-5-input-humidity-to-location.txt' WITH(ROWTERMINATOR = '\n');
SELECT * INTO #advent_5_humidity_to_location FROM dbo.get_clean_input()

;WITH SOIL AS (
SELECT S.[value] AS seed_value
	, S.[value] + (COALESCE(STS.destination, 0) - COALESCE(STS.[source], 0)) AS soil_value
FROM #advent_5_seed S
LEFT JOIN #advent_5_seed_to_soil STS ON S.[value] >= STS.[source] AND S.[value] < STS.[source] + STS.[range]
)

, FERTILIZER AS (
SELECT SOIL.soil_value
	, SOIL.soil_value + (COALESCE(STF.destination, 0) - COALESCE(STF.[source], 0)) AS fertilizer_value
FROM SOIL
LEFT JOIN #advent_5_soil_to_fertilizer STF ON SOIL.soil_value >= STF.[source] AND SOIL.soil_value < STF.[source] + STF.[range]
)

, WATER AS (
SELECT FERTILIZER.fertilizer_value
    , FERTILIZER.fertilizer_value + (COALESCE(FTW.destination, 0) - COALESCE(FTW.[source], 0)) AS water_value
FROM FERTILIZER
LEFT JOIN #advent_5_fertilizer_to_water FTW ON FERTILIZER.fertilizer_value >= FTW.[source] AND FERTILIZER.fertilizer_value < FTW.[source] + FTW.[range]
)

, LIGHT AS (
SELECT WATER.water_value
    , WATER.water_value + (COALESCE(WTL.destination, 0) - COALESCE(WTL.[source], 0)) AS light_value
FROM WATER
LEFT JOIN #advent_5_water_to_light WTL ON WATER.water_value >= WTL.[source] AND WATER.water_value < WTL.[source] + WTL.[range]
)

, TEMPERATURE AS (
SELECT LIGHT.light_value
    , LIGHT.light_value + (COALESCE(LTT.destination, 0) - COALESCE(LTT.[source], 0)) AS temperature_value
FROM LIGHT
LEFT JOIN #advent_5_light_to_temperature LTT ON LIGHT.light_value >= LTT.[source] AND LIGHT.light_value < LTT.[source] + LTT.[range]
)

, HUMIDITY AS (
SELECT TEMPERATURE.temperature_value
    , TEMPERATURE.temperature_value + (COALESCE(TTH.destination, 0) - COALESCE(TTH.[source], 0)) AS humidity_value
FROM TEMPERATURE
LEFT JOIN #advent_5_temperature_to_humidity TTH ON TEMPERATURE.temperature_value >= TTH.[source] AND TEMPERATURE.temperature_value < TTH.[source] + TTH.[range]
)

SELECT MIN(HUMIDITY.humidity_value + (COALESCE(HTL.destination, 0) - COALESCE(HTL.[source], 0))) AS solution_part_1
FROM HUMIDITY
LEFT JOIN #advent_5_humidity_to_location HTL ON HUMIDITY.humidity_value >= HTL.[source] AND HUMIDITY.humidity_value < HTL.[source] + HTL.[range]

IF OBJECT_ID('tempdb..#advent_5_seed') IS NOT NULL
    DROP TABLE #advent_5_seed

IF OBJECT_ID('tempdb..#advent_5_seed_to_soil') IS NOT NULL
    DROP TABLE #advent_5_seed_to_soil

IF OBJECT_ID('tempdb..#advent_5_soil_to_fertilizer') IS NOT NULL
    DROP TABLE #advent_5_soil_to_fertilizer

IF OBJECT_ID('tempdb..#advent_5_fertilizer_to_water') IS NOT NULL
    DROP TABLE #advent_5_fertilizer_to_water

IF OBJECT_ID('tempdb..#advent_5_water_to_light') IS NOT NULL
    DROP TABLE #advent_5_water_to_light

IF OBJECT_ID('tempdb..#advent_5_light_to_temperature') IS NOT NULL
    DROP TABLE #advent_5_light_to_temperature

IF OBJECT_ID('tempdb..#advent_5_temperature_to_humidity') IS NOT NULL
    DROP TABLE #advent_5_temperature_to_humidity

IF OBJECT_ID('tempdb..#advent_5_humidity_to_location') IS NOT NULL
    DROP TABLE #advent_5_humidity_to_location
