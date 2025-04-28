-- Tạo Database QLSVNhom
CREATE DATABASE QLSVNhom;
GO

drop database QLSVNhom
go

-- Sử dụng Database QLSVNhom
USE QLSVNhom;
GO

-- Tạo bảng SINHVIEN
CREATE TABLE SINHVIEN (
    MASV VARCHAR(20) PRIMARY KEY,
    HOTEN NVARCHAR(100) NOT NULL,
    NGAYSINH DATETIME,
    DIACHI NVARCHAR(200),
    MALOP NVARCHAR(200),
    TENDN NVARCHAR(100) UNIQUE NOT NULL,
    MATKHAU VARBINARY(MAX) NOT NULL
);
GO

-- Tạo bảng NHANVIEN
CREATE TABLE NHANVIEN (
    MANV VARCHAR(20) PRIMARY KEY,
    HOTEN NVARCHAR(100) NOT NULL,
    EMAIL VARCHAR(20),
    LUONG VARBINARY(MAX),
    TENDN NVARCHAR(100) UNIQUE NOT NULL,
    MATKHAU VARBINARY(MAX) NOT NULL,
    PUBKEY VARCHAR(20) -- Tên khóa công khai
);
GO

-- Tạo bảng LOP
CREATE TABLE LOP (
    MALOP VARCHAR(20) PRIMARY KEY,
    TENLOP NVARCHAR(100) NOT NULL,
    MANV VARCHAR(20),
    FOREIGN KEY (MANV) REFERENCES NHANVIEN(MANV)
);
GO

-- Tạo bảng HOCPHAN
CREATE TABLE HOCPHAN (
    MAHP VARCHAR(20) PRIMARY KEY,
    TENHP NVARCHAR(100) NOT NULL,
    SOTC INT
);
GO

-- Tạo bảng BANGDIEM
CREATE TABLE BANGDIEM (
    MASV VARCHAR(20),
    MAHP VARCHAR(20),
    DIEMTHI VARBINARY(MAX), -- Mã hóa điểm thi
    PRIMARY KEY (MASV, MAHP),
    FOREIGN KEY (MASV) REFERENCES SINHVIEN(MASV),
    FOREIGN KEY (MAHP) REFERENCES HOCPHAN(MAHP)
);
GO

-- insert values
select * from nhanvien

insert into LOP(MALOP, TENLOP, MANV)
values	('CTT1',N'Công nghệ thông tin','NV01'),
('CTT2',N'Công nghệ thông tin','NV01'),
('CTT3',N'Công nghệ thông tin','NV01'),
('CTT4',N'Công nghệ thông tin','NV01'),
('CTT5',N'Công nghệ thông tin','NV01'),

('CNSH1',N'Công nghệ sinh học','NV02'),
('CNSH2',N'Công nghệ sinh học','NV02'),
('CNSH3',N'Công nghệ sinh học','NV02'),
('CNSH4',N'Công nghệ sinh học','NV02'),
('CNSH5',N'Công nghệ sinh học','NV02')
go

select * from lop

insert into SINHVIEN(MASV, HOTEN, NGAYSINH, DIACHI, MALOP, TENDN, MATKHAU)
VALUES	('1712601',N'Trịnh Văn Minh','1/1/1999',N'Thành phố Hồ Chí Minh','CTT5','TVM',convert(varbinary,'tvm601')),
		('1712633',N'Nguyễn Long Nhật','1/2/1999',N'Bình Dương','CNSH1','NLN',convert(varbinary,'nln633'))

select * from sinhvien

insert into HOCPHAN(MAHP, TENHP, SOTC)
VALUES	('TLDC', N'Tâm Lý Đại Cương',3),
		('CTDL',N'Cấu trúc dữ liệu và giải thuật',4),
		('SH',N'Sinh học',4),
		('VLDC1',N'Vật lý đại cương 1',3),
		('VLDC2',N'Vật lý đại cương 2',3)
go

select * from hocphan

insert into BANGDIEM(MASV,MAHP,DIEMTHI)
VALUES	('1712601','CTDL',convert(varbinary,10)),
		('1712633','TLDC',convert(varbinary,5))

select * from BANGDIEM