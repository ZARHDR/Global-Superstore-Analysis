/*
Global Superstore - SQL Analysis
Database: GlobalSuperstoreDB
Data table: dbo.superstore_sql_fixed
*/

USE GlobalSuperstoreDB;
GO

/* 01. DATASET VALIDATION */
SELECT
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT RowID) AS UniqueRowIDs
FROM dbo.superstore_sql_fixed;
GO

SELECT
    MIN(TRY_CONVERT(DATE, OrderDate)) AS FirstOrderDate,
    MAX(TRY_CONVERT(DATE, OrderDate)) AS LastOrderDate
FROM dbo.superstore_sql_fixed;
GO

/* 02. CHECK COLUMN DATA TYPES */
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'superstore_sql_fixed'
ORDER BY ORDINAL_POSITION;
GO

/* 03. YEARLY SALES, PROFIT, AND PROFIT MARGIN */
SELECT
    TRY_CONVERT(INT, [Year]) AS OrderYear,
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT OrderID) AS TotalOrders,
    SUM(TRY_CONVERT(DECIMAL(18, 4), Sales)) AS TotalSales,
    SUM(TRY_CONVERT(DECIMAL(18, 4), Profit)) AS TotalProfit,
    CAST(
        SUM(TRY_CONVERT(DECIMAL(18, 4), Profit)) * 100.0
        / NULLIF(SUM(TRY_CONVERT(DECIMAL(18, 4), Sales)), 0)
        AS DECIMAL(10, 2)
    ) AS ProfitMarginPercent
FROM dbo.superstore_sql_fixed
GROUP BY TRY_CONVERT(INT, [Year])
ORDER BY OrderYear;
GO

/* 04. YEAR-OVER-YEAR SALES GROWTH USING LAG() */
WITH YearlySales AS (
    SELECT
        TRY_CONVERT(INT, [Year]) AS OrderYear,
        SUM(TRY_CONVERT(DECIMAL(18, 4), Sales)) AS TotalSales,
        SUM(TRY_CONVERT(DECIMAL(18, 4), Profit)) AS TotalProfit
    FROM dbo.superstore_sql_fixed
    GROUP BY TRY_CONVERT(INT, [Year])
),
SalesGrowth AS (
    SELECT
        OrderYear,
        TotalSales,
        TotalProfit,
        LAG(TotalSales) OVER (ORDER BY OrderYear) AS PreviousYearSales
    FROM YearlySales
)
SELECT
    OrderYear,
    TotalSales,
    PreviousYearSales,
    TotalSales - PreviousYearSales AS SalesIncrease,
    CAST(
        (TotalSales - PreviousYearSales) * 100.0
        / NULLIF(PreviousYearSales, 0)
        AS DECIMAL(10, 2)
    ) AS SalesGrowthPercent
FROM SalesGrowth
ORDER BY OrderYear;
GO

/* 05. CHECK NON-EMPTY VALUES THAT CANNOT BE CONVERTED */
SELECT
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(18, 4), Sales) IS NULL
                  AND NULLIF(LTRIM(RTRIM(Sales)), '') IS NOT NULL
             THEN 1 ELSE 0 END) AS InvalidSalesRows,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(18, 4), Profit) IS NULL
                  AND NULLIF(LTRIM(RTRIM(Profit)), '') IS NOT NULL
             THEN 1 ELSE 0 END) AS InvalidProfitRows,
    SUM(CASE WHEN TRY_CONVERT(INT, [Year]) IS NULL
                  AND NULLIF(LTRIM(RTRIM([Year])), '') IS NOT NULL
             THEN 1 ELSE 0 END) AS InvalidYearRows
FROM dbo.superstore_sql_fixed;
GO

/* 06. PROFIT ANALYSIS BY SUBCATEGORY */

SELECT
    SubCategory,
    SUM(TRY_CONVERT(DECIMAL(18, 4), Sales)) AS TotalSales,
    SUM(TRY_CONVERT(DECIMAL(18, 4), Profit)) AS TotalProfit,
    SUM(TRY_CONVERT(DECIMAL(18, 4), Quantity)) AS TotalQuantity,
    COUNT(DISTINCT OrderID) AS TotalOrders
FROM dbo.superstore_sql_fixed
GROUP BY SubCategory
ORDER BY TotalProfit ASC;

/* 07. DISCOUNT AND PROFIT ANALYSIS */

SELECT
    Discount,
    COUNT(*) AS TotalRows,
    SUM(TRY_CONVERT(DECIMAL(18, 4), Sales)) AS TotalSales,
    SUM(TRY_CONVERT(DECIMAL(18, 4), Profit)) AS TotalProfit,
    AVG(TRY_CONVERT(DECIMAL(18, 4), Profit)) AS AverageProfit
FROM dbo.superstore_sql_fixed
GROUP BY Discount
ORDER BY Discount;


/* 08. PROFITABILITY BY DISCOUNT BAND */

WITH DiscountAnalysis AS (
    SELECT
        CASE
            WHEN TRY_CONVERT(DECIMAL(10, 4), Discount) < 0.10
                THEN '0% - 9.9%'
            WHEN TRY_CONVERT(DECIMAL(10, 4), Discount) < 0.20
                THEN '10% - 19.9%'
            WHEN TRY_CONVERT(DECIMAL(10, 4), Discount) < 0.30
                THEN '20% - 29.9%'
            WHEN TRY_CONVERT(DECIMAL(10, 4), Discount) < 0.40
                THEN '30% - 39.9%'
            WHEN TRY_CONVERT(DECIMAL(10, 4), Discount) < 0.50
                THEN '40% - 49.9%'
            WHEN TRY_CONVERT(DECIMAL(10, 4), Discount) < 0.60
                THEN '50% - 59.9%'
            WHEN TRY_CONVERT(DECIMAL(10, 4), Discount) < 0.70
                THEN '60% - 69.9%'
            ELSE '70% and above'
        END AS DiscountBand,
        TRY_CONVERT(DECIMAL(18, 4), Sales) AS SalesValue,
        TRY_CONVERT(DECIMAL(18, 4), Profit) AS ProfitValue
    FROM dbo.superstore_sql_fixed
)
SELECT
    DiscountBand,
    COUNT(*) AS TotalRows,
    SUM(SalesValue) AS TotalSales,
    SUM(ProfitValue) AS TotalProfit,
    CAST(
        100.0 * SUM(ProfitValue) / NULLIF(SUM(SalesValue), 0)
        AS DECIMAL(10, 2)
    ) AS ProfitMarginPercent
FROM DiscountAnalysis
GROUP BY DiscountBand
ORDER BY
    MIN(SalesValue);


/* 09. TABLES: DISCOUNT AND PROFIT ANALYSIS */

WITH TablesAnalysis AS (
    SELECT
        TRY_CONVERT(DECIMAL(10, 4), Discount) AS DiscountRate,
        TRY_CONVERT(DECIMAL(18, 4), Sales) AS SalesValue,
        TRY_CONVERT(DECIMAL(18, 4), Profit) AS ProfitValue
    FROM dbo.superstore_sql_fixed
    WHERE SubCategory = 'Tables'
)
SELECT
    CASE
        WHEN DiscountRate < 0.10 THEN '0% - 9.9%'
        WHEN DiscountRate < 0.20 THEN '10% - 19.9%'
        WHEN DiscountRate < 0.30 THEN '20% - 29.9%'
        WHEN DiscountRate < 0.40 THEN '30% - 39.9%'
        WHEN DiscountRate < 0.50 THEN '40% - 49.9%'
        WHEN DiscountRate < 0.60 THEN '50% - 59.9%'
        WHEN DiscountRate < 0.70 THEN '60% - 69.9%'
        ELSE '70% and above'
    END AS DiscountBand,
    COUNT(*) AS TotalRows,
    SUM(SalesValue) AS TotalSales,
    SUM(ProfitValue) AS TotalProfit,
    CAST(
        100.0 * SUM(ProfitValue)
        / NULLIF(SUM(SalesValue), 0)
        AS DECIMAL(10, 2)
    ) AS ProfitMarginPercent
FROM TablesAnalysis
GROUP BY
    CASE
        WHEN DiscountRate < 0.10 THEN '0% - 9.9%'
        WHEN DiscountRate < 0.20 THEN '10% - 19.9%'
        WHEN DiscountRate < 0.30 THEN '20% - 29.9%'
        WHEN DiscountRate < 0.40 THEN '30% - 39.9%'
        WHEN DiscountRate < 0.50 THEN '40% - 49.9%'
        WHEN DiscountRate < 0.60 THEN '50% - 59.9%'
        WHEN DiscountRate < 0.70 THEN '60% - 69.9%'
        ELSE '70% and above'
    END
ORDER BY MIN(DiscountRate);


/* 10. TABLES PROFITABILITY BY MARKET */

SELECT
    Market,
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT OrderID) AS TotalOrders,
    SUM(TRY_CONVERT(DECIMAL(18, 4), Sales)) AS TotalSales,
    SUM(TRY_CONVERT(DECIMAL(18, 4), Profit)) AS TotalProfit,
    CAST(
        100.0 * SUM(TRY_CONVERT(DECIMAL(18, 4), Profit))
        / NULLIF(
            SUM(TRY_CONVERT(DECIMAL(18, 4), Sales)),
            0
        )
        AS DECIMAL(10, 2)
    ) AS ProfitMarginPercent
FROM dbo.superstore_sql_fixed
WHERE SubCategory = 'Tables'
GROUP BY Market
ORDER BY TotalProfit ASC;


/* 11. TABLES: MARKET AND DISCOUNT ANALYSIS */

WITH TablesAnalysis AS (
    SELECT
        Market,
        TRY_CONVERT(DECIMAL(10, 4), Discount) AS DiscountRate,
        TRY_CONVERT(DECIMAL(18, 4), Sales) AS SalesValue,
        TRY_CONVERT(DECIMAL(18, 4), Profit) AS ProfitValue
    FROM dbo.superstore_sql_fixed
    WHERE SubCategory = 'Tables'
)
SELECT
    Market,
    CASE
        WHEN DiscountRate < 0.10 THEN '0% - 9.9%'
        WHEN DiscountRate < 0.20 THEN '10% - 19.9%'
        WHEN DiscountRate < 0.30 THEN '20% - 29.9%'
        WHEN DiscountRate < 0.40 THEN '30% - 39.9%'
        WHEN DiscountRate < 0.50 THEN '40% - 49.9%'
        WHEN DiscountRate < 0.60 THEN '50% - 59.9%'
        WHEN DiscountRate < 0.70 THEN '60% - 69.9%'
        ELSE '70% and above'
    END AS DiscountBand,
    COUNT(*) AS TotalRows,
    SUM(SalesValue) AS TotalSales,
    SUM(ProfitValue) AS TotalProfit,
    CAST(
        100.0 * SUM(ProfitValue)
        / NULLIF(SUM(SalesValue), 0)
        AS DECIMAL(10, 2)
    ) AS ProfitMarginPercent
FROM TablesAnalysis
GROUP BY
    Market,
    CASE
        WHEN DiscountRate < 0.10 THEN '0% - 9.9%'
        WHEN DiscountRate < 0.20 THEN '10% - 19.9%'
        WHEN DiscountRate < 0.30 THEN '20% - 29.9%'
        WHEN DiscountRate < 0.40 THEN '30% - 39.9%'
        WHEN DiscountRate < 0.50 THEN '40% - 49.9%'
        WHEN DiscountRate < 0.60 THEN '50% - 59.9%'
        WHEN DiscountRate < 0.70 THEN '60% - 69.9%'
        ELSE '70% and above'
    END
ORDER BY Market, MIN(DiscountRate);



/* 12. PROFITABILITY BY SUBCATEGORY AND DISCOUNT BAND */

WITH ProductDiscountAnalysis AS (
    SELECT
        SubCategory,
        TRY_CONVERT(DECIMAL(10, 4), Discount) AS DiscountRate,
        TRY_CONVERT(DECIMAL(18, 4), Sales) AS SalesValue,
        TRY_CONVERT(DECIMAL(18, 4), Profit) AS ProfitValue
    FROM dbo.superstore_sql_fixed
)
SELECT
    SubCategory,
    CASE
        WHEN DiscountRate < 0.10 THEN '0% - 9.9%'
        WHEN DiscountRate < 0.20 THEN '10% - 19.9%'
        WHEN DiscountRate < 0.30 THEN '20% - 29.9%'
        WHEN DiscountRate < 0.40 THEN '30% - 39.9%'
        WHEN DiscountRate < 0.50 THEN '40% - 49.9%'
        WHEN DiscountRate < 0.60 THEN '50% - 59.9%'
        WHEN DiscountRate < 0.70 THEN '60% - 69.9%'
        ELSE '70% and above'
    END AS DiscountBand,
    COUNT(*) AS TotalRows,
    SUM(SalesValue) AS TotalSales,
    SUM(ProfitValue) AS TotalProfit,
    CAST(
        100.0 * SUM(ProfitValue)
        / NULLIF(SUM(SalesValue), 0)
        AS DECIMAL(10, 2)
    ) AS ProfitMarginPercent
FROM ProductDiscountAnalysis
GROUP BY
    SubCategory,
    CASE
        WHEN DiscountRate < 0.10 THEN '0% - 9.9%'
        WHEN DiscountRate < 0.20 THEN '10% - 19.9%'
        WHEN DiscountRate < 0.30 THEN '20% - 29.9%'
        WHEN DiscountRate < 0.40 THEN '30% - 39.9%'
        WHEN DiscountRate < 0.50 THEN '40% - 49.9%'
        WHEN DiscountRate < 0.60 THEN '50% - 59.9%'
        WHEN DiscountRate < 0.70 THEN '60% - 69.9%'
        ELSE '70% and above'
    END
ORDER BY SubCategory, MIN(DiscountRate);


/* 13. OVERALL PROFITABILITY BY SUBCATEGORY */

SELECT
    SubCategory,
    COUNT(*) AS TotalRows,
    SUM(TRY_CONVERT(DECIMAL(18, 4), Sales)) AS TotalSales,
    SUM(TRY_CONVERT(DECIMAL(18, 4), Profit)) AS TotalProfit,
    CAST(
        100.0 * SUM(TRY_CONVERT(DECIMAL(18, 4), Profit))
        / NULLIF(
            SUM(TRY_CONVERT(DECIMAL(18, 4), Sales)),
            0
        )
        AS DECIMAL(10, 2)
    ) AS ProfitMarginPercent
FROM dbo.superstore_sql_fixed
GROUP BY SubCategory
ORDER BY TotalProfit ASC;

/* 14. RANK SUBCATEGORIES BY PROFIT MARGIN */

SELECT
    SubCategory,
    SUM(TRY_CONVERT(DECIMAL(18, 4), Sales)) AS TotalSales,
    SUM(TRY_CONVERT(DECIMAL(18, 4), Profit)) AS TotalProfit,
    CAST(
        100.0 * SUM(TRY_CONVERT(DECIMAL(18, 4), Profit))
        / NULLIF(
            SUM(TRY_CONVERT(DECIMAL(18, 4), Sales)),
            0
        )
        AS DECIMAL(10, 2)
    ) AS ProfitMarginPercent
FROM dbo.superstore_sql_fixed
GROUP BY SubCategory
ORDER BY ProfitMarginPercent DESC;


/* 15. TOP 10 MOST PROFITABLE PRODUCTS */

SELECT TOP 10
    ProductName,
    SubCategory,
    SUM(TRY_CONVERT(DECIMAL(18, 4), Sales)) AS TotalSales,
    SUM(TRY_CONVERT(DECIMAL(18, 4), Profit)) AS TotalProfit,
    CAST(
        100.0 * SUM(TRY_CONVERT(DECIMAL(18, 4), Profit))
        / NULLIF(
            SUM(TRY_CONVERT(DECIMAL(18, 4), Sales)),
            0
        )
        AS DECIMAL(10, 2)
    ) AS ProfitMarginPercent
FROM dbo.superstore_sql_fixed
GROUP BY ProductName, SubCategory
ORDER BY TotalProfit DESC;


/* 16. TOP 10 MOST LOSS-MAKING PRODUCTS */

SELECT TOP 10
    ProductName,
    SubCategory,
    SUM(TRY_CONVERT(DECIMAL(18, 4), Sales)) AS TotalSales,
    SUM(TRY_CONVERT(DECIMAL(18, 4), Profit)) AS TotalProfit,
    CAST(
        100.0 * SUM(TRY_CONVERT(DECIMAL(18, 4), Profit))
        / NULLIF(
            SUM(TRY_CONVERT(DECIMAL(18, 4), Sales)),
            0
        )
        AS DECIMAL(10, 2)
    ) AS ProfitMarginPercent
FROM dbo.superstore_sql_fixed
GROUP BY ProductName, SubCategory
HAVING SUM(
    TRY_CONVERT(DECIMAL(18, 4), Profit)
) < 0
ORDER BY TotalProfit ASC;


/* 17. DISCOUNT ANALYSIS OF LOSS-MAKING PRODUCTS */

SELECT
    ProductName,
    SubCategory,
    Discount,
    COUNT(*) AS TotalRows,
    SUM(TRY_CONVERT(DECIMAL(18, 4), Sales)) AS TotalSales,
    SUM(TRY_CONVERT(DECIMAL(18, 4), Profit)) AS TotalProfit
FROM dbo.superstore_sql_fixed
WHERE ProductName IN (
    'Cubify CubeX 3D Printer Double Head Print',
    'Lexmark MX611dhe Monochrome Laser Printer',
    'Motorola Smart Phone, Cordless',
    'Cubify CubeX 3D Printer Triple Head Print',
    'Bevis Round Table, Adjustable Height',
    'Bevis Computer Table, Fully Assembled',
    'Rogers Lockers, Blue',
    'Chromcraft Bull-Nose Wood Oval Conference Tables & Bases',
    'Bevis Wood Table, with Bottom Storage',
    'Lesro Training Table, Rectangular'
)
GROUP BY
    ProductName,
    SubCategory,
    Discount
ORDER BY
    ProductName,
    Discount;


/* 18. DISCOUNT BANDS FOR LOSS-MAKING PRODUCTS */

WITH LossProducts AS (
    SELECT ProductName
    FROM dbo.superstore_sql_fixed
    GROUP BY ProductName
    HAVING SUM(
        TRY_CONVERT(DECIMAL(18, 4), Profit)
    ) < 0
),
ProductRows AS (
    SELECT
        s.ProductName,
        TRY_CONVERT(DECIMAL(18, 4), s.Discount) AS DiscountValue,
        TRY_CONVERT(DECIMAL(18, 4), s.Sales) AS SalesValue,
        TRY_CONVERT(DECIMAL(18, 4), s.Profit) AS ProfitValue
    FROM dbo.superstore_sql_fixed AS s
    INNER JOIN LossProducts AS l
        ON s.ProductName = l.ProductName
)
SELECT
    CASE
        WHEN DiscountValue < 0.30 THEN 'Below 30%'
        WHEN DiscountValue < 0.50 THEN '30% to <50%'
        ELSE '50% and above'
    END AS DiscountBand,
    COUNT(*) AS TotalRows,
    SUM(SalesValue) AS TotalSales,
    SUM(ProfitValue) AS TotalProfit,
    CAST(
        100.0 * SUM(ProfitValue)
        / NULLIF(SUM(SalesValue), 0)
        AS DECIMAL(10, 2)
    ) AS ProfitMarginPercent
FROM ProductRows
WHERE DiscountValue IS NOT NULL
GROUP BY
    CASE
        WHEN DiscountValue < 0.30 THEN 'Below 30%'
        WHEN DiscountValue < 0.50 THEN '30% to <50%'
        ELSE '50% and above'
    END
ORDER BY
    MIN(DiscountValue);


/* 19. GROSS LOSS BY DISCOUNT BAND */

WITH LossProducts AS (
    SELECT ProductName
    FROM dbo.superstore_sql_fixed
    GROUP BY ProductName
    HAVING SUM(
        TRY_CONVERT(DECIMAL(18, 4), Profit)
    ) < 0
),
DiscountData AS (
    SELECT
        TRY_CONVERT(DECIMAL(18, 4), Discount) AS DiscountValue,
        TRY_CONVERT(DECIMAL(18, 4), Profit) AS ProfitValue
    FROM dbo.superstore_sql_fixed AS s
    INNER JOIN LossProducts AS l
        ON s.ProductName = l.ProductName
),
BandResults AS (
    SELECT
        CASE
            WHEN DiscountValue < 0.30 THEN 'Below 30%'
            WHEN DiscountValue < 0.50 THEN '30% to <50%'
            ELSE '50% and above'
        END AS DiscountBand,
        SUM(CASE WHEN ProfitValue < 0
                 THEN -ProfitValue ELSE 0 END) AS GrossLoss,
        SUM(CASE WHEN ProfitValue > 0
                 THEN ProfitValue ELSE 0 END) AS GrossProfit,
        SUM(ProfitValue) AS NetProfit
    FROM DiscountData
    WHERE DiscountValue IS NOT NULL
    GROUP BY
        CASE
            WHEN DiscountValue < 0.30 THEN 'Below 30%'
            WHEN DiscountValue < 0.50 THEN '30% to <50%'
            ELSE '50% and above'
        END
)
SELECT
    DiscountBand,
    GrossLoss,
    GrossProfit,
    NetProfit,
    CAST(
        100.0 * GrossLoss
        / NULLIF(SUM(GrossLoss) OVER (), 0)
        AS DECIMAL(10, 2)
    ) AS ShareOfGrossLossPercent
FROM BandResults
ORDER BY
    CASE DiscountBand
        WHEN 'Below 30%' THEN 1
        WHEN '30% to <50%' THEN 2
        ELSE 3
    END;


/* 20. OVERALL PROFITABILITY BY MARKET */

SELECT
    Market,
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT OrderID) AS TotalOrders,
    SUM(TRY_CONVERT(DECIMAL(18, 4), Sales)) AS TotalSales,
    SUM(TRY_CONVERT(DECIMAL(18, 4), Profit)) AS TotalProfit,
    CAST(
        100.0 * SUM(TRY_CONVERT(DECIMAL(18, 4), Profit))
        / NULLIF(
            SUM(TRY_CONVERT(DECIMAL(18, 4), Sales)),
            0
        )
        AS DECIMAL(10, 2)
    ) AS ProfitMarginPercent
FROM dbo.superstore_sql_fixed
GROUP BY Market
ORDER BY TotalProfit DESC;


/* 21. MARKET PERFORMANCE BY YEAR */

SELECT
    Market,
    TRY_CONVERT(INT, Year) AS SalesYear,
    COUNT(DISTINCT OrderID) AS TotalOrders,
    SUM(TRY_CONVERT(DECIMAL(18, 4), Sales)) AS TotalSales,
    SUM(TRY_CONVERT(DECIMAL(18, 4), Profit)) AS TotalProfit,
    CAST(
        100.0 * SUM(TRY_CONVERT(DECIMAL(18, 4), Profit))
        / NULLIF(
            SUM(TRY_CONVERT(DECIMAL(18, 4), Sales)),
            0
        )
        AS DECIMAL(10, 2)
    ) AS ProfitMarginPercent
FROM dbo.superstore_sql_fixed
GROUP BY
    Market,
    TRY_CONVERT(INT, Year)
ORDER BY
    SalesYear,
    TotalProfit DESC;


/* 22. YEAR-OVER-YEAR GROWTH BY MARKET */

WITH YearlyMarket AS (
    SELECT
        Market,
        TRY_CONVERT(INT, Year) AS SalesYear,
        SUM(TRY_CONVERT(DECIMAL(18, 4), Sales)) AS TotalSales,
        SUM(TRY_CONVERT(DECIMAL(18, 4), Profit)) AS TotalProfit
    FROM dbo.superstore_sql_fixed
    GROUP BY
        Market,
        TRY_CONVERT(INT, Year)
),
Growth AS (
    SELECT
        Market,
        SalesYear,
        TotalSales,
        TotalProfit,
        LAG(TotalSales) OVER (
            PARTITION BY Market
            ORDER BY SalesYear
        ) AS PreviousYearSales,
        LAG(TotalProfit) OVER (
            PARTITION BY Market
            ORDER BY SalesYear
        ) AS PreviousYearProfit
    FROM YearlyMarket
)
SELECT
    Market,
    SalesYear,
    TotalSales,
    TotalProfit,
    CAST(
        100.0 * (TotalSales - PreviousYearSales)
        / NULLIF(PreviousYearSales, 0)
        AS DECIMAL(10, 2)
    ) AS SalesGrowthPercent,
    CAST(
        100.0 * (TotalProfit - PreviousYearProfit)
        / NULLIF(ABS(PreviousYearProfit), 0)
        AS DECIMAL(10, 2)
    ) AS ProfitGrowthPercent
FROM Growth
ORDER BY Market, SalesYear;