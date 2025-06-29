/****** Object:  UserDefinedFunction [dbo].[ReporteFacturacion]    Script Date: 23/06/2025 07:15:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* drop function ReporteFacturacion */
create function [dbo].[ReporteFacturacion]()
RETURNS table
AS

/*****************************************************************************************************************************/
-- CONSULTA PARA ESTADISTICAS DE FACTURACION - IMPORTES 
/*****************************************************************************************************************************/
-- RESUMEN por comprobante, con peridos de emsision, vto, importe, remesa y servicio principal
--		SE ANEXA analisis de EE: periodo de consumo, tarifas, Consumos, Base Eneregia, Fact.No EE asociada
--			AGRUPA LOS IMPORTES por: CF, Base EE, ICT
-- Ultima modificacion 25-04-2024
/*****************************************************************************************************************************/
RETURN
SELECT c.CliCod AS Socio, c.SumNro AS Sumini, p.CliApe AS Nombre
		, YEAR(c.FactFec) AS AnoEmi, MONTH(c.FactFec) AS MesEmi
		, YEAR(c.FactVto1) AS AnoVto, MONTH(c.FactVto1) AS MesVto
		, CAST(CONVERT(VARCHAR(11), c.FactFec, 113) AS date) AS Emision
		, c.FactRgAfip AS FcAfip, c.FactEnerSN AS FcEE
		, c.FactCls AS FcCls, c.FrmCod AS FcTpo, c.FactLet AS FcLet, c.FactPtoV AS FcPtoV, c.FactNro AS FcNro, c.Factquin AS FcOrd
		, CAST(CONVERT(VARCHAR(11), c.FactVto1, 113) AS date) AS FecVto
		, CASE WHEN rc.ResuTpo=50 THEN (-rc.ResuImp) ELSE rc.ResuImp END AS ImpFactura
		, c.FactRem AS Remesa
		, CASE WHEN c.FactRem BETWEEN 21 AND 999 THEN 'EE'
			WHEN c.FactRem BETWEEN 5000 AND 5999  THEN 'SS'
			WHEN c.FactRem = 6101  THEN 'TEL'
			WHEN c.FactRem = 99999 THEN 'INT'
			ELSE 'OTRO' END AS SerPrin
		, c.FactLot AS LoteNro, s2.Fac1Are AS Area, s2.Fac1Rut AS Ruta
-- Fin datos del comprobante sin apertura por servicios-items .
		, s2.AnoCns, s2.MesCns
		, s2.Fac1CtgCon AS CatUPC
		, s2.Fac1EttCod AS TarOceba
		, s2.Fac1EttImp AS TarRango
		, s2.Fac1Ctg AS CatUPCSeg
		, s2.SEGMENTO AS Segmento
-- datos de la factura EE 
		, s2.UltLista -- lista utilizada, la ultima si  hay mas de una
		, s2.ImS1Cod AS FCSubTotCod, s2.ImS1Dsc AS FCSubTotDesc  -- subtotales en la impresion de la factura
		, s2.Consumo
		, CFSubtot AS ImpCF  -- Cargo Fijo
		, s2.ICT
		, s2.BaseEE AS ImpBaseEE  -- Importe del subtotal EE que es la base para los impuestos
-- datos de la factura No EE asociada a la EE 
		, s2.FactEneElec AS ImpTotFc-- Total Fact EE
		, s2.FactNoElec  AS ImpCCap-- Total Fact No Electrica
		, s2.Tot2Fact    AS ImpTotEEyCCap -- Total ambas facturas

-- Datos extras de la factura para control interno
		, s2.FrmNE AS FcCCtipo, s2.LetNE AS FcCClet, s2.PtoVNE AS FcCCptoV, s2.FactNroNE AS FcCCnro
		, CFCant AS CantItemCF
		, s2.Cantitems AS CantItemBaseEE
		, c.FactAnu -- Campos de anulacion de FC Factquin=9 win y FacAnu=1 Web
		, c.FactObs -- Campo en NC que anula Fact indica la factura de referencia
		, s2.Fac1MarEs, s2.Fac1MarLis

FROM 
	[UPCN_COM_PROD].dbo.FACTUC c WITH(NOLOCK) 
	JOIN [UPCN_COM_PROD].dbo.RESUMC rc WITH(NOLOCK) ON (c.SucCod=rc.SucCod AND c.CliCod=rc.CliCod AND c.SumNro=rc.SumNro AND c.FactFec=rc.ResuFec AND c.FrmCod=rc.ResuTpo AND c.FactLet=rc.ResuLet AND c.FactPtoV=rc.ResuPtoV AND c.FactNro=rc.ResuNro) 
	JOIN [UPCN_COM_PROD].dbo.PERSONA p WITH(NOLOCK) ON (c.SucCod=p.SucCod AND c.CliCod=p.CliCod) 

	LEFT JOIN ( -- DATOS-EE, tarifa, consumos, importes
-- SUBCONSULTA DE ANALISIS DE EE
		SELECT s.SucCod, s.Fac1Srv, s.CliCod, s.SumNro, s.FactFec, s.FrmCod, s.FactLet, s.FactPtoV, s.FactNro
			, s.Fac1AnoCns AS AnoCns, s.Fac1MesCns AS MesCns
			, s.Fac1Are, s.Fac1Rut, s.Fac1EttImp --, s.Fac1EttImpDec
				-- datos de la factura EE 
			, t.UltLista, st.ImS1Cod , st.ImS1Dsc
			, m.Consumo, st.Subtotal AS BaseEE, st.Cantitems
			, s.Fac1CtgCon, s.Fac1EttCod, s.Fac1Ctg
			, CASE WHEN s.Fac1Ctg IN (12, 16, 22, 28, 32, 36, 52, 56, 62) THEN 'NIVEL-2'
					WHEN s.Fac1Ctg IN (13,17,23,29,33,35,37,39,43,45,47,53,55,57,59,63,67,73,83,93,97,113) THEN 'NIVEL-3'
				ELSE 'NIVEL-1' END AS SEGMENTO
	-- datos de la factura No EE asociada a la EE 
			, CASE WHEN e.FrmCod=50 THEN (e.Fac7EneImp * -1) ELSE e.Fac7EneImp END AS FactEneElec -- Total Fact EE
			, CASE WHEN e.FrmCod=50 THEN (e.Fac7NoEImp * -1) ELSE e.Fac7NoEImp END AS FactNoElec  -- Total Fact No Electrica
			, CASE WHEN e.FrmCod=50 THEN (e.Fac7EneTot * -1) ELSE e.Fac7EneTot END AS Tot2Fact    -- Total ambas facturas
			, c2.UnaFac
			, CFCant, CFSubtot
			, it.ICT
			, e.FrmCod AS FrmNE, e.FactLet AS LetNE, e.FactPtoV AS PtoVNE, e.FactNro AS FactNroNE
			, e.Fac7NoEImp, e.Fac7EneImp, e.Fac7EneTot, e.Fac7EneSdo
			, s.Fac1MarEs, s.Fac1MarLis
		
			FROM [UPCN_COM_PROD].dbo.FACTUS s
				LEFT JOIN (-- consulta que agrupa por consumos por comprobante aunque haya 2 medidores
					SELECT m.SucCod, m.CliCod, m.SumNro, m.FactFec, m.FrmCod, m.FactLet, m.FactPtoV, m.FactNro, m.Fac1Srv
							, SUM(CASE WHEN m.FrmCod=50 THEN ((m.Fac1Cns+m.Fac1CnsP+m.Fac1CnsFP+m.Fac1CnsV)*m.Fac1Mlt)*-1
									ELSE ((m.Fac1Cns+m.Fac1CnsP+m.Fac1CnsFP+m.Fac1CnsV)*m.Fac1Mlt) END) AS Consumo
							FROM [UPCN_COM_PROD].dbo.FACTUM m WITH(NOLOCK)  -- CONSUMOS
						GROUP BY m.SucCod, m.CliCod, m.SumNro, m.FactFec, m.FrmCod, m.FactLet, m.FactPtoV, m.FactNro, m.Fac1Srv
					) m ON  (s.SucCod=m.SucCod AND s.CliCod=m.CliCod AND s.SumNro=m.SumNro AND s.FactFec=m.FactFec AND s.FrmCod=m.FrmCod AND s.FactLet=m.FactLet AND s.FactPtoV=m.FactPtoV AND s.FactNro=m.FactNro AND s.Fac1Srv=m.Fac1Srv) 

				LEFT JOIN (-- consulta que busca la ultima lista aplicada - no importa la cantidad de dias)
					SELECT t.SucCod, t.CliCod, t.SumNro, t.FactFec, t.FrmCod, t.FactLet, t.FactPtoV, t.FactNro, t.Fac1Srv, MAX(t.Fac5LstCod) AS UltLista
							FROM [UPCN_COM_PROD].dbo.FACTUT t WITH(NOLOCK)  -- CONSUMOS
						GROUP BY t.SucCod, t.CliCod, t.SumNro, t.FactFec, t.FrmCod, t.FactLet, t.FactPtoV, t.FactNro, t.Fac1Srv
					) t ON  (s.SucCod=t.SucCod AND s.CliCod=t.CliCod AND s.SumNro=t.SumNro AND s.FactFec=t.FactFec AND s.FrmCod=t.FrmCod AND s.FactLet=t.FactLet AND s.FactPtoV=t.FactPtoV AND s.FactNro=t.FactNro AND s.Fac1Srv=t.Fac1Srv) 

				LEFT JOIN ( -- consulta que agrupa por Subtotales de impresion 
					SELECT i.SucCod, i.CliCod, i.SumNro, i.FactFec, i.FrmCod, i.FactLet, i.FactPtoV, i.FactNro, s2.ImS1Cod, s1.ImS1Dsc
							, CASE WHEN i.FrmCod=50 THEN SUM(Fac2Imp1)*-1
									ELSE SUM(Fac2Imp1) END AS Subtotal
							, COUNT(*) AS Cantitems
						FROM [UPCN_COM_PROD].dbo.FACTUI i WITH(NOLOCK)  -- IMPORTES ITEMS
							JOIN [UPCN_COM_PROD].dbo.IMPSU2 S2 ON (i.SucCod=s2.ImS1Suc AND i.Fac2Cnp=s2.ImS2Cnp) -- Concepto <-> tabla subtotales
							JOIN [UPCN_COM_PROD].dbo.IMPSU1 S1 ON (s2.ImS1Suc=s1.ImS1Suc AND s2.ImS1Cod=s1.ImS1Cod AND s1.ImS1Cod=1) -- Tabla Subtotales 
			--	WHERE i.SucCod=1 AND i.CliCod=53935 AND i.FactFec>='20231101'
						GROUP BY SucCod, CliCod, SumNro, FactFec, FrmCod, FactLet, FactPtoV, FactNro, s2.ImS1Cod, s1.ImS1Dsc
					) st ON (s.SucCod=st.SucCod AND s.CliCod=st.CliCod AND s.SumNro=st.SumNro AND s.FactFec=st.FactFec AND s.FrmCod=st.FrmCod AND s.FactLet=st.FactLet AND s.FactPtoV=st.FactPtoV AND s.FactNro=st.FactNro) 


				LEFT JOIN ( -- consulta para CF cant y $
					SELECT i.SucCod, i.CliCod, i.SumNro, i.FactFec, i.FrmCod, i.FactLet, i.FactPtoV, i.FactNro
							, CASE WHEN i.FrmCod=50 THEN SUM(i.Fac2Imp1)*-1
									ELSE SUM(i.Fac2Imp1) END AS CFSubtot
							, COUNT(*) AS CFCant
						FROM [UPCN_COM_PROD].dbo.FACTUI i WITH(NOLOCK)
							WHERE i.Fac1Srv=1
							AND i.Fac2Itm IN (1021,1051,1121,1141,1201,1501,1901,2100,3100,4100,5100,5500) -- items de cargo fijo
							-- AND i.Fac2Cnp IN (12,14,62) -- conceptos de item de CF NO sirve para esta consulta varian los datos
						GROUP BY i.SucCod, i.CliCod, i.SumNro, i.FactFec, i.FrmCod, i.FactLet, i.FactPtoV, i.FactNro
					) cf ON (s.SucCod=cf.SucCod AND s.CliCod=cf.CliCod AND s.SumNro=cf.SumNro AND s.FactFec=cf.FactFec AND s.FrmCod=cf.FrmCod AND s.FactLet=cf.FactLet AND s.FactPtoV=cf.FactPtoV AND s.FactNro=cf.FactNro) 

				LEFT JOIN ( -- consulta obtener ICT
					SELECT i.SucCod, i.CliCod, i.SumNro, i.FactFec, i.FrmCod, i.FactLet, i.FactPtoV, i.FactNro
							, CASE WHEN i.FrmCod=50 THEN SUM(i.Fac2Imp1)*-1	ELSE SUM(i.Fac2Imp1) END AS ICT
						FROM [UPCN_COM_PROD].dbo.FACTUI i WITH(NOLOCK)
							WHERE i.Fac1Srv=1
							AND i.Fac2Itm BETWEEN 2007 AND 2014 -- items ICT 2011-2014 Sub-ICT 
							-- AND i.Fac2Cnp IN (12,14,62) -- conceptos de item de CF NO sirve para esta consulta varian los datos
						GROUP BY i.SucCod, i.CliCod, i.SumNro, i.FactFec, i.FrmCod, i.FactLet, i.FactPtoV, i.FactNro
					) it ON (s.SucCod=it.SucCod AND s.CliCod=it.CliCod AND s.SumNro=it.SumNro AND s.FactFec=it.FactFec AND s.FrmCod=it.FrmCod AND s.FactLet=it.FactLet AND s.FactPtoV=it.FactPtoV AND s.FactNro=it.FactNro) 

			JOIN (  -- consulta para contar las facturas
				SELECT c.SucCod, c.CliCod, c.SumNro, c.FactFec, c.FrmCod, c.FactLet, c.FactPtoV, c.FactNro, 1 AS UnaFac
					FROM [UPCN_COM_PROD].dbo.FACTUC c WITH(NOLOCK) 
				) c2 ON (s.SucCod=c2.SucCod AND s.CliCod=c2.CliCod AND s.SumNro=c2.SumNro AND s.FactFec=c2.FactFec AND s.FrmCod=c2.FrmCod AND s.FactLet=c2.FactLet AND s.FactPtoV=c2.FactPtoV AND s.FactNro=c2.FactNro) 

				LEFT JOIN [UPCN_COM_PROD].dbo.FACTUE e WITH(NOLOCK) ON (e.SucCod=s.SucCod AND e.CliCod=s.CliCod AND e.SumNro=s.SumNro AND e.FactFec=s.FactFec 
												AND e.Fac7EneFrm=s.FrmCod AND e.Fac7EneLet=s.FactLet AND e.Fac7EnePto=s.FactPtoV AND e.Fac7EneNro=s.FactNro AND s.Fac1Srv=1)

			WHERE s.SucCod=1 AND s.Fac1Srv=1 
--		AND s.CliCod=53935 AND s.FactFec >='20240101'

		) s2 ON (c.SucCod=s2.SucCod AND c.CliCod=s2.CliCod AND c.SumNro=s2.SumNro AND c.FactFec=s2.FactFec AND c.FrmCod=s2.FrmCod AND c.FactLet=s2.FactLet AND c.FactPtoV=s2.FactPtoV AND c.FactNro=s2.FactNro) 
		-- FIN DATOS-EE
-- FIN SUBCONSULTA DE ANALISIS DE EE

	WHERE c.SucCod=1 
			AND (c.Factquin<>9 AND c.FactAnu=0 AND c.FactObs=' ') -- Excluye las FC anuladas y las NC que anulan facturas
			AND c.FactFec >=  '01/' + RIGHT('00' + CAST(MONTH(GETDATE()) as varchar), 2) +'/'+ CAST((YEAR(GETDATE())-2) as varchar)

/*****************************************************************************************************************************/
/*****************************************************************************************************************************/








GO
