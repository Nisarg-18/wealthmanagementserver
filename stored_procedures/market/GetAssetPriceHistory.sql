CREATE PROCEDURE GetAssetPriceHistory
    @AssetType NVARCHAR(50),
    @AssetID INT,
    @TimeFrame NVARCHAR(3),
    @Success BIT OUTPUT,
    @Message NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartDate DATETIME;
    SET @StartDate = 
        CASE @TimeFrame
            WHEN '1D' THEN DATEADD(DAY, -1, GETDATE())
            WHEN '1M' THEN DATEADD(MONTH, -1, GETDATE())
            WHEN '1Y' THEN DATEADD(YEAR, -1, GETDATE())
            WHEN '5Y' THEN DATEADD(YEAR, -5, GETDATE())
            ELSE DATEADD(DAY, -1, GETDATE())
        END;

    BEGIN TRY
        SELECT 
            AssetName,
            Price,
            RecordedAt,
            LAG(Price) OVER (ORDER BY RecordedAt) AS PreviousPrice,
            ((Price - LAG(Price) OVER (ORDER BY RecordedAt)) / 
             LAG(Price) OVER (ORDER BY RecordedAt)) * 100 AS PriceChangePercent
        FROM AssetPriceHistory
        WHERE AssetType = @AssetType 
        AND AssetID = @AssetID
        AND RecordedAt >= @StartDate
        ORDER BY RecordedAt;

        SET @Success = 1;
        SET @Message = 'Price history retrieved successfully';
    END TRY
    BEGIN CATCH
        SET @Success = 0;
        SET @Message = ERROR_MESSAGE();
    END CATCH
END;