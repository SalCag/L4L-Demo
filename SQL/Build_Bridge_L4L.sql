IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('tempdb..#tmp_Stores_Months'))
BEGIN
    PRINT 'DROP TABLE [#tmp_Stores_Months];';
    DROP TABLE [#tmp_Stores_Months];
END

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('tempdb..#tmp_Store_Dates'))
BEGIN
    PRINT 'DROP TABLE [#tmp_Store_Dates];';
    DROP TABLE [#tmp_Store_Dates];
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

CREATE TABLE [#tmp_Store_Dates]
(
	[StoreKey] [int] NOT NULL,
	[OpenDate] [date] NULL,
	[CloseDate] [date] NULL,
	[L4LKey] [int] NOT NULL
);



WITH [Stores]
AS
(SELECT [St].[StoreKey]
        ,NULL               AS  [OpenDate]
        ,NULL               AS  [CloseDate]
        ,NULL               AS  [L4LKey]
        ,NULL               AS  [L4LKey_PY]
    FROM [dbo].[DimStore]   AS  [St])
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
INSERT INTO [dbo].[tmp_Stores_Months]
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


-- Cleanup
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('tempdb..#tmp_Stores_Months'))
    DROP TABLE [#tmp_Stores_Months];

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID('tempdb..#tmp_Store_Dates'))
    DROP TABLE [#tmp_Store_Dates];



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