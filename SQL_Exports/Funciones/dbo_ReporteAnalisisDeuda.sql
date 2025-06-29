/****** Object:  UserDefinedFunction [dbo].[ReporteAnalisisDeuda]    Script Date: 23/06/2025 07:15:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/*
	22/10/2024: Usado en ReporteGlobal.pbix
*/

/* drop function ReporteAnalisisDeuda */

CREATE function [dbo].[ReporteAnalisisDeuda](
	@año_desde int,
	@año_hasta int,
	@con_municipalidad int
)
RETURNS TABLE AS
RETURN

SELECT RESU.*, FS.*,
	CASE WHEN Grupos = '6. IMPAGO O SIN CONCILIAR' THEN 
		ImporteComprobante - COALESCE(SUM(ImporteCancelado) OVER (PARTITION BY CpteTipo, CpteLetra, CptePtoVta, CpteNumero), 0)
	ELSE
		ImporteCancelado
	END ImporteParaAgrupar
FROM
(
	SELECT YEAR(B.ResuVto1) * 100 +  MONTH(B.ResuVto1) AS Periodo,  
		CASE WHEN Marca='P' THEN 0 ELSE
			CASE WHEN B.ResuTpo IN (1,3) THEN B.ResuImp ELSE B.ResuImp * -1 END  
		END AS ImporteComprobante,
		CASE WHEN B.ResuTpo IN (1,3) THEN COALESCE(B.ResuImpCnc,0) ELSE COALESCE(B.ResuImpCnc,0) * -1 END AS ImporteCancelado,
		CASE 
--			WHEN B.Marca = 'I' AND B.ResuFecCnc IS NULL AND B.ResuImpCnc = 0 THEN '6. IMPAGO O SIN CONCILIAR'
			WHEN B.Marca = 'I' AND B.Pa3FecInt IS NULL AND B.ResuImpCnc = 0 THEN '6. IMPAGO O SIN CONCILIAR'
			WHEN DATEDIFF(DAY, B.ResuVto1, B.Pa3FecInt) <= 0 THEN '1. AL DIA'
			WHEN DATEDIFF(DAY, B.ResuVto1, B.Pa3FecInt) < 15 THEN '2. HASTA 15 DIAS'
			WHEN DATEDIFF(DAY, B.ResuVto1, B.Pa3FecInt) < 30 THEN '3. HASTA 30 DIAS'
			WHEN DATEDIFF(DAY, B.ResuVto1, B.Pa3FecInt) < 60 THEN '4. HASTA 60 DIAS'
			WHEN DATEDIFF(DAY, B.ResuVto1, B.Pa3FecInt) >= 60 THEN '5. MAS DE 60 DIAS'
		END AS Grupos,
		DATEDIFF(DAY, B.ResuVto1, B.Pa3FecInt) DiasVencido,
		B.CliCod Socio, B.SumNro Suministro, B.ResuFec Emision, B.ResuVto1 Vencimiento, B.Pa3FecInt Cancelacion,
		ResuTpo CpteTipo, ResuLet CpteLetra, ResuPtoV CptePtoVta, ResuNro CpteNumero, B.ResuEnerSN
	FROM (
		SELECT RC.ResuVto1, RC.SucCod, RC.CliCod, RC.SumNro, RC.ResuFec, RC.ResuTpo, RC.ResuLet, RC.ResuPtoV, RC.ResuNro,
			RC.ResuImp, RR.ResuImpCnc, RR.ResuFecCnc, RR.ResuTpoCnc, 'P' Marca, RR.Pa3FecInt, RC.ResuEnerSN
		FROM UPCN_COM_PROD.dbo.RESUMC RC WITH(NOLOCK) 
			JOIN (SELECT RR.SucCod, CliCod, SumNro, ResuFec, ResuTpo, ResuLet, ResuPtoV, ResuNro, ResuImpCnc, ResuFecCnc, ResuTpoCnc, COALESCE(Pa3FecInt, ResuFecCnc) Pa3FecInt
					FROM UPCN_COM_PROD.dbo.RESUMR RR WITH(NOLOCK)		
						LEFT JOIN UPCN_COM_PROD.dbo.PAGAD3 P3 WITH(NOLOCK) ON (RR.SucCod=P3.SucCod AND RR.CliCod=P3.Pa3Cli AND RR.SumNro=P3.Pa3Sum AND P3.Pa3Fec = RR.ResuFec AND P3.Pa3Tpo = RR.ResuTpo AND P3.Pa3Let = RR.ResuLet AND P3.Pa3PtoV = RR.ResuPtoV AND P3.Pa3Nro = RR.ResuNro AND P3.Pa2Rec=RR.ResuCptCnc )	
			   		) RR ON (RC.SucCod = RR.SucCod AND RC.CliCod = RR.CliCod AND RC.SumNro = RR.SumNro AND RC.ResuFec = RR.ResuFec AND
					RC.ResuTpo = RR.ResuTpo AND RC.ResuLet = RR.ResuLet AND RC.ResuPtoV = RR.ResuPtoV AND RC.ResuNro = RR.ResuNro)
	
		WHERE RC.SucCod = 1 AND RC.ResuTpo IN (1,3/*,50*/) -- Se excluyen NCs porque provocan valores mensuales de cobranza negativos.
			AND (RR.ResuTpoCnc = 60 OR RR.ResuTpoCnc = 70) AND RC.ResuVto1 BETWEEN '01/01/' + CAST(@año_desde as varchar) AND '31/12/' + CAST(@año_hasta as varchar) AND RC.CliCod <> 1100	
--AND RC.CliCod = 5082 AND RC.SumNro = 8
		   
		UNION
		SELECT RC.ResuVto1, RC.SucCod, RC.CliCod, RC.SumNro, RC.ResuFec, RC.ResuTpo, RC.ResuLet, RC.ResuPtoV, RC.ResuNro,
			RC.ResuImp/* - RC.ResuImp2 AS ResuImp*/, 0, null, null, 'I' Marca, null, null
		FROM UPCN_COM_PROD.dbo.RESUMC RC
			JOIN UPCN_COM_PROD.dbo.FACTUC FC ON (FC.SucCod = RC.SucCod AND FC.CliCod = RC.CliCod AND FC.SumNro = RC.SumNro 
					AND FC.FactFec = RC.ResuFec AND FC.FrmCod = RC.ResuTpo AND FC.FactLet = RC.ResuLet AND FC.FactPtoV = RC.ResuPtoV AND FC.FactNro = RC.ResuNro)
		WHERE RC.SucCod = 1 AND RC.ResuTpo IN (1,3/*,50*/) AND RC.ResuVto1 >= '01/01/' + CAST(@año_desde as varchar) 
			/*AND '31/12/' + CAST(@año_hasta as varchar) */
			AND (RC.CliCod <> 1100 OR @con_municipalidad = 1) 
			AND FC.FactAnu <> 1
--AND RC.CliCod = 5082 AND RC.SumNro = 8
		) AS B
) RESU
OUTER APPLY (
	SELECT TOP(1) FS.Fac1Srv ServicioPrincipal, FS.Fac1Ctg Categoria, FS.Fac1EttCod Tarifa, FS.Fac1EttImpDec TarifaConEscalon, FS.Fac1Are Area
	FROM UPCN_COM_PROD.dbo.FACTUS FS
	WHERE FS.SucCod = 1 AND FS.CliCod = RESU.Socio AND FS.SumNro = RESU.Suministro AND FS.FrmCod = RESU.CpteTipo AND FS.FactLet = RESU.CpteLetra AND FS.FactPtoV = RESU.CptePtoVta AND FS.FactNro = RESU.CpteNumero
	ORDER BY FS.Fac1Srv
) FS


--select * from ReporteAnalisisDeuda(2023,2023,0) where Grupos like '6%' order by ImporteParaAgrupar desc

GO
