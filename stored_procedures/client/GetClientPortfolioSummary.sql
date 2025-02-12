CREATE PROCEDURE GetClientPortfolioSummary
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

        SELECT 
            @TotalInvested = SUM(a.buying_price * a.quantity),
            @CurrentValue = SUM(
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
        WHERE a.client_id = @ClientID;

        SET @TotalInvested = ISNULL(@TotalInvested, 0);
        SET @CurrentValue = ISNULL(@CurrentValue, 0);

        SET @ProfitLoss = @CurrentValue - @TotalInvested;

        IF @TotalInvested > 0
            SET @PercentageReturn = (@ProfitLoss / @TotalInvested) * 100;
        ELSE
            SET @PercentageReturn = 0;

        SELECT
            @TotalInvested AS TotalInvested,
            @CurrentValue AS CurrentPortfolioValue,
            @ProfitLoss AS TotalProfitLoss,
            @PercentageReturn AS PercentageReturn,
            @AvailableBalance AS AvailableBalance,
            (@CurrentValue + @AvailableBalance) AS TotalNetWorth;

        SELECT 
            a.type_name AS AssetType,
            SUM(a.buying_price * a.quantity) AS InvestedAmount,
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
            ) - SUM(a.buying_price * a.quantity) AS ProfitLoss
        FROM Assets a
        LEFT JOIN Stocks s ON a.type_id = s.ID AND a.type_name = 'Stock'
        LEFT JOIN Bonds b ON a.type_id = b.ID AND a.type_name = 'Bond'
        LEFT JOIN Mutual_Funds mf ON a.type_id = mf.ID AND a.type_name = 'Mutual Fund'
        WHERE a.client_id = @ClientID
        GROUP BY a.type_name;

        SET @Success = 1;
        SET @Message = 'Portfolio summary retrieved successfully';
    END TRY
    BEGIN CATCH
        SET @Success = 0;
        SET @Message = ERROR_MESSAGE();
    END CATCH
END;
