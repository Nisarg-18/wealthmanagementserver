DECLARE @Numbers TABLE (number INT);
INSERT INTO @Numbers (number)
SELECT TOP 8760 
    ROW_NUMBER() OVER (ORDER BY a.object_id) - 1
FROM sys.objects a
CROSS JOIN sys.objects b;

-- Generate historical price data for Stocks
INSERT INTO AssetPriceHistory (AssetType, AssetID, AssetName, Price, RecordedAt)
SELECT 
    'Stock' AS AssetType,
    ID AS AssetID,
    name AS AssetName,
    current_price * (1 + (RAND(CHECKSUM(NEWID())) * 0.4 - 0.2)) AS Price,
    DATEADD(HOUR, -1 * n.number, GETDATE()) AS RecordedAt
FROM Stocks
CROSS JOIN @Numbers n
WHERE n.number % CASE 
    WHEN n.number <= 24 THEN 1  -- Every hour for last day
    WHEN n.number <= 720 THEN 24 -- Daily for last month
    ELSE 168 -- Weekly for rest of the data
END = 0;

-- Generate historical price data for Bonds
INSERT INTO AssetPriceHistory (AssetType, AssetID, AssetName, Price, RecordedAt)
SELECT 
    'Bond' AS AssetType,
    ID AS AssetID,
    name AS AssetName,
    current_price * (1 + (RAND(CHECKSUM(NEWID())) * 0.2 - 0.1)) AS Price,
    DATEADD(HOUR, -1 * n.number, GETDATE()) AS RecordedAt
FROM Bonds
CROSS JOIN @Numbers n
WHERE n.number % CASE 
    WHEN n.number <= 24 THEN 1
    WHEN n.number <= 720 THEN 24
    ELSE 168
END = 0;

-- Generate historical price data for Mutual Funds
INSERT INTO AssetPriceHistory (AssetType, AssetID, AssetName, Price, RecordedAt)
SELECT 
    'MutualFund' AS AssetType,
    ID AS AssetID,
    name AS AssetName,
    current_price * (1 + (RAND(CHECKSUM(NEWID())) * 0.3 - 0.15)) AS Price,
    DATEADD(HOUR, -1 * n.number, GETDATE()) AS RecordedAt
FROM Mutual_Funds
CROSS JOIN @Numbers n
WHERE n.number % CASE 
    WHEN n.number <= 24 THEN 1
    WHEN n.number <= 720 THEN 24
    ELSE 168
END = 0;