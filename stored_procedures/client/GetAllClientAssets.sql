-- Procedure to get all assets for a client
CREATE PROCEDURE GetAllClientAssets
    @ClientID INT,
    @Success BIT OUTPUT,
    @Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Client WHERE ID = @ClientID)
        BEGIN
            SET @Success = 0;
            SET @Message = 'Client not found';
            RETURN;
        END

        SELECT 
            a.ID as AssetID,
            a.type_name as AssetType,
            a.name as AssetName,
            a.buying_date as PurchaseDate,
            a.buying_price as PurchasePrice,
            a.quantity as Quantity,
            CASE a.type_name
                WHEN 'Stock' THEN s.current_price
                WHEN 'Bond' THEN b.current_price
                WHEN 'Mutual Fund' THEN mf.current_price
            END as CurrentPrice,
            (a.quantity * 
                CASE a.type_name
                    WHEN 'Stock' THEN s.current_price
                    WHEN 'Bond' THEN b.current_price
                    WHEN 'Mutual Fund' THEN mf.current_price
                END) as CurrentValue
        FROM Assets a
        LEFT JOIN Stocks s ON a.type_id = s.ID AND a.type_name = 'Stock'
        LEFT JOIN Bonds b ON a.type_id = b.ID AND a.type_name = 'Bond'
        LEFT JOIN Mutual_Funds mf ON a.type_id = mf.ID AND a.type_name = 'Mutual Fund'
        WHERE a.client_id = @ClientID;

        SET @Success = 1;
        SET @Message = 'Assets retrieved successfully';
    END TRY
    BEGIN CATCH
        SET @Success = 0;
        SET @Message = ERROR_MESSAGE();
    END CATCH
END;
