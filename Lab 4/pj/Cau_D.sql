-- Script tạo các Stored Procedure cho hệ thống QLSVNhom
USE QLSVNhom;
GO

-- 1. Xử lý đăng nhập nhân viên
CREATE OR ALTER PROCEDURE SP_LOGIN_PUBLIC_ENCRYPT_NHANVIEN
    @TENDN NVARCHAR(50),
    @MK VARBINARY(MAX)	-- Mật khẩu đã được mã hóa SHA1 từ client
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra nhân viên có tồn tại hay không
    IF NOT EXISTS (SELECT 1 FROM NHANVIEN WHERE TENDN = @TENDN AND MATKHAU = @MK)
    BEGIN
        SELECT -1 AS Result, N'Tên đăng nhập hoặc mật khẩu không chính xác.' AS Message;
        RETURN;
    END;

    -- Trả về thông tin nhân viên nếu đăng nhập thành công
    SELECT 1 AS Result, MANV, HOTEN 
    FROM NHANVIEN 
    WHERE TENDN = @TENDN;
END;
GO

-- 2. Thêm mới nhân viên
CREATE OR ALTER PROCEDURE SP_INS_PUBLIC_ENCRYPT_NHANVIEN
    @MANV NVARCHAR(10),
    @HOTEN NVARCHAR(100),
    @EMAIL NVARCHAR(100),
    @LUONG VARBINARY(MAX),
    @TENDN NVARCHAR(50),
    @MK VARBINARY(MAX),  -- Mật khẩu đã được mã hóa SHA1 từ client
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
    VALUES (@MANV, @HOTEN, @EMAIL, @LUONG, @TENDN, @MK, @PUB);

    -- Trả về thành công
    SELECT 1 AS Result, N'Nhân viên đã được thêm thành công.' AS Message;
END;
GO

-- 3. Cập nhật thông tin nhân viên
CREATE OR ALTER PROCEDURE SP_UPDATE_PUBLIC_ENCRYPT_NHANVIEN
    @MANV NVARCHAR(10),
    @HOTEN NVARCHAR(100),
    @EMAIL NVARCHAR(100),
    @LUONG VARBINARY(MAX),
    @TENDN NVARCHAR(50),
    @MK VARBINARY(MAX)  -- Mật khẩu đã được mã hóa SHA1 từ client
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra nhân viên có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM NHANVIEN WHERE MANV = @MANV)
    BEGIN
        SELECT -1 AS Result, N'Nhân viên không tồn tại.' AS Message;
        RETURN;
    END

    -- Kiểm tra trùng lặp tên đăng nhập với nhân viên khác
    IF EXISTS (SELECT 1 FROM NHANVIEN WHERE TENDN = @TENDN AND MANV <> @MANV)
    BEGIN
        SELECT -2 AS Result, N'Tên đăng nhập đã được sử dụng bởi nhân viên khác.' AS Message;
        RETURN;
    END

    -- Cập nhật thông tin nhân viên
    UPDATE NHANVIEN 
    SET HOTEN = @HOTEN, EMAIL = @EMAIL, LUONG = @LUONG, 
        TENDN = @TENDN, MATKHAU = @MK
    WHERE MANV = @MANV;

    -- Trả về kết quả thành công
    SELECT 1 AS Result, N'Cập nhật thông tin nhân viên thành công.' AS Message;
END;
GO

-- 4. Quản lý nhân viên
CREATE OR ALTER PROCEDURE SP_SEL_NHANVIEN
AS
BEGIN
    SET NOCOUNT ON;

    -- Lấy danh sách nhân viên
    SELECT MANV, HOTEN, EMAIL, LUONG FROM NHANVIEN;
END;
GO

-- 5. Nhập điểm sinh viên với điểm thi đã được mã hóa
CREATE OR ALTER PROCEDURE SP_INS_PUBLIC_ENCRYPT_BANGDIEM
    @MASV NVARCHAR(20),
    @MAHP NVARCHAR(20),
    @DIEMTHI VARBINARY(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra sinh viên có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM SINHVIEN WHERE MASV = @MASV)
    BEGIN
        SELECT -1 AS Result;
        RETURN;
    END

    -- Kiểm tra học phần có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM HOCPHAN WHERE MAHP = @MAHP)
    BEGIN
        SELECT -1 AS Result;
        RETURN;
    END

    -- Kiểm tra sinh viên đã có điểm chưa
    IF EXISTS (SELECT 1 FROM BANGDIEM WHERE MASV = @MASV AND MAHP = @MAHP)
    BEGIN
        SELECT -2 AS Result;
        RETURN;
    END

    -- Nhập điểm
    INSERT INTO BANGDIEM (MASV, MAHP, DIEMTHI)
    VALUES (@MASV, @MAHP, @DIEMTHI);

    -- Trả về kết quả thành công
    SELECT 1 AS Result;
END;
GO

-- 6. Truy vấn điểm thi với điểm thi chưa giải mã
CREATE OR ALTER PROCEDURE SP_SEL_PUBLIC_ENCRYPT_BANGDIEM
    @MASV VARCHAR(20),
    @MAHP VARCHAR(20),
    @MANV VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Trả về điểm chưa giải mã
    IF EXISTS (SELECT 1 FROM BANGDIEM WHERE MASV = @MASV AND MAHP = @MAHP)
    BEGIN
        SELECT MASV, MAHP, DIEMTHI
        FROM BANGDIEM
        WHERE MASV = @MASV AND MAHP = @MAHP;
    END
    ELSE
    BEGIN
        SELECT NULL AS MASV, NULL AS MAHP, NULL AS DIEMTHI;
    END
END;
GO

--7. Thêm lớp mới
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
GO

--8. update lớp học
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
GO

--9. xóa lớp học
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
GO

--10. xem danh sách lớp
CREATE OR ALTER PROCEDURE SP_SEL_LOP
	@MANV NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Lấy danh sách lớp
    SELECT MALOP, TENLOP FROM LOP WHERE MANV = @MANV;
END;
GO

--11. Lấy danh sách sinh viên trong lớp do nhân viên quản lý
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
GO

--12. Thêm sinh viên vào lớp
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

	DECLARE @HASHED_PASSWORD VARBINARY(20);
    SET @HASHED_PASSWORD = HASHBYTES('SHA1', 'default');

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
GO

--13. Cập nhật thông tin sinh viên
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
GO

--14. Xóa sinh viên
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