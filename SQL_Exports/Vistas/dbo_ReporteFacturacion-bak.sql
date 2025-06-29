/****** Object:  View [dbo].[ReporteFacturacion-bak]    Script Date: 23/06/2025 07:15:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/* drop view ReporteFacturacion */
CREATE VIEW [dbo].[ReporteFacturacion-bak] AS
SELECT 
	FC.CliCod as Socio,
	FC.SumNro as Suministro,
	FC.FrmCod as TipoComprobante,
	CONCAT(FC.FrmCod, '-', FC.FactLet, '-', FC.FactPtoV, '-', FC.FactNro) as Comprobante,
	FC.FactFec Emision,
	CASE WHEN FC.FactVto1 = '01/01/1753' THEN '01/01/2000' ELSE FC.FactVto1 END Vencimiento,
	/*
	RR.FactFecCnc Cancelacion,
	CASE WHEN RR.FactFecCnc <> '01/01/1753' THEN 'S' ELSE 'N' END Cancelado,
	CASE WHEN DATEDIFF(MONTH, FC.FactVto1, RR.FactFecCnc) > 0 THEN DATEDIFF(MONTH, FC.FactVto1, RR.FactFecCnc) ELSE 0 END DemoraPago,
	CASE WHEN DATEDIFF(DAY, FC.FactVto1, RR.FactFecCnc) <= 0 THEN '1. AL DIA'
		WHEN DATEDIFF(DAY, FC.FactVto1, RR.FactFecCnc) < 15 THEN '2. HASTA 15 DIAS'
		WHEN DATEDIFF(DAY, FC.FactVto1, RR.FactFecCnc) < 30 THEN '3. HASTA 30 DIAS'
		WHEN DATEDIFF(DAY, FC.FactVto1, RR.FactFecCnc) < 60 THEN '4. HASTA 60 DIAS'
		WHEN DATEDIFF(DAY, FC.FactVto1, RR.FactFecCnc) >= 60 THEN '5. MAS DE 60 DIAS'
	END AS Grupos,
	*/
	SUBSTRING(CONVERT(VARCHAR(10), FC.FactVto1, 103),4,2) AS MesVto,
	SUBSTRING(CONVERT(VARCHAR(10), FC.FactVto1, 103),7,4) AS AñoVto,
	CASE WHEN FC.FrmCod IN (1,3) THEN RC.ResuImp ELSE -RC.ResuImp END AS ImporteFactura,
	--CASE WHEN FC.FrmCod IN (1,3) THEN RR.FactImpCnc ELSE -RR.FactImpCnc END AS ImporteCancelado
	FS.Fac1Are Area,
	FS.Fac1Ctg Categoria,
	FS.Fac1EttCod ETTCod
FROM [UPCN_COM_PROD].dbo.FACTUC FC
	OUTER APPLY (SELECT TOP(1) * FROM [UPCN_COM_PROD].dbo.RESUMC RC WHERE FC.SucCod = RC.SucCod 
						AND FC.CliCod = RC.CliCod AND FC.SumNro = RC.SumNro 
						AND FC.FactFec = RC.ResuFec AND FC.FrmCod = RC.ResuTpo AND FC.FactLet = RC.ResuLet AND FC.FactPtoV = RC.ResuPtoV AND FC.FactNro = RC.ResuNro
	) RC
	OUTER APPLY (SELECT TOP(1) * FROM [UPCN_COM_PROD].dbo.FACTUS FS WHERE FC.SucCod = FS.SucCod AND FC.CliCod = FS.CliCod AND FC.SumNro = FS.SumNro AND
		FC.FrmCod = FS.FrmCod and FC.FactLet = FS.FactLet and FC.FactPtoV = FS.FactPtoV and FC.FactNro = FS.FactNro 
		ORDER BY FS.Fac1Srv
	) FS

/*
	OUTER APPLY (SELECT FactFecCnc, FactImpCnc FROM UPCN_COM_PROD.dbo.FactMR RR WHERE FC.SucCod = RR.SucCod 
						AND FC.CliCod = RR.CliCod AND FC.SumNro = RR.SumNro 
						AND FC.FactFec = RR.FactFec AND FC.FrmCod = RR.FrmCod AND FC.FactLet = RR.FactLet AND FC.FactPtoV = RR.FactPtoV AND FC.FactNro = RR.FactNro
				) RR		
				*/
WHERE FC.SucCod = 1 AND FC.FrmCod IN (1,3,50) AND YEAR(FC.FactFec) >= YEAR(GETDATE())-1 /*AND FC.CliCod <> 1100*/ AND FC.FactPtoV in (0,12,13,14) /*and FC.Factquin <> 9 and FC.FactAnu <> 1*/ 
	and FC.FactNro > 0



GO
