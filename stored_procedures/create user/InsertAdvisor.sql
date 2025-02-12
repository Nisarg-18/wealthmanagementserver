CREATE PROCEDURE InsertAdvisor
    @Name NVARCHAR(255),
    @Email NVARCHAR(255),
    @Password NVARCHAR(255),
    @Phone NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM Advisor WHERE email = @Email)
        BEGIN
            SELECT -1 AS StatusCode, 'Email already exists' AS Message;
            RETURN;
        END

        INSERT INTO Advisor (name, email, password, phone)
        VALUES (@Name, @Email, @Password, @Phone);

        SELECT 1 AS StatusCode, 'Advisor added successfully' AS Message, SCOPE_IDENTITY() AS AdvisorID;
    END TRY
    BEGIN CATCH
        SELECT -2 AS StatusCode, ERROR_MESSAGE() AS Message;
    END CATCH
END;




