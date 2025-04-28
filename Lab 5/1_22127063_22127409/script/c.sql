USE master;
GO

-- 1. Tạo Database Master Key (DMK) nếu chưa có
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'MatKhauManh@123';
    PRINT N'Database Master Key đã được tạo thành công.';
END
ELSE
    PRINT N'Database Master Key đã tồn tại.';
GO

-- 2. Tạo chứng chỉ (Certificate)
IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'QLBONGDA_TDE_Cert')
BEGIN
    CREATE CERTIFICATE QLBONGDA_TDE_Cert
    WITH SUBJECT = 'Certificate for TDE on QLBONGDA';
    PRINT N'Chứng chỉ TDE đã được tạo thành công.';
END
ELSE
    PRINT N'Chứng chỉ TDE đã tồn tại.';
GO

-- 3. Backup the TDE certificate
BACKUP CERTIFICATE QLBONGDA_TDE_Cert  
TO FILE = 'D:\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\Backup\QLBONGDA_TDE_Cert.cer'
WITH PRIVATE KEY 
(
    FILE = 'D:\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\Backup\QLBONGDA_TDE_Cert.pvk', 
    ENCRYPTION BY PASSWORD = 'Backup@123!'
);
GO

-- 4. Sử dụng CSDL QLBONGDA
USE QLBONGDA;
GO

-- 5. Tạo Database Encryption Key (DEK) sử dụng chứng chỉ
IF NOT EXISTS (SELECT * FROM sys.dm_database_encryption_keys)
BEGIN
    CREATE DATABASE ENCRYPTION KEY
    WITH ALGORITHM = AES_256
    ENCRYPTION BY SERVER CERTIFICATE QLBONGDA_TDE_Cert;
    PRINT N'Database Encryption Key đã được tạo thành công.';
END
ELSE
    PRINT N'Database Encryption Key đã tồn tại.';
GO

-- 6. Bật TDE cho CSDL QLBONGDA
ALTER DATABASE QLBONGDA
SET ENCRYPTION ON;
PRINT N'Transparent Data Encryption đã được bật.';
GO