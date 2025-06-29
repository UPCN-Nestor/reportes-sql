/****** Object:  View [dbo].[ReporteFacturacionResumido]    Script Date: 23/06/2025 07:15:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








/* drop view ReporteFacturacionResumido */
CREATE VIEW [dbo].[ReporteFacturacionResumido] AS

SELECT MesEmision, AñoEmision, FechaEmision, MesVto, AñoVto, Area, Categoria, Tarifa,
	Subtotal, SUM(Importe) Importe, SUM(Saldo) Saldo
FROM
(
	SELECT MONTH(FC.FactFec) AS MesEmision,
		YEAR(FC.FactFec) AS AñoEmision,
		FC.FactFec AS FechaEmision,
		MONTH(FC.FactVto1) AS MesVto,
		YEAR(FC.FactVto1) AS AñoVto,
		FS.Fac1Srv Servicio,
		FS.Fac1Are Area,
		FS.Fac1Ctg Categoria,
		FS.Fac1EttCod Tarifa,	
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
			ELSE 'Otros' END Subtotal
	FROM [UPCN_COM_PROD].dbo.FACTUC FC
		OUTER APPLY (SELECT TOP(1) * FROM [UPCN_COM_PROD].dbo.FACTUS FS WHERE FC.SucCod = FS.SucCod AND FC.CliCod = FS.CliCod AND FC.SumNro = FS.SumNro AND
			FC.FrmCod = FS.FrmCod and FC.FactLet = FS.FactLet and FC.FactPtoV = FS.FactPtoV and FC.FactNro = FS.FactNro 
			ORDER BY FS.Fac1Srv
		) FS
		JOIN [UPCN_COM_PROD].dbo.FACTUI FI ON (FC.SucCod = FI.SucCod and FC.CliCod = FI.CliCod and FC.SumNro = FI.SumNro and FC.FrmCod = FI.FrmCod 
			and FC.FactLet = FI.FactLet and FC.FactPtoV = FI.FactPtoV and FC.FactNro = FI.FactNro)

	WHERE FC.SucCod = 1 AND FC.FrmCod IN (1,3,50) AND YEAR(FC.FactFec) >= YEAR(GETDATE())-1 /*AND FC.CliCod <> 1100*/ AND FC.FactPtoV in (0,12,13,14)
		and FC.Factquin <> 9 and FC.FactAnu <> 1  -- ¿Qué pasa con las anuladas por NC? ¿No estoy incluyendo la NC sin incluir la original?
		and FC.FactNro > 0
) X
GROUP BY Servicio, Area, Categoria, Tarifa,
	MesEmision, AñoEmision, FechaEmision, MesVto, AñoVto, Subtotal
	/*, RC.ResuImp*/


GO
