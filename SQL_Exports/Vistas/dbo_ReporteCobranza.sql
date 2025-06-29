/****** Object:  View [dbo].[ReporteCobranza]    Script Date: 23/06/2025 07:15:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO













/* COBRANZAS (Recaudacion Mensual) 
	22/10/2024: Usado en ReporteGlobal.pbix
	04/11/2024: Problema con desfasaje en procesamiento de transferencias. Ahora se toma como fecha la mayor fecha de cálculo 
		de interés de los comprobantes del REC de la transferencia, si existe; si no, se sigue tomando la del REC.
*/

/* DROP VIEW ReporteCobranza */
CREATE VIEW [dbo].[ReporteCobranza] AS
SELECT CAST('01/' + RIGHT('00' + CAST(MONTH(P2.Pa1Fec) AS VARCHAR), 2) + '/' + CAST(YEAR(P2.Pa1Fec) AS VARCHAR) AS DATE) AS Periodo, -- No usado en PowerBI
       CASE WHEN (P6.Pa6Ent = '9999') THEN 'cj. CHEQUE' 
		        WHEN (P6.Pa6Ent = 'EFEC') THEN 'cj. EFECTIVO' 
				WHEN (P6.Pa6Ent = '1036') THEN 'cj. DEBITO'
				WHEN (P6.Pa6Ent IN ('9850', '9851', '9852', '9853', '9854')) THEN 'z. TRANSFERENCIA'
				WHEN (P6.Pa6Ent = '9600' OR P6.Pa6Ent = '9650' OR P6.Pa6Ent = 'EPAN') THEN 'PREPAGO'
				WHEN (P6.Pa6Ent = '9750' OR P6.Pa6Ent = '9760' OR P6.Pa6Ent = '9761') THEN 'OFICINA VIRTUAL'
				WHEN (P6.Pa6Ent = '1040') THEN 'COMPENSACIÓN MUNICIPALIDAD (CAJAS)'
				WHEN (P6.Pa6Ent = '9060') THEN 'COMPENSACIÓN MUNICIALIDAD (LOTE)'
				WHEN (P6.Pa6Ent = '9000') THEN 'BCO. NACIÓN'
				WHEN (P6.Pa6Ent = '9001') THEN 'BCO. PCIA.'
				WHEN (P6.Pa6Ent = '9002') THEN 'BCO. CREDICOOP'
				WHEN (P6.Pa6Ent = '9007') THEN 'BCO. RÍO'
				WHEN (P6.Pa6Ent = '9100') THEN 'PAGO FACIL'
				WHEN (P6.Pa6Ent = '9200') THEN 'RIPSA'
				WHEN (P6.Pa6Ent = '9300') THEN 'BAPRO'
				WHEN (P6.Pa6Ent = '9400') THEN 'RED LINK'
				WHEN (P6.Pa6Ent = '9450') THEN 'BANELCO'
				WHEN (P6.Pa6Ent = '9500') THEN 'BCO. MACRO'
				WHEN (P6.Pa6Ent = '9700') THEN 'PRONTO PAGO'
				WHEN (P6.Pa6Ent = '9800') THEN 'COBROEXPRESS'
				WHEN (P6.Pa6Ent = '9900') THEN 'RAPIPAGO'
				WHEN (P6.Pa6Ent = '9950') THEN 'COOP. CRÉDITO'
				ELSE 'OTROS'
		   END AS Ente,
		   CASE WHEN (P6.Pa6Ent = '9999') OR (P6.Pa6Ent = 'EFEC') OR (P6.Pa6Ent = '1036') THEN 'CAJAS'
				WHEN (P6.Pa6Ent IN ('9850', '9851', '9852', '9853', '9854')) THEN 'z. TRANSFERENCIA'
				WHEN (P6.Pa6Ent = '9600' OR P6.Pa6Ent = '9650' OR P6.Pa6Ent = 'EPAN') THEN 'PREPAGO'
				WHEN (P6.Pa6Ent = '9750' OR P6.Pa6Ent = '9760' OR P6.Pa6Ent = '9761') THEN 'WEB'
				WHEN (P6.Pa6Ent = '1040') THEN 'MUNICIPALIDAD'
				WHEN (P6.Pa6Ent = '9060') THEN 'COMPENSACIÓN'
				WHEN (P6.Pa6Ent = '9400') OR (P6.Pa6Ent = '9450') THEN 'BANCA ELECTRÓNICA'
				WHEN (P6.Pa6Ent = '9100') THEN 'PAGO FACIL'
				WHEN (P6.Pa6Ent IN ('9000', '9001', '9002', '9007', '9200', '9300', '9400', '9450', '9500', '9700', '9800', '9900', '9950')) THEN 'COB.BANCOS'
				ELSE 'OTROS' 
		   END AS Grupo,
		   P6.Pa6Ent AS "Código Ente",
		   P6.Pa6Imp AS Importe,
		   CASE WHEN (P6.Pa6Ent IN ('9850', '9851', '9852', '9853', '9854'))
					AND P3.Pa3FecInt IS NOT NULL 
				THEN P3.Pa3FecInt 
				ELSE P2.Pa1Fec 
		   END AS Fecha,
		   P3.Pa3FecInt FechaCalculoInteres,
		   P2.Pa1Fec FechaRecibo,
		   P2.Pa1Cjr AS Cajero,
		   P2.Pa2Rec AS Recibo,
		   P6.Pa6Cta AS Cuenta,
		   P3.CantidadComprobantesCancelados
FROM UPCN_COM_PROD.dbo.PAGAD2 P2 
	JOIN UPCN_COM_PROD.dbo.PAGAD6 P6 ON (P2.SucCod = P6.SucCod AND P2.Pa1Fec = P6.Pa1Fec AND P2.Pa1Cjr = P6.Pa1Cjr AND P2.Pa2Rec = P6.Pa2Rec)
	LEFT JOIN (
		SELECT 
			P3.SucCod,
			P3.Pa1Fec,
			P3.Pa1Cjr,
			P3.Pa2Rec,
			MAX(P3.Pa3FecInt) AS Pa3FecInt,
			SUM(CASE WHEN P3.Pa3Tpo = 3 THEN 1 ELSE 0 END) AS CantidadComprobantesCancelados
		FROM UPCN_COM_PROD.dbo.PAGAD3 P3
		GROUP BY 
			P3.SucCod,
			P3.Pa1Fec,
			P3.Pa1Cjr,
			P3.Pa2Rec
	) P3 ON P2.SucCod = P3.SucCod 
		AND P2.Pa1Fec = P3.Pa1Fec 
		AND P2.Pa1Cjr = P3.Pa1Cjr 
		AND P2.Pa2Rec = P3.Pa2Rec
WHERE P2.SucCod = 1 AND P2.Pa1Fec > '01/01/2023'



GO
