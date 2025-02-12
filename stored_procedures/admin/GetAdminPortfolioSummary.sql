CREATE PROCEDURE GetAdminPortfolioSummary
    @AdminID INT,
    @Success BIT OUTPUT,
    @Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Admin WHERE ID = @AdminID)
        BEGIN
            SET @Success = 0;
            SET @Message = 'Admin not found';
            RETURN;
        END

        -- First Result Set: Overall System Summary
        SELECT 
            (SELECT COUNT(*) FROM Advisor) AS TotalAdvisors,
            (SELECT COUNT(*) FROM Client) AS TotalClients,
            (SELECT SUM(available_balance) FROM Client) AS TotalAvailableBalance,
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
            ) AS TotalAssetsValue;

        -- Second Result Set: Asset Type Breakdown
        SELECT 
            ast.type_name AS AssetType,
            COUNT(DISTINCT ast.ID) AS TotalInvestments,
            COUNT(DISTINCT ast.client_id) AS NumberOfInvestors,
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
        GROUP BY ast.type_name;

        -- Third Result Set: Advisor Performance Summary
        SELECT 
            a.ID AS AdvisorID,
            a.name AS AdvisorName,
            COUNT(DISTINCT c.ID) AS NumberOfClients,
            SUM(c.available_balance) AS ClientsAvailableBalance,
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
                WHERE ast.client_id IN (SELECT ID FROM Client WHERE advisor_id = a.ID)
            ) AS TotalAssetsManaged
        FROM Advisor a
        LEFT JOIN Client c ON c.advisor_id = a.ID
        GROUP BY a.ID, a.name
        ORDER BY TotalAssetsManaged DESC;

        SET @Success = 1;
        SET @Message = 'Admin portfolio summary retrieved successfully';
    END TRY
    BEGIN CATCH
        SET @Success = 0;
        SET @Message = ERROR_MESSAGE();
    END CATCH
END;
