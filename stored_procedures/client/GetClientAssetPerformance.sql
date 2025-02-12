CREATE PROCEDURE GetClientAssetPerformance
    @ClientID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        a.type_name AS AssetType,
        SUM(a.quantity * a.buying_price) AS TotalInvested,
        SUM(a.quantity * 
            CASE a.type_name
                WHEN 'Stock' THEN s.current_price
                WHEN 'Bond' THEN b.current_price
                WHEN 'Mutual Fund' THEN mf.current_price
            END) AS CurrentValue,
        SUM(a.quantity * 
            (CASE a.type_name
                WHEN 'Stock' THEN s.current_price
                WHEN 'Bond' THEN b.current_price
                WHEN 'Mutual Fund' THEN mf.current_price
            END) - (a.quantity * a.buying_price)) AS ProfitOrLoss
    FROM Assets a
    LEFT JOIN Stocks s ON a.type_id = s.ID AND a.type_name = 'Stock'
    LEFT JOIN Bonds b ON a.type_id = b.ID AND a.type_name = 'Bond'
    LEFT JOIN Mutual_Funds mf ON a.type_id = mf.ID AND a.type_name = 'Mutual Fund'
    WHERE a.client_id = @ClientID
    GROUP BY a.type_name;
END;
