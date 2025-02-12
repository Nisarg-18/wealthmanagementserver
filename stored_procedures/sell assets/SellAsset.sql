CREATE PROCEDURE SellAsset
    @ClientID INT,
    @AssetID INT,
    @Quantity INT,
    @Success BIT OUTPUT,
    @Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentPrice DECIMAL(15, 2);
    DECLARE @AssetType NVARCHAR(50);
    DECLARE @TypeID INT;
    DECLARE @AvailableQuantity INT;
    DECLARE @TotalValue DECIMAL(15, 2);

    BEGIN TRY
        SELECT @AssetType = type_name,
               @TypeID = type_id,
               @AvailableQuantity = quantity
        FROM Assets
        WHERE ID = @AssetID AND client_id = @ClientID;

        IF @AssetType IS NULL
        BEGIN
            SET @Success = 0;
            SET @Message = 'Asset not found or does not belong to client';
            RETURN;
        END

        IF @Quantity > @AvailableQuantity
        BEGIN
            SET @Success = 0;
            SET @Message = 'Insufficient quantity available';
            RETURN;
        END

        SELECT @CurrentPrice = 
            CASE @AssetType
                WHEN 'Stock' THEN (SELECT current_price FROM Stocks WHERE ID = @TypeID)
                WHEN 'Bond' THEN (SELECT current_price FROM Bonds WHERE ID = @TypeID)
                WHEN 'Mutual Fund' THEN (SELECT current_price FROM Mutual_Funds WHERE ID = @TypeID)
            END;

        SET @TotalValue = @CurrentPrice * @Quantity;

        BEGIN TRANSACTION;

        UPDATE Client
        SET available_balance = available_balance + @TotalValue
        WHERE ID = @ClientID;

        IF @Quantity = @AvailableQuantity
        BEGIN
            DELETE FROM Assets WHERE ID = @AssetID;
        END
        ELSE
        BEGIN
            UPDATE Assets 
            SET quantity = quantity - @Quantity
            WHERE ID = @AssetID;
        END

        COMMIT TRANSACTION;

        SET @Success = 1;
        SET @Message = 'Asset sold successfully for $' + CAST(@TotalValue AS NVARCHAR(20));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        SET @Success = 0;
        SET @Message = ERROR_MESSAGE();
    END CATCH
END;