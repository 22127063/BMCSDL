USE master;
GO

-- Sao lưu cơ sở dữ liệu QLBONGDA ra file .bak
BACKUP DATABASE QLBONGDA
TO DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER89\MSSQL\Backup\QLBONGDA_TDE.bak';

-- Tạo Master Key nếu chưa có (chỉ thực hiện 1 lần duy nhất trên server)
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'MatKhauManh@123';

-- Tạo chứng chỉ từ file backup đã sao lưu ở server nguồn
-- Dùng để giải mã cơ sở dữ liệu đã mã hóa bằng TDE
CREATE CERTIFICATE TDECert
FROM FILE = 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER_RESTORE_TDE\MSSQL\Backup\QLBONGDA_TDE_Cert.cer'
WITH PRIVATE KEY (
    FILE = 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER_RESTORE_TDE\MSSQL\Backup\QLBONGDA_TDE_Cert.pvk',
    DECRYPTION BY PASSWORD = 'Backup@123!'
);

-- Kiểm tra tên logic file trong file backup (bắt buộc trước khi restore)
RESTORE FILELISTONLY 
FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER_RESTORE_TDE\MSSQL\Backup\QLBONGDA_TDE.bak';

-- Khôi phục cơ sở dữ liệu từ bản backup TDE
RESTORE DATABASE QLBONGDA
FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER_RESTORE_TDE\MSSQL\Backup\QLBONGDA_TDE.bak'
WITH MOVE 'QLBONGDA' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER_RESTORE_TDE\MSSQL\DATA\QLBONGDA.mdf',
     MOVE 'QLBONGDA_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER_RESTORE_TDE\MSSQL\DATA\QLBONGDA_log.ldf';
