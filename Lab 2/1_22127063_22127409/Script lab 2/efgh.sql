-- e)
create or alter procedure SP_SEL_NO_ENCRYPT
	@TenCLB nvarchar(100),
	@TenQG nvarchar(60)
as
	begin
		select ct.SO, ct.HOTEN, ct.NGAYSINH,
		ct.DIACHI, ct.VITRI
		from CAUTHU ct
		join CAULACBO clb on clb.MACLB = ct.MACLB
		join QUOCGIA qg on qg.MAQG = ct.MAQG
		where clb.TENCLB = @TenCLB
		and qg.TENQG = @TenQG
	end
GO

-- f)
create or alter procedure SP_SEL_ENCRYPT
	@TenCLB nvarchar(100),
	@TenQG nvarchar(60)
with encryption
as
	begin
		select ct.SO, ct.HOTEN, ct.NGAYSINH,
		ct.DIACHI, ct.VITRI
		from CAUTHU ct
		join CAULACBO clb on clb.MACLB = ct.MACLB
		join QUOCGIA qg on qg.MAQG = ct.MAQG
		where clb.TENCLB = @TenCLB
		and qg.TENQG = @TenQG
	end
GO

--g)
exec SP_SEL_NO_ENCRYPT @TenCLB = N'SHB Đà Nẵng', @TenQG = N'Brazil'

exec SP_SEL_ENCRYPT @TenCLB = N'SHB Đà Nẵng', @TenQG = N'Brazil'

exec sp_helptext 'SP_SEL_NO_ENCRYPT'

exec sp_helptext 'SP_SEL_ENCRYPT'