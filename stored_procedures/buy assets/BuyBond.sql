CREATE PROCEDURE BuyBond
    @ClientID INT,
    @BondID INT,
    @Quantity INT,
    @Success BIT OUTPUT,
    @Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @BondPrice DECIMAL(15, 2);
    DECLARE @TotalCost DECIMAL(15, 2);
    DECLARE @ClientBalance DECIMAL(15, 2);
    DECLARE @BondName NVARCHAR(255);
    DECLARE @ExistingAssetID INT;
    DECLARE @ExistingQuantity INT;
    DECLARE @ExistingPrice DECIMAL(15, 2);
    DECLARE @NewAveragePrice DECIMAL(15, 2);

    BEGIN TRY
        SELECT @BondPrice = current_price, @BondName = name
        FROM Bonds
        WHERE ID = @BondID;

        IF @BondPrice IS NULL
        BEGIN
            SET @Success = 0;
            SET @Message = 'Bond not found';
            RETURN;
        END

        SET @TotalCost = @BondPrice * @Quantity;

        SELECT @ClientBalance = available_balance
        FROM Client
        WHERE ID = @ClientID;

        IF @ClientBalance IS NULL
        BEGIN
            SET @Success = 0;
            SET @Message = 'Client not found';
            RETURN;
        END

        IF @ClientBalance < @TotalCost
        BEGIN
            SET @Success = 0;
            SET @Message = 'Insufficient balance';
            RETURN;
        END

        SELECT 
            @ExistingAssetID = ID,
            @ExistingQuantity = quantity,
            @ExistingPrice = buying_price
        FROM Assets
        WHERE client_id = @ClientID 
        AND type_name = 'Bond' 
        AND type_id = @BondID;

        BEGIN TRANSACTION;

        UPDATE Client
        SET available_balance = available_balance - @TotalCost
        WHERE ID = @ClientID;

        IF @ExistingAssetID IS NOT NULL
        BEGIN
            SET @NewAveragePrice = ((@ExistingPrice * @ExistingQuantity) + (@BondPrice * @Quantity)) 
                                  / (@ExistingQuantity + @Quantity);

            UPDATE Assets
            SET quantity = quantity + @Quantity,
                buying_price = @NewAveragePrice
            WHERE ID = @ExistingAssetID;

            SET @Message = 'Bond position updated successfully. New average price: ' + 
                          CAST(@NewAveragePrice AS NVARCHAR(20));
        END
        ELSE
        BEGIN
            INSERT INTO Assets (type_name, type_id, name, buying_date, buying_price, quantity, client_id)
            VALUES ('Bond', @BondID, @BondName, GETDATE(), @BondPrice, @Quantity, @ClientID);

            SET @Message = 'New bond position created successfully';
        END

        COMMIT TRANSACTION;
        SET @Success = 1;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        SET @Success = 0;
        SET @Message = ERROR_MESSAGE();
    END CATCH
END;
