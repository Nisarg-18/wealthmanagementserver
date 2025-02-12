CREATE PROCEDURE GetClientPortfolioAnalysis
    @ClientID INT,
    @Success BIT OUTPUT,
    @Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @TotalInvested DECIMAL(15, 2) = 0;
    DECLARE @CurrentValue DECIMAL(15, 2) = 0;
    DECLARE @AvailableBalance DECIMAL(15, 2) = 0;
    DECLARE @ProfitLoss DECIMAL(15, 2) = 0;
    DECLARE @PercentageReturn DECIMAL(15, 2) = 0;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Client WHERE ID = @ClientID)
        BEGIN
            SET @Success = 0;
            SET @Message = 'Client not found';
            RETURN;
        END

        SELECT @AvailableBalance = available_balance
        FROM Client
        WHERE ID = @ClientID;

        -- First Result Set: Overall Portfolio Summary
        SELECT 
            c.name AS ClientName,
            c.email AS ClientEmail,
            c.available_balance AS AvailableBalance,
            (
                SELECT SUM(a.quantity * a.buying_price)
                FROM Assets a
                WHERE a.client_id = @ClientID
            ) AS TotalInvested,
            (
                SELECT SUM(
                    a.quantity * 
                    CASE a.type_name
                        WHEN 'Stock' THEN s.current_price
                        WHEN 'Bond' THEN b.current_price
                        WHEN 'Mutual Fund' THEN mf.current_price
                    END
                )
                FROM Assets a
                LEFT JOIN Stocks s ON a.type_id = s.ID AND a.type_name = 'Stock'
                LEFT JOIN Bonds b ON a.type_id = b.ID AND a.type_name = 'Bond'
                LEFT JOIN Mutual_Funds mf ON a.type_id = mf.ID AND a.type_name = 'Mutual Fund'
                WHERE a.client_id = @ClientID
            ) AS CurrentPortfolioValue
        FROM Client c
        WHERE c.ID = @ClientID;

        -- Second Result Set: Detailed Asset Type Breakdown
        SELECT 
            a.type_name AS AssetType,
            COUNT(DISTINCT a.type_id) AS NumberOfInvestments,
            SUM(a.quantity * a.buying_price) AS TotalInvested,
            SUM(
                a.quantity * 
                CASE a.type_name
                    WHEN 'Stock' THEN s.current_price
                    WHEN 'Bond' THEN b.current_price
                    WHEN 'Mutual Fund' THEN mf.current_price
                END
            ) AS CurrentValue,
            SUM(
                a.quantity * 
                CASE a.type_name
                    WHEN 'Stock' THEN s.current_price
                    WHEN 'Bond' THEN b.current_price
                    WHEN 'Mutual Fund' THEN mf.current_price
                END
            ) - SUM(a.quantity * a.buying_price) AS ProfitLoss,
            (
                (SUM(
                    a.quantity * 
                    CASE a.type_name
                        WHEN 'Stock' THEN s.current_price
                        WHEN 'Bond' THEN b.current_price
                        WHEN 'Mutual Fund' THEN mf.current_price
                    END
                ) - SUM(a.quantity * a.buying_price)) / 
                NULLIF(SUM(a.quantity * a.buying_price), 0) * 100
            ) AS PercentageReturn
        FROM Assets a
        LEFT JOIN Stocks s ON a.type_id = s.ID AND a.type_name = 'Stock'
        LEFT JOIN Bonds b ON a.type_id = b.ID AND a.type_name = 'Bond'
        LEFT JOIN Mutual_Funds mf ON a.type_id = mf.ID AND a.type_name = 'Mutual Fund'
        WHERE a.client_id = @ClientID
        GROUP BY a.type_name;

        -- Third Result Set: Individual Asset Performance
        SELECT 
            a.type_name AS AssetType,
            a.name AS AssetName,
            a.quantity AS Quantity,
            a.buying_price AS BuyingPrice,
            CASE a.type_name
                WHEN 'Stock' THEN s.current_price
                WHEN 'Bond' THEN b.current_price
                WHEN 'Mutual Fund' THEN mf.current_price
            END AS CurrentPrice,
            (a.quantity * a.buying_price) AS InvestedAmount,
            (a.quantity * 
                CASE a.type_name
                    WHEN 'Stock' THEN s.current_price
                    WHEN 'Bond' THEN b.current_price
                    WHEN 'Mutual Fund' THEN mf.current_price
                END
            ) AS CurrentValue,
            (
                (a.quantity * 
                    CASE a.type_name
                        WHEN 'Stock' THEN s.current_price
                        WHEN 'Bond' THEN b.current_price
                        WHEN 'Mutual Fund' THEN mf.current_price
                    END
                ) - (a.quantity * a.buying_price)
            ) AS ProfitLoss,
            a.buying_date AS PurchaseDate
        FROM Assets a
        LEFT JOIN Stocks s ON a.type_id = s.ID AND a.type_name = 'Stock'
        LEFT JOIN Bonds b ON a.type_id = b.ID AND a.type_name = 'Bond'
        LEFT JOIN Mutual_Funds mf ON a.type_id = mf.ID AND a.type_name = 'Mutual Fund'
        WHERE a.client_id = @ClientID
        ORDER BY a.type_name, a.buying_date;

        SET @Success = 1;
        SET @Message = 'Portfolio analysis retrieved successfully';
    END TRY
    BEGIN CATCH
        SET @Success = 0;
        SET @Message = ERROR_MESSAGE();
    END CATCH
END;

EXEC GetClientPortfolioAnalysis 1, @Success = '', @Message = '';