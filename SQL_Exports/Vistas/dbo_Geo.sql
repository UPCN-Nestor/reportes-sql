/****** Object:  View [dbo].[Geo]    Script Date: 19/06/2025 07:15:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW Geo AS
select c.CliCod Socio, c.SumNro Suministro, CONCAT(c.CliCod, '-', c.SumNro) "Soc-Sumi",
	i.InmLatitud Latitud, i.InmLongitud Longitud
from [UPCN_COM_PROD].dbo.[CUENTA] c
	join [UPCN_COM_PROD].dbo.[INMUEBLE] i
		on (c.SucCod = i.SucCod and c.InmCod = i.InmCod)
	
GO
