use QLBONGDA
go

--SPCau1
CREATE OR ALTER PROCEDURE SPCau1 @TenCLB NVARCHAR(100), @TenQG NVARCHAR(60)
AS 
select ct.mact, ct.hoten, ct.ngaysinh, ct.diachi, ct.vitri 
from CAUTHU	ct
join CAULACBO clb on clb.MACLB = ct.MACLB
join QUOCGIA qg on qg.MAQG = ct.MAQG
where clb.TENCLB = @TenCLB and qg.TENQG = @TenQG
GO

EXEC SPCau1 @TenCLB = N'SHB Đà Nẵng', @TenQG = N'Brazil';
go


--SPCau2
create or alter procedure SPCau2 @Vong int, @Nam int
as
SELECT td.MATRAN, td.NGAYTD, clb1.TENCLB as TENCLB1, clb2.TENCLB as TENCLB2, svd.TENSAN, td.KETQUA
from TRANDAU td
join SANVD svd on svd.MASAN = td.MASAN
join CAULACBO clb1 on clb1.MACLB = td.MACLB1
join CAULACBO clb2 on clb2.MACLB = td.MACLB2
where clb1.MACLB <> clb2.MACLB and td.VONG = @Vong and td.NAM = @Nam
go

exec SPCau2 @Vong = 3, @Nam = 2009
go

--SPCau3
create or alter procedure SPCau3 @TenQG NVARCHAR(60)
as
select hlv.MAHLV, hlv.TENHLV, hlv.NGAYSINH, hlv.DIACHI, hlvclb.VAITRO, clb.TENCLB
from HUANLUYENVIEN hlv
join HLV_CLB hlvclb on hlvclb.MAHLV = hlv.MAHLV
join CAULACBO clb on clb.MACLB = hlvclb.MACLB
join QUOCGIA qg on qg.MAQG = hlv.MAQG
where qg.TENQG = @TenQG
go

exec SPCau3 @TenQG = N'Việt Nam'
go


--SPCau4
CREATE or alter procedure SPCau4  @TenQG NVARCHAR(60)
as
select clb.MACLB, clb.TENCLB, svd.TENSAN, svd.DIACHI, COUNT(clb.MACLB) as SOCAUTHUNUOCNGOAI
from CAUTHU ct
join CAULACBO clb on clb.MACLB = ct.MACLB
join SANVD svd on svd.MASAN = clb.MASAN
join QUOCGIA qg on qg.MAQG = ct.MAQG
where qg.TENQG != @TenQG
group by clb.MACLB, clb.TENCLB, svd.TENSAN, svd.DIACHI
having COUNT(clb.MACLB) >= 2
go

exec SPCau4 @TenQG  = N'Việt Nam'
go

--SPCau5
create or alter procedure SPCau5 @ViTri NVARCHAR(20) 
as 
select t.TENTINH, count(ct.MACT) as SoLuongCauThu
from TINH t
join CAULACBO clb on clb.MATINH = t.MATINH
join CAUTHU ct on ct.MACLB = clb.MACLB
where ct.VITRI = @ViTri
group by t.TENTINH
go

exec SPCau5 @vitri = N'Tiền Đạo'
go

--SPCau6
create or alter procedure SPCau6 @Vong int, @Hang int, @Nam int
as
select clb.TENCLB, t.TENTINH
from BANGXH bxh
join CAULACBO clb on clb.MACLB = bxh.MACLB
join TINH t on t.MATINH = clb.MATINH
where bxh.VONG = @Vong and bxh.HANG = @Hang and bxh.NAM = @Nam
go

exec SPCau6 @Vong = 3, @Hang = 1, @Nam = 2009
go

--SPCau7
create or alter procedure SPCau7 
as
select hlv.TENHLV
from HUANLUYENVIEN hlv
where hlv.MAHLV in (select MAHLV from HLV_CLB) and hlv.DIENTHOAI = NULL
go

exec SPCau7
go

--SPCau8
create or alter procedure SPCau8 @TenQG nvarchar(60) 
as
select hlv.*
from HUANLUYENVIEN hlv
join HLV_CLB hlvclb on hlv.MAHLV = hlvclb.MAHLV
join QUOCGIA qg on hlv.MAQG = qg.MAQG
where hlv.MAHLV not in (select MAHLV from HLV_CLB) and qg.TENQG=@TenQG;
go

exec spcau8  @TenQG = N'Việt Nam'
go

--SPCau9
create or alter procedure SPCau9 @Vong int, @Nam int
as
declare @HangCaoNhat int;
declare @CauLacBoTop1 varchar(5);
select @HangCaoNhat = Min(Hang)
from BANGXH

select @CauLacBoTop1 = bxh.MACLB
from BANGXH bxh
where bxh.HANG = @HangCaoNhat and bxh.NAM = @Nam and bxh.VONG = @Vong

select td.MATRAN, td.NGAYTD, clb1.TENCLB as TENCLB1, clb2.TENCLB as TENCLB2, svd.TENSAN, td.KETQUA
from TRANDAU td
join SANVD svd on svd.MASAN = td.MASAN
join CAULACBO clb1 on clb1.MACLB = td.MACLB1
join CAULACBO clb2 on clb2.MACLB = td.MACLB2
where td.NAM = @Nam and td.VONG <= @Vong and (td.MACLB1 = @CauLacBoTop1 or td.MACLB2 = @CauLacBoTop1)
go

exec SPCau9 @Vong = 3, @Nam = 2009
go

--SPcau10 
create or alter procedure SPCau10 @Vong int, @Nam int
as

declare @HangThapNhat int;
declare @CauLacBoTopCuoi varchar(5);
select @HangThapNhat = Max(Hang)
from BANGXH

select @CauLacBoTopCuoi = bxh.MACLB
from BANGXH bxh
where bxh.HANG = @HangThapNhat and bxh.NAM = @Nam and bxh.VONG = @Vong

select td.MATRAN, td.NGAYTD, clb1.TENCLB as TENCLB1, clb2.TENCLB as TENCLB2, svd.TENSAN, td.KETQUA
from TRANDAU td
join SANVD svd on svd.MASAN = td.MASAN
join CAULACBO clb1 on clb1.MACLB = td.MACLB1
join CAULACBO clb2 on clb2.MACLB = td.MACLB2
where td.NAM = @Nam and td.VONG <= @Vong and (td.MACLB1 = @CauLacBoTopCuoi or td.MACLB2 = @CauLacBoTopCuoi)
go

exec SPCau10 @Vong = 3, @Nam = 2009
go