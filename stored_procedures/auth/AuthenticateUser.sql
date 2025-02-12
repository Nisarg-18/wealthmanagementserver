CREATE PROCEDURE AuthenticateUser
    @Email NVARCHAR(255),
    @Password NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON; 
    -- Check Admin
    IF EXISTS (SELECT 1 FROM Admin WHERE email = @Email AND password = @Password)
    BEGIN
        SELECT 'Admin' AS UserType, ID, name, email, phone
        FROM Admin
        WHERE email = @Email;
        RETURN;
    END

    -- Check Advisor
    IF EXISTS (SELECT 1 FROM Advisor WHERE email = @Email AND password = @Password)
    BEGIN
        SELECT 'Advisor' AS UserType, ID, name, email, phone
        FROM Advisor
        WHERE email = @Email;
        RETURN;
    END

    -- Check Client
    IF EXISTS (SELECT 1 FROM Client WHERE email = @Email AND password = @Password)
    BEGIN
        SELECT 'Client' AS UserType, ID, name, email, phone, available_balance
        FROM Client
        WHERE email = @Email;
        RETURN;
    END

    -- Invalid Credentials
    SELECT 'Invalid credentials' AS Message;
END
