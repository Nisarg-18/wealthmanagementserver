CREATE PROCEDURE GetAdvisorClients
    @AdvisorID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Advisor WHERE ID = @AdvisorID)
        BEGIN
            SELECT 
                -1 AS StatusCode, 
                'Advisor not found' AS Message, 
                NULL AS ID, 
                CAST(NULL AS NVARCHAR(255)) AS name, 
                CAST(NULL AS NVARCHAR(255)) AS email, 
                CAST(NULL AS NVARCHAR(20)) AS phone, 
                CAST(NULL AS DECIMAL(18,2)) AS available_balance, 
                NULL AS total_assets;
            RETURN;
        END

        SELECT 
            1 AS StatusCode,
            'Clients retrieved successfully' AS Message,
            c.ID,
            CAST(c.name AS NVARCHAR(255)) AS name,
            CAST(c.email AS NVARCHAR(255)) AS email,
            CAST(c.phone AS NVARCHAR(20)) AS phone,
            CAST(c.available_balance AS DECIMAL(18,2)) AS available_balance,
            (SELECT COUNT(*) FROM Assets a WHERE a.client_id = c.ID) AS total_assets
        FROM 
            Client c
        WHERE 
            c.advisor_id = @AdvisorID;

        IF @@ROWCOUNT = 0
        BEGIN
            SELECT 
                1 AS StatusCode, 
                'No clients found for this advisor' AS Message, 
                NULL AS ID, 
                CAST(NULL AS NVARCHAR(255)) AS name, 
                CAST(NULL AS NVARCHAR(255)) AS email, 
                CAST(NULL AS NVARCHAR(20)) AS phone, 
                CAST(NULL AS DECIMAL(18,2)) AS available_balance, 
                NULL AS total_assets;
        END
    END TRY
    BEGIN CATCH
        SELECT 
            -2 AS StatusCode, 
            ERROR_MESSAGE() AS Message, 
            NULL AS ID, 
            CAST(NULL AS NVARCHAR(255)) AS name, 
            CAST(NULL AS NVARCHAR(255)) AS email, 
            CAST(NULL AS NVARCHAR(20)) AS phone, 
            CAST(NULL AS DECIMAL(18,2)) AS available_balance, 
            NULL AS total_assets;
    END CATCH
END;
