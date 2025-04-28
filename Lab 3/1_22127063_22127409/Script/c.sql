use QLSVNhom
go

alter database qlsvnhom
SET COMPATIBILITY_LEVEL = 120

-- Mã hoá sử dụng hệ mã asymmetric cho RSA_512
-- Tạo master key
if not exists (select * from sys.asymmetric_keys where asymmetric_key_id = 101)
	create master key
	encryption by password = 'Matxeluu@07052040*]';
go

-- Tạo certificate
if not exists (select * from sys.certificates where name = 'Cert_RSA_Encryption')
	create certificate Cert_RSA_Encryption
	with subject = 'Certificate for RSA Encryption';
go

-- Stored dùng để thêm mới dữ liệu (Insert) vào table NHANVIEN
CREATE OR ALTER PROCEDURE SP_INS_PUBLIC_NHANVIEN 
    @MANV VARCHAR(20),
    @HOTEN NVARCHAR(100),
    @EMAIL VARCHAR(20),
    @LUONGCB INT,  -- Lương trước khi mã hóa
    @TENDN NVARCHAR(100),
    @MK NVARCHAR(100)  -- Mật khẩu trước khi mã hóa
AS
BEGIN
    -- Mã hóa mật khẩu bằng SHA1
    DECLARE @MATKHAU VARBINARY(MAX);
    SET @MATKHAU = HASHBYTES('SHA1', @MK);

    -- Tạo Asymmetric Key cho nhân viên này (nếu chưa có)
    IF NOT EXISTS (SELECT * FROM sys.asymmetric_keys WHERE name = @MANV)
    BEGIN
        EXEC('CREATE ASYMMETRIC KEY ' + @MANV + '  
              WITH ALGORITHM = RSA_512 ENCRYPTION BY PASSWORD = ''' + @MK + '''');
    END;

    -- Mã hóa lương bằng RSA_512
    DECLARE @LUONG VARBINARY(MAX);
    SET @LUONG = EncryptByAsymKey(AsymKey_ID(@MANV), CAST(@LUONGCB AS VARBINARY));

    -- Kiểm tra nếu mã hóa thất bại
    IF @LUONG IS NULL
    BEGIN
        PRINT N'Lỗi: Mã hóa lương thất bại. Kiểm tra Asymmetric Key.';
        RETURN;
    END

    -- Thêm nhân viên vào bảng NHANVIEN
    INSERT INTO NHANVIEN (MANV, HOTEN, EMAIL, LUONG, TENDN, MATKHAU, PUBKEY)
    VALUES (@MANV, @HOTEN, @EMAIL, @LUONG, @TENDN, @MATKHAU, @MANV);

    PRINT N'Nhân viên đã được thêm thành công!';
END;
GO

EXEC SP_INS_PUBLIC_NHANVIEN 'NV01', 'NGUYEN VAN A', 'NVA@', 3000000, 'NVA', 'abcd12'
go
EXEC SP_INS_PUBLIC_NHANVIEN 'NV02', 'NGUYEN VAN B', 'NVB@', 4000000, 'NVB', 'abcd123'
go

-- Stored dùng để truy vấn dữ liệu nhân viên (NHANVIEN)
CREATE OR ALTER PROCEDURE SP_SEL_PUBLIC_NHANVIEN
    @TENDN NVARCHAR(100),
    @MK NVARCHAR(100)  -- Mật khẩu để mở khóa
AS
BEGIN
    -- Kiểm tra nếu nhân viên tồn tại
    IF NOT EXISTS (SELECT 1 FROM NHANVIEN WHERE TENDN = @TENDN)
    BEGIN
        PRINT N'Lỗi: TENDN không tồn tại!';
        RETURN;
    END;

    -- Lấy giá trị lương đã mã hóa
    DECLARE @LUONG_GIAIMA VARBINARY(MAX);
	DECLARE @PUB_KEY NVARCHAR(100);
    SELECT @LUONG_GIAIMA = LUONG, @PUB_KEY = PUBKEY FROM NHANVIEN WHERE TENDN = @TENDN;

    -- Giải mã lương
    DECLARE @LUONG_DEC INT;
    SET @LUONG_DEC = CAST(DecryptByAsymKey(AsymKey_ID(@PUB_KEY), @LUONG_GIAIMA, @MK) AS INT);

    -- Hiển thị lương gốc
    PRINT 'Lương sau giải mã: ' + CAST(@LUONG_DEC AS NVARCHAR);
    SELECT @LUONG_DEC AS LUONG_GOC;
END;
GO

EXEC SP_SEL_PUBLIC_NHANVIEN 'NVA', 'abcd12';
go
EXEC SP_SEL_PUBLIC_NHANVIEN 'NVB', 'abcd123';
go