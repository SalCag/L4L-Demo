WITH [Source]
AS
(SELECT [St].[StoreKey]
        ,[St].[GeographyKey]
        ,[St].[Status]
        ,DATEADD(yyyy, 13, CONVERT(date, [St].[OpenDate])) AS  [OpenDate]
    FROM [dbo].[DimStore]   AS  [St]
        INNER JOIN [dbo].[DimGeography]     AS  [G]
            ON [G].[GeographyKey] = [St].[GeographyKey]
        WHERE [G].[RegionCountryName] = 'Italy')
, [Result]
AS
(SELECT [StoreKey]
        ,[GeographyKey]
        ,CASE [StoreKey]
            WHEN 223
                THEN CONVERT(date, '20240701')
            WHEN 224
                THEN CONVERT(date, '20240531')
            WHEN 226
                THEN CONVERT(date, '20241031')
            ELSE [OpenDate]
         END                AS  [OpenDate]
        ,CASE [StoreKey]
            WHEN 222
                THEN CONVERT(date, '20240831')
            WHEN 223
                THEN CONVERT(date, '20240331')
            ELSE CONVERT(date, '20301231')
         END                AS  [CloseDate]
        ,CASE [StoreKey]
            WHEN 224
                THEN 2  --  Opening
            WHEN 226
                THEN 2  --  Opening
            WHEN 222
                THEN 3  --  Closing
            WHEN 223
                THEN 4  --  Renew
            ELSE 1      --  Comparable
         END                AS  [L4L_Status_Src]
    FROM [Source]
    )
SELECT [StoreKey]
        ,[GeographyKey]
        ,[OpenDate]
        ,[CloseDate]
        ,EOMONTH([OpenDate])    AS  [OpenDate_EOM]
        ,EOMONTH([CloseDate])   AS  [CloseDate_EOM]
        ,[L4L_Status_Src]
    FROM [Result]
ORDER BY [StoreKey]
            ,[OpenDate];



