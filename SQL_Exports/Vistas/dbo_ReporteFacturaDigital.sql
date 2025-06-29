/****** Object:  View [dbo].[ReporteFacturaDigital]    Script Date: 23/06/2025 07:15:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* drop view ReporteFacturaDigital */
create view ReporteFacturaDigital as
select C.CliCod Socio, C.SumNro Suministro, 
	case when M.FuenteEmail is not null then 1 else 0 end FacturaDigital,
	case when M.FuenteEmail = 'OficinaVirtual' THEN 1 else 0 end Adhesiones
from [UPCN_COM_PROD].dbo.[CUENTA] C
	left join [UPCN_SISTEMAS].dbo.Mails M
		on (C.CliCod = M.Socio and C.SumNro = M.Suministro)
	outer apply (
		select top(1) * from [UPCN_COM_PROD].dbo.CONTRATO CO
		where C.SucCod = CO.SucCod and C.CliCod = CO.CliCod and C.SumNro = CO.SumNro		
		order by CO.SrvCod
	) CO
where C.SucCod = 1 and C.SumFecBaj = '01/01/1753' and CO.Sum2Sts < 4
GO
