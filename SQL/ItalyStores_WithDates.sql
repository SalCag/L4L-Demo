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
, [Result]
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
         END                AS  [L4L_Status_Src]
    FROM [Source]
    UNION ALL
    SELECT [StoreKey]
            ,CONVERT(date, '20231013')  AS  [OpenDate]
            ,CONVERT(date, '20230814')  AS  [CloseDate]
            ,4                          AS  [L4L_Status_Src]
        FROM [Source]
            WHERE [StoreKey] = 222
    )
SELECT [StoreKey]
        --,[GeographyKey]
        ,[OpenDate]
        ,[CloseDate]
        ,EOMONTH([OpenDate])    AS  [OpenDate_EOM]
        ,EOMONTH([CloseDate])   AS  [CloseDate_EOM]
        ,[L4L_Status_Src]
    FROM [Result]
    WHERE [StoreKey] != 223
ORDER BY [StoreKey]
            ,[OpenDate];

