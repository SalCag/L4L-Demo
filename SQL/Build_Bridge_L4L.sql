SET NOCOUNT ON;

-- CLeanup before run
IF OBJECT_ID('tempdb..#tmp_Store_Dates') IS NOT NULL
BEGIN
    PRINT 'DROP TABLE [#tmp_Store_Dates];';
    DROP TABLE [#tmp_Store_Dates];
END

-- Crate table to hold the Stores with their Opening and CLosing Dates together with the L4LKey to assign
CREATE TABLE [#tmp_Store_Dates]
(
	[StoreKey] [int] NOT NULL,
	[OpenDate] [date] NULL,
	[CloseDate] [date] NULL,
	[L4LKey] [int] NOT NULL
);

-- Insert the Stores with their Opening and CLosing Dates together with the L4LKey to assign
WITH [Source]
AS
(SELECT [St].[StoreKey]
        --,[St].[GeographyKey]
        ,[St].[Status]
        ,DATEADD(yyyy, 13, CONVERT(date, [St].[OpenDate])) AS  [OpenDate]
    FROM [dbo].[DimStore]   AS  [St]
        INNER JOIN [dbo].[DimGeography]     AS  [G]
            ON [G].[GeographyKey] = [St].[GeographyKey]
        WHERE [G].[RegionCountryName] = 'Italy')
, [Store_Dates]
AS
(SELECT [StoreKey]
        --,[GeographyKey]
        ,CASE [StoreKey]
            WHEN 225
                THEN CONVERT(date, '20240713')
            WHEN 224
                THEN CONVERT(date, '20240524')
            WHEN 226
                THEN CONVERT(date, '20241018')
            ELSE [OpenDate]
         END                AS  [OpenDate]
        ,CASE [StoreKey]
            WHEN 222
                THEN CONVERT(date, '20240818')
            WHEN 225
                THEN CONVERT(date, '20240303')
            ELSE CONVERT(date, '20301231')
         END                AS  [CloseDate]
        ,CASE [StoreKey]
            WHEN 224
                THEN 2  --  Opening
            WHEN 226
                THEN 2  --  Opening
            WHEN 222
                THEN 3  --  Closing
            WHEN 225
                THEN 4  --  Refresh
            ELSE 1      --  Comparable
         END                AS  [L4LKey]
    FROM [Source]
    UNION ALL
    SELECT [StoreKey]
            ,CONVERT(date, '20231013')  AS  [OpenDate]
            ,CONVERT(date, '20230814')  AS  [CloseDate]
            ,4                          AS  [L4LKey]
        FROM [Source]
            WHERE [StoreKey] = 222
    )
INSERT INTO [#tmp_Store_Dates]
           ([StoreKey]
           ,[OpenDate]
           ,[CloseDate]
           ,[L4LKey])
SELECT [StoreKey]
        ,[OpenDate]
        ,[CloseDate]
        ,[L4LKey]
    FROM [Store_Dates];



-- Start Update procedure


-- Cle3anup temporary table for all the Stores with all Months
IF OBJECT_ID('tempdb..#tmp_Stores_Months') IS NOT NULL
BEGIN
    PRINT 'DROP TABLE [#tmp_Stores_Months];';
    DROP TABLE [#tmp_Stores_Months];
END

CREATE TABLE [#tmp_Stores_Months]
(
	[StoreKey]          int NOT NULL,
	[OpenDate]          date NULL,
	[CloseDate]         date NULL,
	[L4LKey]            int NULL,
	[L4LKey_PY]         int NULL,
	[MonthKey]          int NULL,
	[MonthKeyPY]        int NULL,
	[FirstDayOfMonth]   date NULL,
	[LastDayOfMonth]    date NULL,
	[FirstDayOfMonthPY] date NULL,
	[LastDayOfMonthPY]  date NULL
);


-- Insert all Stores with CROSS APPLY all Months
WITH [Stores]
AS
-- Get all Stores
(SELECT [St].[StoreKey]
        ,NULL               AS  [OpenDate]
        ,NULL               AS  [CloseDate]
        ,NULL               AS  [L4LKey]
        ,NULL               AS  [L4LKey_PY]
    FROM [dbo].[DimStore]   AS  [St])
, [Months]
AS
(
-- Get all Months
SELECT DISTINCT 
      [MonthKey] + 1600                         AS  [MonthKey]
      ,[MonthKeyPY] + 1600                      AS  [MonthKeyPY]
      ,DATEADD(yyyy, 16, [FirstDayOfMonth]  )   AS  [FirstDayOfMonth]
      ,DATEADD(yyyy, 16, [LastDayOfMonth]   )   AS  [LastDayOfMonth]
      ,DATEADD(yyyy, 16, [FirstDayOfMonthPY])   AS  [FirstDayOfMonthPY]
      ,DATEADD(yyyy, 16, [LastDayOfMonthPY] )   AS  [LastDayOfMonthPY]
  FROM [dbo].[Date])
INSERT INTO [#tmp_Stores_Months]
           ([StoreKey]
           ,[OpenDate]
           ,[CloseDate]
           ,[L4LKey]
           ,[L4LKey_PY]
           ,[MonthKey]
           ,[MonthKeyPY]
           ,[FirstDayOfMonth]
           ,[LastDayOfMonth]
           ,[FirstDayOfMonthPY]
           ,[LastDayOfMonthPY])
-- CROSS APPLY all Stores with all Months to get the complete list of rows
SELECT [S].[StoreKey]
        ,[S].[OpenDate]
        ,[S].[CloseDate]
        ,[S].[L4LKey]
        ,[S].[L4LKey_PY]
        ,[M].[MonthKey]
        ,[M].[MonthKeyPY]
        ,[M].[FirstDayOfMonth]
        ,[M].[LastDayOfMonth]
        ,[M].[FirstDayOfMonthPY]
        ,[M].[LastDayOfMonthPY]
    FROM [Stores]           AS  [S]
        CROSS JOIN [Months] AS  [M];

-- Declare all needed variables
DECLARE @StoreKey       int;
DECLARE @OpenDate       date;
DECLARE @CloseDate      date;
DECLARE @L4LKey         int;

-- Create the Cursor to loop through the Stores with each opening. closing and refresh dates
DECLARE sd CURSOR FOR
    SELECT [StoreKey]
            ,[OpenDate]
            ,[CloseDate]
            ,[L4LKey]
        FROM #tmp_Store_Dates
            -- Order the the CLosing date, as the procedure must run from the first (oldest) to the last (newest) row
            ORDER BY [CloseDate];

OPEN sd;

-- Get the first row
FETCH NEXT FROM sd INTO @StoreKey, @OpenDate, @CloseDate, @L4LKey;

-- Start the loop
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Update all rows according to each store based on the L4L status and the respective dates fbased on the previous years dates
    UPDATE [#tmp_Stores_Months]
        SET [OpenDate] = @OpenDate
            ,[CloseDate] = @CloseDate
            ,[L4LKey] = CASE @L4LKey
                            WHEN 2
                                THEN IIF(@OpenDate >= [FirstDayOfMonthPY], @L4LKey, NULL)
                            WHEN 3
                                THEN IIF(@CloseDate <= [LastDayOfMonthPY], @L4LKey, NULL)
                            WHEN 4
                                THEN IIF(@OpenDate >= [FirstDayOfMonthPY] AND @CloseDate <= [LastDayOfMonthPY], @L4LKey, NULL)
                                ELSE 1
                            END
            WHERE [L4LKey] IS NULL
                AND [StoreKey] = @StoreKey;

-- Update based on the current month for the PY calculation
UPDATE [#tmp_Stores_Months]
        SET [OpenDate] = @OpenDate
            ,[CloseDate] = @CloseDate
            ,[L4LKey_PY] = CASE @L4LKey
                            WHEN 2
                                THEN IIF(@OpenDate >= [FirstDayOfMonth], @L4LKey, NULL)
                            WHEN 3
                                THEN IIF(@CloseDate <= [LastDayOfMonth], @L4LKey, NULL)
                            WHEN 4
                                THEN IIF(@OpenDate >= [FirstDayOfMonth] AND @CloseDate <= [LastDayOfMonth], @L4LKey, NULL)
                                ELSE 1
                            END
            WHERE [L4LKey_PY] IS NULL
                AND [StoreKey] = @StoreKey;
    
    -- Get the next row until all rows are processed
    FETCH NEXT FROM sd INTO @StoreKey, @OpenDate, @CloseDate, @L4LKey;

END

-- Close the Cursor
CLOSE sd;
DEALLOCATE sd;

-- Update the L4LKey and L4LKey_PY in all empty rows
UPDATE #tmp_Stores_Months
    SET [L4LKey] = 1
        WHERE [L4LKey] IS NULL;

UPDATE #tmp_Stores_Months
    SET [L4LKey_PY] = 1
        WHERE [L4LKey_PY] IS NULL;


-- Select the table for the Bridge_L4L table
SELECT [StoreKey]
        ,CONVERT(varchar(12), [StoreKey]) + '_' + CONVERT(varchar(12), [MonthKey])  AS  [StoreMonthKey]
        ,[L4LKey]
        ,[L4LKey_PY]
    FROM #tmp_Stores_Months
        WHERE [StoreKey] IN (222, 224, 225, 226)
            ORDER BY [StoreKey], [MonthKey];


-- Cleanup all
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('tempdb..#tmp_Stores_Months'))
BEGIN
    PRINT 'DROP TABLE [#tmp_Stores_Months];';
    DROP TABLE [#tmp_Stores_Months];
END

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('tempdb..#tmp_Store_Dates'))
BEGIN
    PRINT 'DROP TABLE [#tmp_Stores_Dates];';
    DROP TABLE [#tmp_Store_Dates];
END



/*
--- V1: Try with Single Query


WITH [Source]
AS
(SELECT [St].[StoreKey]
        --,[St].[GeographyKey]
        ,[St].[Status]
        ,DATEADD(yyyy, 13, CONVERT(date, [St].[OpenDate])) AS  [OpenDate]
    FROM [dbo].[DimStore]   AS  [St]
        INNER JOIN [dbo].[DimGeography]     AS  [G]
            ON [G].[GeographyKey] = [St].[GeographyKey]
        WHERE [G].[RegionCountryName] = 'Italy')
, [Stores_Dates]
AS
(
SELECT [StoreKey]
        --,[GeographyKey]
        ,CASE [StoreKey]
            WHEN 225
                THEN CONVERT(date, '20240713')
            WHEN 224
                THEN CONVERT(date, '20240524')
            WHEN 226
                THEN CONVERT(date, '20241018')
            ELSE [OpenDate]
         END                AS  [OpenDate]
        ,CASE [StoreKey]
            WHEN 222
                THEN CONVERT(date, '20240818')
            WHEN 225
                THEN CONVERT(date, '20240303')
            ELSE CONVERT(date, '20301231')
         END                AS  [CloseDate]
        ,CASE [StoreKey]
            WHEN 224
                THEN 2  --  Opening
            WHEN 226
                THEN 2  --  Opening
            WHEN 222
                THEN 3  --  Closing
            WHEN 225
                THEN 4  --  Refresh
            ELSE 1      --  Comparable
         END                AS  [L4LKey]
    FROM [Source]
    UNION ALL
    SELECT [StoreKey]
            ,CONVERT(date, '20231013')  AS  [OpenDate]
            ,CONVERT(date, '20230814')  AS  [CloseDate]
            ,4                          AS  [L4LKey]
        FROM [Source]
            WHERE [StoreKey] = 222
    )
, [Months]
AS
(
SELECT DISTINCT 
      [MonthKey] + 1600                         AS  [MonthKey]
      ,[MonthKeyPY] + 1600                      AS  [MonthKeyPY]
      ,DATEADD(yyyy, 16, [FirstDayOfMonth]  )   AS  [FirstDayOfMonth]
      ,DATEADD(yyyy, 16, [LastDayOfMonth]   )   AS  [LastDayOfMonth]
      ,DATEADD(yyyy, 16, [FirstDayOfMonthPY])   AS  [FirstDayOfMonthPY]
      ,DATEADD(yyyy, 16, [LastDayOfMonthPY] )   AS  [LastDayOfMonthPY]
  FROM [dbo].[Date])
, [Result]
AS
(SELECT [S].[StoreKey]
        ,[S].[OpenDate]
        ,[S].[CloseDate]
        ,[S].[L4LKey]
        ,[M].[MonthKey]
        ,[M].[MonthKeyPY]
        ,[M].[FirstDayOfMonth]
        ,[M].[LastDayOfMonth]
        ,[M].[FirstDayOfMonthPY]
        ,[M].[LastDayOfMonthPY]
        ,CASE [S].[L4LKey]
            WHEN 2
                THEN IIF([S].[OpenDate] >= [M].[FirstDayOfMonthPY], [S].[L4LKey], NULL)
            WHEN 3
                THEN IIF([S].[CloseDate] <= [M].[LastDayOfMonthPY], [S].[L4LKey], NULL)
            WHEN 4
                THEN IIF([S].[OpenDate] >= [M].[FirstDayOfMonthPY] AND [S].[CloseDate] <= [M].[LastDayOfMonthPY], [S].[L4LKey], NULL)
                ELSE 1
            END                 AS  [L4LKey_New]
        ,NULL                   AS  [L4LKeyPY_New]
    FROM [Stores_Dates]     AS  [S]
        CROSS JOIN [Months] AS  [M])
, [Result_PY]
AS
(SELECT [S].[StoreKey]
        ,[S].[OpenDate]
        ,[S].[CloseDate]
        ,[S].[L4LKey]
        ,[M].[MonthKey]
        ,[M].[MonthKeyPY]
        ,[M].[FirstDayOfMonth]
        ,[M].[LastDayOfMonth]
        ,[M].[FirstDayOfMonthPY]
        ,[M].[LastDayOfMonthPY]
        ,NULL                   AS  [L4LKey_New]
        ,CASE [S].[L4LKey]
            WHEN 2
                THEN IIF([S].[OpenDate] >= [M].[FirstDayOfMonth], [S].[L4LKey], NULL)
            WHEN 3
                THEN IIF([S].[CloseDate] <= [M].[LastDayOfMonth], [S].[L4LKey], NULL)
            WHEN 4
                THEN IIF([S].[OpenDate] >= [M].[FirstDayOfMonth] AND [S].[CloseDate] <= [M].[LastDayOfMonth], [S].[L4LKey], NULL)
                ELSE 1
            END                 AS  [L4LKeyPY_New]
    FROM [Stores_Dates]     AS  [S]
        CROSS JOIN [Months] AS  [M])
    , [AllTogether]
    AS
    (SELECT [R].[StoreKey]
            ,[R].[OpenDate]
            ,[R].[CloseDate]
            ,[R].[L4LKey]
            ,[R].[MonthKey]
            ,[R].[MonthKeyPY]
            ,[R].[FirstDayOfMonth]
            ,[R].[LastDayOfMonth]
            ,[R].[FirstDayOfMonthPY]
            ,[R].[LastDayOfMonthPY]
            ,[R].[L4LKey_New]
            ,[PY].[L4LKeyPY_New]
        FROM [Result]   AS  [R]
            INNER JOIN [Result_PY]  AS  [PY]
                ON [PY].[L4LKeyPY_New] = [R].[L4LKey_New]
     )
    SELECT DISTINCT [StoreKey]
            ,[OpenDate]
            ,[CloseDate]
            ,[L4LKey]
            ,[MonthKey]
            ,[MonthKeyPY]
            ,[FirstDayOfMonth]
            ,[LastDayOfMonth]
            ,[FirstDayOfMonthPY]
            ,[LastDayOfMonthPY]
            ,[L4LKey_New]
            ,[L4LKeyPY_New]
        FROM [AllTogether]
        WHERE [L4LKey_New] IS NOT NULL OR [L4LKeyPY_New] IS NOT NULL
        ORDER BY [StoreKey], [MonthKey]

*/