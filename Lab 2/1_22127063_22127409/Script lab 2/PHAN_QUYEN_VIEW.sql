﻿use QLBONGDA
go

--Cấp quyền cho BDREAD
GRANT SELECT ON SCHEMA::dbo TO BDRead

--Cấp quyền cho BDU01
GRANT SELECT ON vCau5 TO BDU01
GRANT SELECT ON vCau6 TO BDU01
GRANT SELECT ON vCau7 TO BDU01
GRANT SELECT ON vCau8 TO BDU01
GRANT SELECT ON vCau9 TO BDU01
GRANT SELECT ON vCau10 TO BDU01

--Cấp quyền cho BDU03
GRANT SELECT ON vCau1 TO BDU03
GRANT SELECT ON vCau2 TO BDU03
GRANT SELECT ON vCau3 TO BDU03
GRANT SELECT ON vCau4 TO BDU03

--Cấp quyền cho BDU04
GRANT SELECT ON vCau1 TO BDU04
GRANT SELECT ON vCau2 TO BDU04
GRANT SELECT ON vCau3 TO BDU04
GRANT SELECT ON vCau4 TO BDU04
