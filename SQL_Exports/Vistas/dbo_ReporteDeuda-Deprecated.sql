/****** Object:  View [dbo].[ReporteDeuda-Deprecated]    Script Date: 23/06/2025 07:15:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





/*
	17/03/2025, Nestor: Renombrado a "ReporteDeuda-Deprecated" porque no se usa en PowerBI.
*/

/* drop view [dbo].[[ReporteDeuda-Deprecated]] */
create view [dbo].[ReporteDeuda-Deprecated] as

SELECT CS.CliCod as Socio,
	CS.SumNro as Suministro,
	CONCAT(CS.CliCod, '-',CS.SumNro) as "Soc-Sumi",
	P.CliApe as Nombre,
	FS.Fac1EttCod as Tarifa,
	FS.Fac1Srv as ServicioPrincipal,
	FS.Fac1Are as Area,
	CompTpo as TipoComprobante,
	CONCAT(CompTpo, '-', CompLet, '-', CompPtoV, '-', CompNro) as Comprobante,
	CompFec as Emision,
	CompVto1 as Vencimiento,
	YEAR(CompVto1) AS VencimientoAño,
	CONCAT(YEAR(CompVto1), '-', MONTH(CompVto1)) AS VencimientoAñoMes,
	CASE WHEN CompVto1 > GETDATE() THEN 'N' ELSE 'S' END Vencida,
	CASE WHEN CompTpo IN (1,3) THEN CompImp WHEN CompTpo IN (50,60) THEN CompImp * -1 END AS Saldo,
	CO.Sum2Sts Estado,
	CASE WHEN CO.Sum2Sts = 4 THEN 'Desconectado' ELSE 'Conectado' END EstadoCD,
	Sum2FecSts FechaEstado,
	CASE WHEN CompEnerSN = 'N' THEN 'No energético' ELSE 'Energético' END Energetico
FROM [UPCN_COM_PROD].dbo.COMSAL CS
	OUTER APPLY (SELECT TOP(1) CliApe FROM [UPCN_COM_PROD].dbo.PERSONA P WHERE CS.SucCod = P.SucCod and CS.CliCod = P.CliCod) P
	OUTER APPLY (SELECT TOP(1) * FROM [UPCN_COM_PROD].dbo.CONTRATO CO WHERE CS.SucCod = CO.SucCod AND CS.CliCod = CO.CliCod AND CS.SumNro = CO.SumNro 
		ORDER BY CO.SrvCod) CO
	OUTER APPLY (SELECT TOP(1) FS.Fac1EttCod, FS.Fac1Srv, FS.Fac1Are 
		FROM [UPCN_COM_PROD].dbo.FACTUS FS 
		WHERE CS.SucCod = FS.SucCod  AND CS.CliCod = FS.CliCod AND CS.SumNro = FS.SumNro AND CS.CompFec = FS.FactFec AND CS.CompTpo = FS.FrmCod 
			AND CS.CompLet = FS.FactLet AND CS.CompPtoV = FS.FactPtoV AND CS.CompNro = FS.FactNro 
		ORDER BY FS.Fac1Srv
	) FS
WHERE CS.SucCod = 1 AND CS.CliCod <> 1100  
	AND CS.CompPtoV IN (0,12,13,14) -- Hay deuda rara en pto.vta. 8
	AND CS.CompVto1 > '01/01/2022'

GO
