CREATE PROCEDURE InsertClient
    @Name NVARCHAR(255),
    @Email NVARCHAR(255),
    @Password NVARCHAR(255),
    @Phone NVARCHAR(20),
    @AdvisorID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM Client WHERE email = @Email)
        BEGIN
            SELECT -1 AS StatusCode, 'Email already exists' AS Message;
            RETURN;
        END

        IF @AdvisorID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Advisor WHERE ID = @AdvisorID)
        BEGIN
            SELECT -1 AS StatusCode, 'Invalid Advisor ID' AS Message;
            RETURN;
        END

        INSERT INTO Client (name, email, password, phone, advisor_id, available_balance)
        VALUES (@Name, @Email, @Password, @Phone, @AdvisorID, 0.00);

        SELECT 1 AS StatusCode, 
               'Client added successfully' AS Message, 
               SCOPE_IDENTITY() AS ClientID;
    END TRY
    BEGIN CATCH
        SELECT -2 AS StatusCode, ERROR_MESSAGE() AS Message;
    END CATCH
END;