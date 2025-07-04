/****** Object:  View [dbo].[ReporteFacturacionDetallado]    Script Date: 23/06/2025 07:15:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





/*
	22/10/2024: Usado en ReporteGlobal.pbix
*/

/* drop view ReporteFacturacionDetallado */
create view [dbo].[ReporteFacturacionDetallado] AS
SELECT Socio, Suministro, Comprobante, FechaEmision, FechaVencimiento, Servicio, Area, Categoria, Tarifa, GrupoTarifa, Subtotal, Energetico,
	SUM(Importe) Importe, SUM(Saldo) Saldo
FROM
(
	SELECT 
		FC.CliCod Socio,
		FC.SumNro Suministro,
		CONCAT(FC.FrmCod, '-', FC.FactLet, '-', FC.FactPtoV, '-', FC.FactNro) Comprobante,
		FC.FactFec AS FechaEmision,		
		FC.FactVto1 AS FechaVencimiento,
		CASE WHEN FC.FactVto1 > GETDATE() THEN 'N' ELSE 'S' END Vencida,
		FS.Fac1Srv Servicio,
		FS.Fac1Are Area,
		FS.Fac1Ctg Categoria,
		FS.Fac1EttCod Tarifa,
		CASE WHEN FS.Fac1EttCod IN ('T1AP') THEN 'Alumbrado Público'
			WHEN FS.Fac1EttCod IN ('AP', 'APN') THEN 'APN'
			WHEN FS.Fac1EttCod IN ('SS') THEN 'Servicios Sociales'
			WHEN FS.Fac1EttCod IN ('TELEC') THEN 'Telecomunicaciones'
			WHEN FS.Fac1EttCod IN ('T1R', 'T1RE', 'T1RP', 'T1REG', 'T1RG', 'TIS', 'TISG', 'TISP', 'TSE') THEN 'T1R - Residencial'
			WHEN FS.Fac1EttCod IN ('T1G', 'T1GBP', 'T1GCB', 'T1GE', 'T1GP', 'MUNI') THEN 'T1G - Comercial'
			WHEN FS.Fac1EttCod IN ('T2BT', 'T2MT', 'T3BT', 'T3MT', 'T5MT') THEN 'T2-T3-T5 - Grandes'
			WHEN FS.Fac1EttCod IN ('T4', 'T4G', 'T4NR') THEN 'T4 - Rural'
			ELSE FS.Fac1EttCod
		END GrupoTarifa,
		CASE WHEN FC.FrmCod = 50 THEN -FI.Fac2Imp1 ELSE FI.Fac2Imp1 END Importe,
		CASE WHEN FC.FrmCod = 50 THEN -FI.Fac2Sdo ELSE FI.Fac2Sdo END Saldo,
		CASE WHEN FI.CliCod = 1100 THEN 'Municipalidad' 
			WHEN FI.Fac2Cnp BETWEEN 0 and 38 AND FI.Fac2Itm NOT BETWEEN 2007 and 2010 THEN 'Energía'
			WHEN FI.Fac2Itm BETWEEN 2007 and 2010 THEN 'ICT'
			WHEN FI.Fac2Cnp in (200, 901) THEN 'Cuota Capital'
			WHEN FI.Fac2Cnp BETWEEN 700 and 750 THEN 'Impuestos'
			WHEN FI.Fac1Srv = 10 AND (FI.Fac2Cnp BETWEEN 100 and 110 OR FI.Fac2Cnp BETWEEN 346 AND 351 OR FI.Fac2Cnp BETWEEN 390 AND 602
				OR FI.Fac2Cnp = 960) THEN 'Servicios Sociales'
			WHEN FI.Fac1Srv = 5 AND (FI.Fac2Cnp BETWEEN 620 and 646 OR FI.Fac2Cnp BETWEEN 661 and 675) THEN 'Telecomunicaciones'
			WHEN FI.Fac2Itm = 8550 THEN 'Suscrip. Acciones'
			ELSE 'Otros' END Subtotal,
		CASE WHEN FC.FactEnerSN = 'N' THEN 'No energético' ELSE 'Energético' END AS Energetico
	FROM [UPCN_COM_PROD].dbo.FACTUC FC
		OUTER APPLY (SELECT TOP(1) * FROM [UPCN_COM_PROD].dbo.FACTUS FS WHERE FC.SucCod = FS.SucCod AND FC.CliCod = FS.CliCod AND FC.SumNro = FS.SumNro AND
			FC.FrmCod = FS.FrmCod and FC.FactLet = FS.FactLet and FC.FactPtoV = FS.FactPtoV and FC.FactNro = FS.FactNro 
			ORDER BY FS.Fac1Srv
		) FS
		JOIN [UPCN_COM_PROD].dbo.FACTUI FI ON (FC.SucCod = FI.SucCod and FC.CliCod = FI.CliCod and FC.SumNro = FI.SumNro and FC.FrmCod = FI.FrmCod 
			and FC.FactLet = FI.FactLet and FC.FactPtoV = FI.FactPtoV and FC.FactNro = FI.FactNro)

	WHERE FC.SucCod = 1 AND FC.FrmCod IN (1,3,50) AND YEAR(FC.FactFec) >= YEAR(GETDATE())-1 /*AND FC.CliCod <> 1100*/ AND FC.FactPtoV in (0,12,13,14)
		and FC.Factquin <> 9 /*and FC.FactAnu <> 1*/  -- ¿Qué pasa con las anuladas por NC? ¿No estoy incluyendo la NC sin incluir la original?
		and FC.FactNro > 0
		and FC.FactVto1 < DATEADD(MONTH, 3, GETDATE())
) X
GROUP BY Socio, Suministro, Comprobante, FechaEmision, FechaVencimiento, Servicio, Area, Categoria, Tarifa, GrupoTarifa, Subtotal, Energetico

GO
