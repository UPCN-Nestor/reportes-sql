/****** Object:  View [dbo].[ReporteCuotaCapital]    Script Date: 23/06/2025 07:15:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/*
	22/10/2024: Usado en ReporteGlobal.pbix
*/

/* drop VIEW ReporteCuotaCapital */
CREATE VIEW [dbo].[ReporteCuotaCapital] AS
select YEAR(Fecha) Año, MONTH(Fecha) Mes, Caso,
	SUM(SaldoCC) SaldoCC, SUM(SaldoE) SaldoE,
	SUM(ImporteCC) ImporteCC, SUM(ImporteE) ImporteE,
	COUNT(*) Cantidad
from
(
	select FC.FactVto1 Fecha, CS.CompSdo SaldoCC, CS2.CompSdo SaldoE,
		CASE WHEN CS.CompSdo IS NULL and CS2.CompSdo IS NULL THEN 'Ambas Pagas'
			WHEN CS.CompSdo IS NOT NULL and CS2.CompSdo IS NULL THEN 'CC Impaga'
			WHEN CS.CompSdo IS NULL and CS2.CompSdo IS NOT NULL THEN 'Energía Impaga'
			WHEN CS.CompSdo IS NOT NULL and CS2.CompSdo IS NOT NULL THEN 'Ambas Impagas'
		END Caso,
		FE.Fac7NoEImp ImporteCC, FE.Fac7EneImp ImporteE
	from UPCN_COM_PROD.dbo.FACTUC FC
		join UPCN_COM_PROD.dbo.FACTUE FE ON (FC.SucCod = FE.SucCod and FC.CliCod = FE.CliCod and FC.SumNro = FE.SumNro 
			and FC.FrmCod = FE.FrmCod and FC.FactLet = FE.FactLet and FC.FactPtoV = FE.FactPtoV and FC.FactNro = FE.FactNro)
		left join UPCN_COM_PROD.dbo.COMSAL CS on (FC.SucCod = CS.SucCod and FC.CliCod = CS.CliCod and FC.SumNro = CS.SumNro
			and FC.FrmCod = CS.CompTpo and FC.FactLet = CS.CompLet and FC.FactPtoV = CS.CompPtoV and FC.FactNro = CS.CompNro)
		left join UPCN_COM_PROD.dbo.COMSAL CS2 ON (FE.SucCod = CS2.SucCod and FE.CliCod = CS2.CliCod and FE.SumNro = CS2.SumNro
			and FE.Fac7EneFrm = CS2.CompTpo and FE.Fac7EneLet = CS2.CompLet and FE.Fac7EnePto = CS2.CompPtoV and FE.Fac7EneNro = CS2.CompNro)		
	where FC.SucCod = 1 and FC.FactPtoV = 14
		and FC.FactFec > '01/01/2022'
		and FC.FactVto1 < GETDATE()
		and FC.FactFec IS NOT NULL
		and FC.FactAnu = 0
) x
group by YEAR(Fecha), MONTH(Fecha), Caso

GO
