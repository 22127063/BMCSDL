USE QLSVNhom
GO

-- Stored dùng để thêm mới dữ liệu (Insert) vào table NHANVIEN
CREATE OR ALTER PROCEDURE SP_INS_PUBLIC_ENCRYPT_NHANVIEN
    @MANV NVARCHAR(10),
    @HOTEN NVARCHAR(100),
    @EMAIL NVARCHAR(100),
    @LUONG NVARCHAR(MAX),
    @TENDN NVARCHAR(50),
    @MK NVARCHAR(MAX),  -- Mật khẩu đã được mã hóa SHA1 từ client
    @PUB NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra trùng lặp
    IF EXISTS (SELECT 1 FROM NHANVIEN WHERE MANV = @MANV)
    BEGIN
        SELECT -1 AS Result, N'Mã nhân viên đã tồn tại.' AS Message;
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM NHANVIEN WHERE TENDN = @TENDN)
    BEGIN
        SELECT -1 AS Result, N'Tên đăng nhập đã tồn tại.' AS Message;
        RETURN;
    END

    -- Thêm nhân viên
    INSERT INTO NHANVIEN (MANV, HOTEN, EMAIL, LUONG, TENDN, MATKHAU, PUBKEY)
    VALUES (@MANV, @HOTEN, @EMAIL, CONVERT(VARBINARY(MAX), @LUONG), @TENDN, CONVERT(VARBINARY(MAX), @MK), @PUB);

    -- Trả về thành công
    SELECT 1 AS Result, N'Nhân viên đã được thêm thành công.' AS Message;
END;
GO

EXEC SP_INS_PUBLIC_ENCRYPT_NHANVIEN  
    'NV01',  
    'NGUYEN VAN A',  
    'NVA@',
    'LLLLLL',
    'NVA',
    'MKMKMKMK',
    'PUBPUB';
GO

-- Stored dùng để truy vấn dữ liệu nhân viên (NHANVIEN)
CREATE PROCEDURE SP_SEL_PUBLIC_ENCRYPT_NHANVIEN
    @TENDN NVARCHAR(50),
    @MK NVARCHAR(100)  -- Mật khẩu đã được mã hóa SHA1 từ client
AS
BEGIN
    -- Truy vấn thông tin nhân viên nếu tên đăng nhập và mật khẩu khớp
    SELECT 
        MANV, 
        HOTEN, 
        EMAIL, 
        LUONG  -- Lương đã được mã hóa RSA (chưa giải mã)
    FROM NHANVIEN
    WHERE TENDN = @TENDN AND MATKHAU = @MK;
END;
GO

EXEC SP_SEL_PUBLIC_ENCRYPT_NHANVIEN 'NVA', 'MKMKMKMK'
GO
