CREATE PROCEDURE UpdateMarketPrices
    @Success BIT OUTPUT,
    @Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Create a temp table to store random percentage changes
        CREATE TABLE #PriceChanges (
            ID INT,
            Type NVARCHAR(50),
            ChangePercentage DECIMAL(5,2)
        );

        INSERT INTO #PriceChanges (ID, Type, ChangePercentage)
        SELECT 
            ID,
            'Stock',
            (RAND() * 20) - 10 
        FROM Stocks;

        INSERT INTO #PriceChanges (ID, Type, ChangePercentage)
        SELECT 
            ID,
            'Bond',
            ((RAND() * 10) - 5)
        FROM Bonds;

        INSERT INTO #PriceChanges (ID, Type, ChangePercentage)
        SELECT 
            ID,
            'Mutual Fund',
            (RAND() * 16) - 8
        FROM Mutual_Funds;

        UPDATE s
        SET current_price = ROUND(s.current_price * (1 + (pc.ChangePercentage / 100)), 2)
        FROM Stocks s
        INNER JOIN #PriceChanges pc ON s.ID = pc.ID AND pc.Type = 'Stock';

        UPDATE b
        SET current_price = ROUND(b.current_price * (1 + (pc.ChangePercentage / 100)), 2)
        FROM Bonds b
        INNER JOIN #PriceChanges pc ON b.ID = pc.ID AND pc.Type = 'Bond';

        UPDATE mf
        SET current_price = ROUND(mf.current_price * (1 + (pc.ChangePercentage / 100)), 2)
        FROM Mutual_Funds mf
        INNER JOIN #PriceChanges pc ON mf.ID = pc.ID AND pc.Type = 'Mutual Fund';

        SELECT 
            'Stock' as AssetType,
            s.name,
            pc.ChangePercentage as PriceChangePercent,
            s.current_price as NewPrice
        FROM Stocks s
        INNER JOIN #PriceChanges pc ON s.ID = pc.ID AND pc.Type = 'Stock'
        UNION ALL
        SELECT 
            'Bond' as AssetType,
            b.name,
            pc.ChangePercentage,
            b.current_price as NewPrice
        FROM Bonds b
        INNER JOIN #PriceChanges pc ON b.ID = pc.ID AND pc.Type = 'Bond'
        UNION ALL
        SELECT 
            'Mutual Fund' as AssetType,
            mf.name,
            pc.ChangePercentage,
            mf.current_price as NewPrice
        FROM Mutual_Funds mf
        INNER JOIN #PriceChanges pc ON mf.ID = pc.ID AND pc.Type = 'Mutual Fund'
        ORDER BY AssetType, name;

        DROP TABLE #PriceChanges;

        INSERT INTO AssetPriceHistory (AssetType, AssetID, AssetName, Price)
        SELECT 'Stock', ID, name, current_price FROM Stocks
        UNION ALL
        SELECT 'Bond', ID, name, current_price FROM Bonds
        UNION ALL
        SELECT 'Mutual Fund', ID, name, current_price FROM Mutual_Funds;

        SET @Success = 1;
        SET @Message = 'Market prices updated successfully';
    END TRY
    BEGIN CATCH
        DROP TABLE #PriceChanges;
            
        SET @Success = 0;
        SET @Message = ERROR_MESSAGE();
    END CATCH
END;