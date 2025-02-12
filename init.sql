CREATE TABLE Admin (
    ID INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(255) NOT NULL,
    email NVARCHAR(255) UNIQUE NOT NULL,
    password NVARCHAR(255) NOT NULL,
    phone NVARCHAR(20)
);

CREATE TABLE Advisor (
    ID INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(255) NOT NULL,
    email NVARCHAR(255) UNIQUE NOT NULL,
    password NVARCHAR(255) NOT NULL,
    phone NVARCHAR(20)
);

CREATE TABLE Client (
    ID INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(255) NOT NULL,
    email NVARCHAR(255) UNIQUE NOT NULL,
    password NVARCHAR(255) NOT NULL,
    phone NVARCHAR(20),
    advisor_id INT,
    available_balance DECIMAL(15, 2) DEFAULT 0.00,
    FOREIGN KEY (advisor_id) REFERENCES Advisor(ID)
);

CREATE TABLE Assets (
    ID INT PRIMARY KEY IDENTITY(1,1),
    type_name NVARCHAR(50) NOT NULL,
    type_id INT NOT NULL,
    name NVARCHAR(255) NOT NULL,
    buying_date DATE NOT NULL,
    buying_price DECIMAL(15, 2) NOT NULL,
    quantity INT NOT NULL,
    client_id INT,
    FOREIGN KEY (client_id) REFERENCES Client(ID)
);

CREATE TABLE Stocks (
    ID INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(255) NOT NULL,
    current_price DECIMAL(15, 2) NOT NULL
);

CREATE TABLE Bonds (
    ID INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(255) NOT NULL,
    current_price DECIMAL(15, 2) NOT NULL
);

CREATE TABLE Mutual_Funds (
    ID INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(255) NOT NULL,
    current_price DECIMAL(15, 2) NOT NULL
);

CREATE TABLE AssetPriceHistory (
    ID INT PRIMARY KEY IDENTITY(1,1),
    AssetType NVARCHAR(50) NOT NULL,
    AssetID INT NOT NULL,
    AssetName NVARCHAR(255) NOT NULL,
    Price DECIMAL(15, 2) NOT NULL,
    RecordedAt DATETIME NOT NULL DEFAULT GETDATE(),
    INDEX IX_AssetPrice_History (AssetType, AssetID, RecordedAt)
);