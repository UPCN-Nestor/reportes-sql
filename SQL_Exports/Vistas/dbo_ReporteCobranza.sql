/****** Object:  View [dbo].[ReporteCobranza]    Script Date: 22/10/2024 09:37:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







/* COBRANZAS (Recaudacion Mensual) 
	22/10/2024: Usado en ReporteGlobal.pbix
*/

/* DROP VIEW ReporteCobranza */
CREATE VIEW [dbo].[ReporteCobranza] AS
SELECT CAST('01/' + RIGHT('00' + CAST(MONTH(P2.Pa1Fec) AS VARCHAR), 2) + '/' + CAST(YEAR(P2.Pa1Fec) AS VARCHAR) AS DATE) AS Periodo,
       CASE WHEN (P6.Pa6Ent = '9999') THEN 'cj. CHEQUE' 
		        WHEN (P6.Pa6Ent = 'EFEC') THEN 'cj. EFECTIVO' 
				WHEN (P6.Pa6Ent = '1036') THEN 'cj. DEBITO'
				WHEN (P6.Pa6Ent = '9001' OR P6.Pa6Ent = '9002' OR P6.Pa6Ent = '9852' OR P6.Pa6Ent = '9854') THEN 'z. TRANSFERENCIA'
				WHEN (P6.Pa6Ent = '9600' OR P6.Pa6Ent = '9650' OR P6.Pa6Ent = 'EPAN') THEN 'PREPAGO'
				WHEN (P6.Pa6Ent = '9750' OR P6.Pa6Ent = '9760' OR P6.Pa6Ent = '9761') THEN 'OFICINA VIRTUAL'
				WHEN (P6.Pa6Ent = '1040') THEN 'MUNICIPALIDAD'
				WHEN (P6.Pa6Ent = '9060') THEN 'COMPENSACIÓN'
				WHEN (P6.Pa6Ent = '9100') THEN 'PAGO FACIL'
				WHEN (P6.Pa6Ent = '9400') THEN 'RED LINK'
				WHEN (P6.Pa6Ent = '9300') THEN 'BAPRO'
				WHEN (P6.Pa6Ent = '9450') THEN 'BANELCO'
				WHEN (P6.Pa6Ent = '9200') THEN 'RIPSA'
				WHEN (P6.Pa6Ent = '9800') THEN 'COBROEXPRESS'
				WHEN (P6.Pa6Ent = '9900') THEN 'RAPIPAGO'
				WHEN (P6.Pa6Ent = '9001') THEN 'BCO. PCIA.'
				WHEN (P6.Pa6Ent = '9500') THEN 'BCO. MACRO'
				WHEN (P6.Pa6Ent = '9007') THEN 'BCO. RÍO'
				WHEN (P6.Pa6Ent = '9853') THEN 'BCO. RÍO TRANSF.'
				WHEN (P6.Pa6Ent = '9851') THEN 'BCO. PCIA. TRANSF.'
				WHEN (P6.Pa6Ent = '9700') THEN 'PRONTO PAGO'
				WHEN (P6.Pa6Ent = '9950') THEN 'COOP. CRÉDITO'
				WHEN (P6.Pa6Ent = '9000') THEN 'BCO. NACIÓN'
				ELSE 'OTROS'
		   END AS Ente,
		   CASE WHEN (P6.Pa6Ent = '9999') OR (P6.Pa6Ent = 'EFEC') OR (P6.Pa6Ent = '1036') THEN 'CAJAS'
				WHEN (P6.Pa6Ent = '9001' OR P6.Pa6Ent = '9002' OR P6.Pa6Ent = '9852' OR P6.Pa6Ent = '9854')  THEN 'z. TRANSFERENCIA'
				WHEN (P6.Pa6Ent = '9600' OR P6.Pa6Ent = '9650' OR P6.Pa6Ent = 'EPAN') THEN 'PREPAGO'
				WHEN (P6.Pa6Ent = '9750' OR P6.Pa6Ent = '9760' OR P6.Pa6Ent = '9761') THEN 'WEB'
				WHEN (P6.Pa6Ent = '1040') THEN 'MUNICIPALIDAD'
				WHEN (P6.Pa6Ent = '9060') THEN 'COMPENSACIÓN'
				WHEN (P6.Pa6Ent = '9400') OR (P6.Pa6Ent = '9450') THEN 'BANCA ELECTRÓNICA'
				WHEN (P6.Pa6Ent = '9300') OR (P6.Pa6Ent = '9200') OR (P6.Pa6Ent = '9800') OR (P6.Pa6Ent = '9900') OR (P6.Pa6Ent = '9100') OR (P6.Pa6Ent = '9001' OR P6.Pa6Ent = '9500' OR P6.Pa6Ent = '9007' OR P6.Pa6Ent = '9853' OR P6.Pa6Ent = '9851' 
						OR P6.Pa6Ent = '9700' OR P6.Pa6Ent = '9950' OR P6.Pa6Ent = '9000' 
				) THEN 'BANCO'
				ELSE 'OTROS' 
		   END AS Grupo,
		   P6.Pa6Ent AS "Código Ente",
		   P6.Pa6Imp AS Importe,
		   P2.Pa1Fec AS Fecha,
		   P2.Pa1Cjr AS Cajero,
		   P2.Pa2Rec AS Recibo,
		   P6.Pa6Cta AS Cuenta
FROM UPCN_COM_PROD.dbo.PAGAD2 P2 JOIN UPCN_COM_PROD.dbo.PAGAD6 P6 ON (P2.SucCod = P6.SucCod AND P2.Pa1Fec = P6.Pa1Fec AND P2.Pa1Cjr = P6.Pa1Cjr AND P2.Pa2Rec = P6.Pa2Rec)
WHERE P2.SucCod = 1 AND P2.Pa1Fec > '01/01/2019'



GO
