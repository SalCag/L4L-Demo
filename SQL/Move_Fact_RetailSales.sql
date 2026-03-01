SELECT [F].[SaleLineCounter]    AS  [Sale Line Counter]
        ,CONVERT(date, DATEADD(yyyy, 16, [F].[DateKey]))     AS  [DateKey]
        ,[F].[channelKey]
        ,[F].[StoreKey]
        ,CONCAT(CONVERT(nvarchar(25), [F].[StoreKey])
                ,'_'
                ,CONVERT(nvarchar(25), YEAR([F].[DateKey]))
                ,RIGHT('00' + CONVERT(nvarchar(25), MONTH([F].[DateKey])), 2)
                )               AS  [StoreMonthKey]
        ,[F].[ProductKey]
        ,[F].[PromotionKey]
        ,[F].[CurrencyKey]
        ,[F].[UnitCost]
        ,[F].[UnitPrice]
        ,[F].[SalesQuantity]
        ,[F].[ReturnQuantity]
        ,[F].[ReturnAmount]
        ,[F].[DiscountQuantity]
        ,[F].[DiscountAmount]
        ,[F].[TotalCost]
        ,[F].[SalesAmount]
        ,[F].[DateKeyYear]
    FROM [dbo].[v_FactSales]    AS  [F];
