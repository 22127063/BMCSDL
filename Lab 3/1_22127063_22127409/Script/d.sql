USE QLSVNhom;
GO

-- Tạo chứng chỉ dùng để mã hóa khóa đối xứng
CREATE CERTIFICATE DiemThiCert  
WITH SUBJECT = 'Certificate for encrypting exam scores';  

-- Tạo khóa đối xứng và mã hóa bằng chứng chỉ
CREATE SYMMETRIC KEY DiemThiKey  
WITH ALGORITHM = AES_256  
ENCRYPTION BY CERTIFICATE DiemThiCert;


--  kiểm tra đăng nhập
CREATE OR ALTER PROCEDURE SP_LOGIN_NHANVIEN
    @MANV VARCHAR(20),
    @MATKHAU NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @HASHED_PASSWORD VARBINARY(20);
    SET @HASHED_PASSWORD = HASHBYTES('SHA1', @MATKHAU);

    IF EXISTS (
        SELECT 1 FROM NHANVIEN 
        WHERE MANV = @MANV AND MATKHAU = @HASHED_PASSWORD
    )
    BEGIN
        -- Trả về thông tin nhân viên
        SELECT MANV, HOTEN, EMAIL FROM NHANVIEN WHERE MANV = @MANV;
    END
    ELSE
    BEGIN
        SELECT -1 AS Result;
    END
END;


-- thêm lớp mới
CREATE OR ALTER PROCEDURE SP_INS_LOP
    @MALOP VARCHAR(20),
    @TENLOP NVARCHAR(100),
    @MANV VARCHAR(20) -- Nhân viên quản lý lớp
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra trùng mã lớp
    IF EXISTS (SELECT 1 FROM LOP WHERE MALOP = @MALOP)
    BEGIN
        SELECT -2 AS Result;  -- Trả về lỗi
        RETURN;
    END

    -- Thêm lớp mới
    INSERT INTO LOP (MALOP, TENLOP, MANV)
    VALUES (@MALOP, @TENLOP, @MANV);

	SELECT 1 AS Result;  -- Trả về thành công
END;

-- update lớp học
CREATE OR ALTER PROCEDURE SP_UPDATE_LOP
    @MALOP VARCHAR(20),
    @TENLOP NVARCHAR(100),
    @MANV VARCHAR(20) -- Nhân viên thực hiện cập nhật
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra lớp tồn tại và nhân viên có quyền cập nhật không
    IF NOT EXISTS (SELECT 1 FROM LOP WHERE MALOP = @MALOP AND MANV = @MANV)
    BEGIN
        SELECT -1 AS Result;  -- Lớp không tồn tại hoặc không có quyền cập nhật
        RETURN;
    END

    -- Cập nhật thông tin lớp
    UPDATE LOP
    SET TENLOP = @TENLOP
    WHERE MALOP = @MALOP AND MANV = @MANV;

    SELECT 1 AS Result;  -- Cập nhật thành công
END;

-- xóa lớp học
CREATE OR ALTER PROCEDURE SP_DELETE_LOP
    @MALOP VARCHAR(20),
    @MANV VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra nếu lớp không tồn tại hoặc không thuộc quyền quản lý
    IF NOT EXISTS (SELECT 1 FROM LOP WHERE MALOP = @MALOP AND MANV = @MANV)
    BEGIN
        SELECT -1 AS Result;  -- Trả về giá trị có thể đọc từ Python
        RETURN;
    END

	-- Xóa tất cả sinh viên thuộc lớp trước
    DELETE FROM SINHVIEN WHERE MALOP = @MALOP;

    -- Xóa lớp
    DELETE FROM LOP WHERE MALOP = @MALOP;
    SELECT 1 AS Result;  -- Trả về giá trị thành công
END;

-- xem danh sách lớp
CREATE OR ALTER PROCEDURE SP_SEL_LOP
	@MANV NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Lấy danh sách lớp
    SELECT MALOP, TENLOP FROM LOP WHERE MANV = @MANV;
END;


-- Lấy danh sách sinh viên trong lớp do nhân viên quản lý
CREATE OR ALTER PROCEDURE SP_SEL_SINHVIEN_LOP
    @MANV VARCHAR(20) -- Mã nhân viên đăng nhập
AS
BEGIN
    SET NOCOUNT ON;

    -- Chỉ lấy sinh viên thuộc lớp do nhân viên quản lý
    SELECT SV.MASV, SV.HOTEN, SV.NGAYSINH, SV.DIACHI, L.TENLOP
    FROM SINHVIEN SV
    JOIN LOP L ON SV.MALOP = L.MALOP
    WHERE L.MANV = @MANV;
END;

--Thêm sinh viên vào lớp
CREATE OR ALTER PROCEDURE SP_INS_SINHVIEN
    @MASV NVARCHAR(20),
    @HOTEN NVARCHAR(100),
    @NGAYSINH DATETIME,
    @DIACHI NVARCHAR(200),
    @MALOP NVARCHAR(20),
    @MANV VARCHAR(20) -- Kiểm tra quyền thêm vào lớp
AS
BEGIN
    SET NOCOUNT ON;

	DECLARE @TENDN NVARCHAR(100);
    SET @TENDN = @MASV;

    -- Kiểm tra quyền quản lý lớp
    IF NOT EXISTS (SELECT 1 FROM LOP WHERE MALOP = @MALOP AND MANV = @MANV)
    BEGIN
        SELECT -1 AS Result;  -- Không có quyền hoặc lớp không tồn tại
        RETURN;
    END

    -- Kiểm tra xem sinh viên đã tồn tại chưa
    IF EXISTS (SELECT 1 FROM SINHVIEN WHERE MASV = @MASV)
    BEGIN
        SELECT -2 AS Result;  -- Sinh viên đã tồn tại
        RETURN;
    END

    -- Thêm sinh viên mới
    INSERT INTO SINHVIEN (MASV, HOTEN, NGAYSINH, DIACHI, MALOP, TENDN, MATKHAU)
    VALUES (@MASV, @HOTEN, @NGAYSINH, @DIACHI, @MALOP, @TENDN, @HASHED_PASSWORD);

    SELECT 1 AS Result;  -- Thành công
END;

-- Cập nhật thông tin sinh viên
CREATE OR ALTER PROCEDURE SP_UPDATE_SINHVIEN
    @MASV NVARCHAR(20),
    @HOTEN NVARCHAR(100),
    @NGAYSINH DATETIME,
    @DIACHI NVARCHAR(200),
    @MANV VARCHAR(20) -- Kiểm tra quyền
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra quyền
    IF NOT EXISTS (
        SELECT 1 FROM SINHVIEN SV
        JOIN LOP L ON SV.MALOP = L.MALOP
        WHERE SV.MASV = @MASV AND L.MANV = @MANV
    )
    BEGIN
        SELECT -1 AS Result;
        RETURN;
    END

    -- Cập nhật thông tin
    UPDATE SINHVIEN
    SET HOTEN = @HOTEN, NGAYSINH = @NGAYSINH, DIACHI = @DIACHI
    WHERE MASV = @MASV;

    SELECT 1 AS Result;
END;

-- Xóa sinh viên
CREATE OR ALTER PROCEDURE SP_DELETE_SINHVIEN
    @MASV NVARCHAR(20),
    @MANV VARCHAR(20) -- Kiểm tra quyền
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra quyền
    IF NOT EXISTS (
        SELECT 1 FROM SINHVIEN SV
        JOIN LOP L ON SV.MALOP = L.MALOP
        WHERE SV.MASV = @MASV AND L.MANV = @MANV
    )
    BEGIN
        SELECT -1 AS Result;
        RETURN;
    END

	-- Xóa điểm của sinh viên
	DELETE FROM BANGDIEM WHERE MASV = @MASV

    -- Xóa sinh viên
    DELETE FROM SINHVIEN WHERE MASV = @MASV;

    SELECT 1 AS Result;
END;

-- Lưu điểm thi
CREATE OR ALTER PROCEDURE SP_INS_BANGDIEM
    @MASV VARCHAR(20),
    @MAHP VARCHAR(20),
    @DIEMTHI FLOAT,
    @MANV VARCHAR(20) -- Nhân viên nhập điểm
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;

    -- Kiểm tra quyền nhập điểm
    IF NOT EXISTS (
        SELECT 1 FROM SINHVIEN SV
        JOIN LOP L ON SV.MALOP = L.MALOP
        WHERE SV.MASV = @MASV AND L.MANV = @MANV
    )
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT -1 AS Result;
        RETURN;
    END

    -- Kiểm tra mã môn học có tồn tại
    IF NOT EXISTS (SELECT 1 FROM HOCPHAN WHERE MAHP = @MAHP)
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT -1 AS Result;
        RETURN;
    END

    -- Lấy Public Key của nhân viên
    DECLARE @PUBKEY VARCHAR(50);
    SELECT @PUBKEY = PUBKEY FROM NHANVIEN WHERE MANV = @MANV;

    -- Mở khóa trước khi mã hóa
    OPEN SYMMETRIC KEY DiemThiKey DECRYPTION BY CERTIFICATE DiemThiCert;

    -- Kiểm tra xem khóa đã mở chưa
    IF NOT EXISTS (SELECT 1 FROM sys.openkeys WHERE key_name = 'DiemThiKey')
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT -4 AS Result;
        RETURN;
    END

    -- Mã hóa điểm
    DECLARE @ENCRYPTED_SCORE VARBINARY(MAX);
    SET @ENCRYPTED_SCORE = EncryptByKey(Key_GUID('DiemThiKey'), CAST(@DIEMTHI AS VARCHAR(10)));

    -- Kiểm tra nếu mã hóa thất bại
    IF @ENCRYPTED_SCORE IS NULL
    BEGIN
        CLOSE SYMMETRIC KEY DiemThiKey;
        ROLLBACK TRANSACTION;
        SELECT -5 AS Result;
        RETURN;
    END

    -- Lưu vào bảng điểm
    INSERT INTO BANGDIEM (MASV, MAHP, DIEMTHI)
    VALUES (@MASV, @MAHP, @ENCRYPTED_SCORE);

    -- Đóng khóa và commit transaction
    CLOSE SYMMETRIC KEY DiemThiKey;
    COMMIT TRANSACTION;

    SELECT 1 AS Result;
END;

-- Truy vấn điểm thi
CREATE OR ALTER PROCEDURE SP_SEL_BANGDIEM
    @MASV VARCHAR(20),
    @MAHP VARCHAR(20),
    @MANV VARCHAR(20) -- Nhân viên truy vấn điểm
AS
BEGIN
    SET NOCOUNT ON;

    -- Mở khóa bí mật (nếu chưa mở)
    OPEN SYMMETRIC KEY DiemThiKey DECRYPTION BY CERTIFICATE DiemThiCert;

    -- Giải mã điểm thi
    DECLARE @DECRYPTED_SCORE VARCHAR(10);
    SELECT @DECRYPTED_SCORE = CONVERT(VARCHAR, DecryptByKey(DIEMTHI))
    FROM BANGDIEM
    WHERE MASV = @MASV AND MAHP = @MAHP;

    -- Trả về điểm đã giải mã
    SELECT MASV, MAHP, CAST(@DECRYPTED_SCORE AS FLOAT) AS DIEMTHI
    FROM BANGDIEM
    WHERE MASV = @MASV AND MAHP = @MAHP;

    -- Đóng khóa bí mật
    CLOSE SYMMETRIC KEY DiemThiKey;
END;


