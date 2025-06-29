/****** Object:  View [dbo].[TelecomunicacionesNAP]    Script Date: 23/06/2025 07:15:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* DROP VIEW TelecomunicacionesNAP */
CREATE VIEW 
	TelecomunicacionesNAP
AS
SELECT
    CO.CliCod Socio
    ,CO.SumNro Suministro
	,P.CliApe Nombre
	,CONCAT(TRIM(I.InmCllDsc), ' ', I.InmAlt) Domicilio
    , CASE WHEN TRIM(Sum2Port) = 'SI' OR Sum2Port = '' OR Sum2Port IS NULL THEN 'Sin datos' ELSE Sum2Port END NAP
	,CO.Sum2Sts
FROM [UPCN_COM_PROD].dbo.CONTRATO CO	
	JOIN [UPCN_COM_PROD].dbo.PERSONA P ON (CO.SucCod = P.SucCod AND CO.CliCod = P.CliCod)
	JOIN [UPCN_COM_PROD].dbo.CUENTA C ON (CO.SucCod = C.SucCod AND CO.CliCod = C.CliCod AND CO.SumNro = C.SumNro)
	JOIN [UPCN_COM_PROD].dbo.INMUEBLE I ON (C.InmCod = I.InmCod)
	OUTER APPLY (
		SELECT TOP(1) FC.FactNro 
		FROM [UPCN_COM_PROD].dbo.FACTUC FC 
		WHERE FC.SucCod = CO.SucCod AND FC.CliCod = CO.CliCod AND FC.SumNro = CO.SumNro 
			AND FC.FactFec > DATEADD(MONTH, -2, GETDATE())
	) F
WHERE CO.SucCod = 1 and CO.SrvCod = 5 and Sum2Sts < 4
	AND F.FactNro IS NOT NULL
GO
