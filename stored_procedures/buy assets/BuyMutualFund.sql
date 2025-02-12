CREATE PROCEDURE BuyMutualFund
    @ClientID INT,
    @FundID INT,
    @Quantity INT,
    @Success BIT OUTPUT,
    @Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @FundPrice DECIMAL(15, 2);
    DECLARE @TotalCost DECIMAL(15, 2);
    DECLARE @ClientBalance DECIMAL(15, 2);
    DECLARE @FundName NVARCHAR(255);
    DECLARE @ExistingAssetID INT;
    DECLARE @ExistingQuantity INT;
    DECLARE @ExistingPrice DECIMAL(15, 2);
    DECLARE @NewAveragePrice DECIMAL(15, 2);

    BEGIN TRY
        SELECT @FundPrice = current_price, @FundName = name
        FROM Mutual_Funds
        WHERE ID = @FundID;

        IF @FundPrice IS NULL
        BEGIN
            SET @Success = 0;
            SET @Message = 'Mutual Fund not found';
            RETURN;
        END

        SET @TotalCost = @FundPrice * @Quantity;

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
        AND type_name = 'Mutual Fund' 
        AND type_id = @FundID;

        BEGIN TRANSACTION;

        UPDATE Client
        SET available_balance = available_balance - @TotalCost
        WHERE ID = @ClientID;

        IF @ExistingAssetID IS NOT NULL
        BEGIN
            SET @NewAveragePrice = ((@ExistingPrice * @ExistingQuantity) + (@FundPrice * @Quantity)) 
                                  / (@ExistingQuantity + @Quantity);

            UPDATE Assets
            SET quantity = quantity + @Quantity,
                buying_price = @NewAveragePrice
            WHERE ID = @ExistingAssetID;

            SET @Message = 'Mutual Fund position updated successfully. New average price: ' + 
                          CAST(@NewAveragePrice AS NVARCHAR(20));
        END
        ELSE
        BEGIN
            INSERT INTO Assets (type_name, type_id, name, buying_date, buying_price, quantity, client_id)
            VALUES ('Mutual Fund', @FundID, @FundName, GETDATE(), @FundPrice, @Quantity, @ClientID);

            SET @Message = 'New mutual fund position created successfully';
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
