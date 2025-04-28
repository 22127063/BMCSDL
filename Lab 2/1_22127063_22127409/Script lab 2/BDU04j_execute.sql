use QLBONGDA
go

EXEC SPCau1 N'SHB Đà Nẵng', N'Brazil'; --Thành công
EXEC SPCau10 3, 2009; --Không thành công vì không được phân quyền
EXEC SPCau3 N'Việt Nam'; --Thành công
EXEC SPCau4 N'Việt Nam'; --Thành công