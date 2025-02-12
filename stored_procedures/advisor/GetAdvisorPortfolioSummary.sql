CREATE PROCEDURE GetAdvisorPortfolioSummary
    @AdvisorID INT,
    @Success BIT OUTPUT,
    @Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Advisor WHERE ID = @AdvisorID)
        BEGIN
            SET @Success = 0;
            SET @Message = 'Advisor not found';
            RETURN;
        END

        -- First Result Set: Overall Summary
        SELECT 
            a.name AS AdvisorName,
            a.email AS AdvisorEmail,
            COUNT(DISTINCT c.ID) AS TotalClients,
            SUM(c.available_balance) AS TotalAvailableBalance,
            (
                SELECT SUM(
                    ast.quantity * 
                    CASE ast.type_name
                        WHEN 'Stock' THEN s.current_price
                        WHEN 'Bond' THEN b.current_price
                        WHEN 'Mutual Fund' THEN mf.current_price
                    END
                )
                FROM Assets ast
                LEFT JOIN Stocks s ON ast.type_id = s.ID AND ast.type_name = 'Stock'
                LEFT JOIN Bonds b ON ast.type_id = b.ID AND ast.type_name = 'Bond'
                LEFT JOIN Mutual_Funds mf ON ast.type_id = mf.ID AND ast.type_name = 'Mutual Fund'
                WHERE ast.client_id IN (SELECT ID FROM Client WHERE advisor_id = @AdvisorID)
            ) AS TotalAssetsValue,
            (
                SELECT SUM(
                    ast.quantity * 
                    CASE ast.type_name
                        WHEN 'Stock' THEN s.current_price
                        WHEN 'Bond' THEN b.current_price
                        WHEN 'Mutual Fund' THEN mf.current_price
                    END
                )
                FROM Assets ast
                LEFT JOIN Stocks s ON ast.type_id = s.ID AND ast.type_name = 'Stock'
                LEFT JOIN Bonds b ON ast.type_id = b.ID AND ast.type_name = 'Bond'
                LEFT JOIN Mutual_Funds mf ON ast.type_id = mf.ID AND ast.type_name = 'Mutual Fund'
                WHERE ast.client_id IN (SELECT ID FROM Client WHERE advisor_id = @AdvisorID)
            ) + SUM(c.available_balance) AS TotalPortfolioValue
        FROM Advisor a
        LEFT JOIN Client c ON c.advisor_id = a.ID
        WHERE a.ID = @AdvisorID
        GROUP BY a.name, a.email;

        -- Second Result Set: Asset Type Breakdown
        SELECT 
            ast.type_name AS AssetType,
            COUNT(DISTINCT ast.ID) AS NumberOfInvestments,
            SUM(ast.quantity * ast.buying_price) AS TotalInvested,
            SUM(
                ast.quantity * 
                CASE ast.type_name
                    WHEN 'Stock' THEN s.current_price
                    WHEN 'Bond' THEN b.current_price
                    WHEN 'Mutual Fund' THEN mf.current_price
                END
            ) AS CurrentValue,
            SUM(
                ast.quantity * 
                CASE ast.type_name
                    WHEN 'Stock' THEN s.current_price
                    WHEN 'Bond' THEN b.current_price
                    WHEN 'Mutual Fund' THEN mf.current_price
                END - 
                ast.quantity * ast.buying_price
            ) AS TotalProfitLoss
        FROM Assets ast
        LEFT JOIN Stocks s ON ast.type_id = s.ID AND ast.type_name = 'Stock'
        LEFT JOIN Bonds b ON ast.type_id = b.ID AND ast.type_name = 'Bond'
        LEFT JOIN Mutual_Funds mf ON ast.type_id = mf.ID AND ast.type_name = 'Mutual Fund'
        WHERE ast.client_id IN (SELECT ID FROM Client WHERE advisor_id = @AdvisorID)
        GROUP BY ast.type_name;

        -- Third Result Set: Client-wise Breakdown
        SELECT 
            c.ID AS ClientID,
            c.name AS ClientName,
            c.available_balance AS AvailableBalance,
            (
                SELECT SUM(
                    ast.quantity * 
                    CASE ast.type_name
                        WHEN 'Stock' THEN s.current_price
                        WHEN 'Bond' THEN b.current_price
                        WHEN 'Mutual Fund' THEN mf.current_price
                    END
                )
                FROM Assets ast
                LEFT JOIN Stocks s ON ast.type_id = s.ID AND ast.type_name = 'Stock'
                LEFT JOIN Bonds b ON ast.type_id = b.ID AND ast.type_name = 'Bond'
                LEFT JOIN Mutual_Funds mf ON ast.type_id = mf.ID AND ast.type_name = 'Mutual Fund'
                WHERE ast.client_id = c.ID
            ) AS InvestedAmount,
            c.available_balance + (
                SELECT ISNULL(SUM(
                    ast.quantity * 
                    CASE ast.type_name
                        WHEN 'Stock' THEN s.current_price
                        WHEN 'Bond' THEN b.current_price
                        WHEN 'Mutual Fund' THEN mf.current_price
                    END
                ), 0)
                FROM Assets ast
                LEFT JOIN Stocks s ON ast.type_id = s.ID AND ast.type_name = 'Stock'
                LEFT JOIN Bonds b ON ast.type_id = b.ID AND ast.type_name = 'Bond'
                LEFT JOIN Mutual_Funds mf ON ast.type_id = mf.ID AND ast.type_name = 'Mutual Fund'
                WHERE ast.client_id = c.ID
            ) AS TotalPortfolioValue
        FROM Client c
        WHERE c.advisor_id = @AdvisorID
        ORDER BY TotalPortfolioValue DESC;

        SET @Success = 1;
        SET @Message = 'Advisor portfolio summary retrieved successfully';
    END TRY
    BEGIN CATCH
        SET @Success = 0;
        SET @Message = ERROR_MESSAGE();
    END CATCH
END;
