/****** Object:  View [dbo].[ReporteDeuda]    Script Date: 23/06/2025 07:15:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
	28/03/2025: Usado en ReporteGlobal
*/
/* DROP VIEW  [dbo].[ReporteDeuda] */
CREATE VIEW [dbo].[ReporteDeuda]
AS
SELECT CU.CliCod AS Socio, CU.SumNro AS Suministro, CU.SumNomPos AS Nombre, 
	CA.CtgEttCod,
	CASE WHEN CA.CtgEttCod IN ('SS') THEN 'SS'
		WHEN CA.CtgEttCod IN ('T1G', 'T1GCB', 'T1GE', 'T1GP') THEN 'T1G'
		WHEN CA.CtgEttCod IN ('T2BT', 'T2MT') THEN 'T2'
		WHEN CA.CtgEttCod IN ('T3BT', 'T3MT') THEN 'T3'
		WHEN CA.CtgEttCod IN ('T4', 'T4G') THEN 'T4'
		WHEN CA.CtgEttCod IN ('T1AP') THEN 'T1AP'
		WHEN CA.CtgEttCod IN ('T1R', 'T1RE', 'T1RG', 'T1RP', 'T1GBP', 'TSE') THEN 'T1R'
		WHEN CA.CtgEttCod IN ('TELEC') THEN 'TELEC'
		WHEN CA.CtgEttCod IN ('T5MT') THEN 'T5'
		ELSE 'OTROS' 
	END AS Tarifa, 		
	CO.Sum2Ctg, 
	IM.InmDom AS Domicilio, CO.Sum2Are, CO.Sum2Rut, 
	CASE WHEN CO.Sum2Sts IN (0, 1, 2, 3) THEN 'CONECTADO' ELSE 'DESCONECTADO' END AS Estado, 
	CASE WHEN CU.CliCod = 1100 THEN 'Municipalidad' ELSE 'Otros' END AS Municipalidad, 
	CS.CompTpo, CS.CompLet, CS.CompPtoV, CS.CompNro, CS.CompVto1,
	CASE WHEN CS.CompEnerSN = 'N' THEN 'No' ELSE 'Sí' END CompEnerSN, 
    CASE WHEN CS.CompTpo IN (1,3) THEN CS.CompImp ELSE -CS.CompImp END AS Saldo, 
	CASE WHEN CS.CompTpo IN (1,3) THEN CS.CompSdo ELSE -CS.CompSdo END AS Importe
FROM UPCN_COM_PROD.dbo.CUENTA AS CU 
	INNER JOIN UPCN_COM_PROD.dbo.INMUEBLE AS IM ON CU.SucCod = IM.SucCod AND CU.InmCod = IM.InmCod 
	OUTER APPLY (SELECT TOP(1) SucCod, Sum2Ctg, Sum2Sts, Sum2Are, Sum2Rut
		FROM UPCN_COM_PROD.dbo.CONTRATO CO
		WHERE CU.SucCod = CO.SucCod AND CU.CliCod = CO.CliCod
			AND CU.SumNro = CO.SumNro
		ORDER BY SrvCod ASC
	) CO
	INNER JOIN UPCN_COM_PROD.dbo.CATEGO AS CA ON CO.SucCod = CA.SucCod AND CO.Sum2Ctg = CA.CtgCod
	INNER JOIN UPCN_COM_PROD.dbo.COMSAL AS CS ON CU.SucCod = CS.SucCod AND CU.CliCod = CS.CliCod 
		AND CU.SumNro = CS.SumNro
WHERE (CU.CliCod <= 200000) AND (CS.CompVto1 BETWEEN DATEADD(YEAR, - 5, GETDATE()) AND GETDATE())




GO
