/****** Object:  View [dbo].[vw_DemoraDePagoDespuesDeEnviarAvisosDeCorte]    Script Date: 23/06/2025 07:15:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
select * FROM vw_DemoraDePagoDespuesDeEnviarAvisosDeCorte
where Emision >= '24/10/2024'
order by Emision, Area, DiasDespuesDeAviso
*/


/* drop view vw_DemoraDePagoDespuesDeEnviarAvisosDeCorte; */
create view vw_DemoraDePagoDespuesDeEnviarAvisosDeCorte as

-- Tabla temporal con días del 1 al 30 para hacer el análisis por día
with dias as (
  select n as dia
  from (values (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),
              (11),(12),(13),(14),(15),(16),(17),(18),(19),(20),
              (21),(22),(23),(24),(25),(26),(27),(28),(29),(30)) as nums(n)
)
-- Consulta principal que muestra estadísticas de pagos por día después del aviso
select Emision, Vto, Area, Suministros, NULLIF(Comprobantes,0) as Comprobantes, DemoraPromedio, 
	CptesAvisadosAmbos, PagosAvisadosAmbos, CptesAvisadosEmail, PagosAvisadosEmail,
	CptesAvisadosSMS, PagosAvisadosSMS, CptesNoAvisados, PagosNoAvisados, CptesPagadosDespuesDeAvisoHastaDia,
	dia as DiasDespuesDeAviso,
	CASE WHEN Comprobantes > 0 THEN (100.0 * CptesPagadosDespuesDeAvisoHastaDia / Comprobantes) ELSE NULL END as PorcHastaDia,
	CASE WHEN CptesAvisadosAmbos > 0 THEN (100.0 * PagosAvisadosAmbos / CptesAvisadosAmbos) ELSE NULL END PorcAvisadosAmbos,
	CASE WHEN CptesAvisadosEmail > 0 THEN (100.0 * PagosAvisadosEmail / CptesAvisadosEmail) ELSE NULL END PorcAvisadosEmail,
	CASE WHEN CptesAvisadosSMS > 0 THEN (100.0 * PagosAvisadosSMS / CptesAvisadosSMS) ELSE NULL END PorcAvisadosSMS,
	CASE WHEN CptesNoAvisados > 0 THEN (100.0 * PagosNoAvisados / CptesNoAvisados) ELSE NULL END PorcNoAvisados
from
(
	-- Agrupación por fecha de emisión, vencimiento y área
	select CrtFecEmi Emision, CrtFecVtoAvi Vto, Area,
		COUNT(DISTINCT CONCAT(CliCod, '-', SumNro, '-', Crt1Tpo, '-', Crt1Let, '-', Crt1PtoV, '-', Crt1Nro)) Comprobantes,
		COUNT(DISTINCT CONCAT(CliCod, '-', SumNro)) Suministros,
		AVG(Demora) DemoraPromedio,
		d.dia,
		SUM(CASE WHEN Demora >= 0 AND Demora <= d.dia THEN 1 ELSE 0 END) CptesPagadosDespuesDeAvisoHastaDia,
		SUM(CASE WHEN CptesAvisadosAmbos > 0 THEN 1 ELSE 0 END) CptesAvisadosAmbos, 
		SUM(CASE WHEN CptesAvisadosEmail > 0 THEN 1 ELSE 0 END) CptesAvisadosEmail, 
		SUM(CASE WHEN CptesAvisadosSMS > 0 THEN 1 ELSE 0 END) CptesAvisadosSMS, 
		SUM(CASE WHEN CptesNoAvisados > 0 THEN 1 ELSE 0 END) CptesNoAvisados,
		SUM(CASE WHEN PagosAvisadosAmbos > 0 THEN 1 ELSE 0 END) PagosAvisadosAmbos, 
		SUM(CASE WHEN PagosAvisadosEmail > 0 THEN 1 ELSE 0 END) PagosAvisadosEmail, 
		SUM(CASE WHEN PagosAvisadosSMS > 0 THEN 1 ELSE 0 END) PagosAvisadosSMS, 
		SUM(CASE WHEN PagosNoAvisados > 0 THEN 1 ELSE 0 END) PagosNoAvisados
	from
	(
		-- Consulta base que obtiene datos de pagos y avisos
		select 
			C.CliCod, C.SumNro, C.Crt1Tpo, C.Crt1Let, C.Crt1PtoV, C.Crt1Nro, T.CrtFecEmi, P.Pa1Fec, 
				DATEDIFF(DAY, T.CrtFecEmi, P.Pa1Fec) Demora, COUNT(P.Pa1Fec) CantPagos,
				T.CrtFecVtoAvi, Area,
				SUM(CASE WHEN LEA.medio_aviso = 'Ambos' THEN 1 ELSE 0 END) CptesAvisadosAmbos,				
				SUM(CASE WHEN LEA.medio_aviso = 'SMS' THEN 1 ELSE 0 END) CptesAvisadosSMS,
				SUM(CASE WHEN LEA.medio_aviso = 'E-mail' THEN 1 ELSE 0 END) CptesAvisadosEmail,
				SUM(CASE WHEN LEA.medio_aviso = 'Ninguno' OR LEA.medio_aviso IS NULL THEN 1 ELSE 0 END) CptesNoAvisados,
				SUM(CASE WHEN P.SucCod = 1 AND LEA.medio_aviso = 'Ambos' THEN 1 ELSE 0 END) PagosAvisadosAmbos,
				SUM(CASE WHEN P.SucCod = 1 AND LEA.medio_aviso = 'SMS' THEN 1 ELSE 0 END) PagosAvisadosSMS,
				SUM(CASE WHEN P.SucCod = 1 AND LEA.medio_aviso = 'E-mail' THEN 1 ELSE 0 END) PagosAvisadosEmail,
				SUM(CASE WHEN P.SucCod = 1 AND (LEA.medio_aviso = 'Ninguno' OR LEA.medio_aviso IS NULL) THEN 1 ELSE 0 END) PagosNoAvisados
		from [UPCN_COM_PROD].[dbo].[TRCOR1] C
			outer apply (
				select top(1) * 
				from [UPCN_COM_PROD].[dbo].PAGAD3 P 
				where C.SucCod = P.SucCod and C.Crt1Tpo = P.Pa3Tpo
					and C.Crt1Let = P.Pa3Let and C.Crt1PtoV = P.Pa3PtoV and C.Crt1Nro = P.Pa3Nro
			) P
			join [UPCN_COM_PROD].dbo.TRCORT T ON (C.SucCod = T.SucCod and C.CrtFecLis = T.CrtFecLis and C.CliCod = T.CliCod and C.SumNro = T.SumNro)
			outer apply (
				select top(1) CO.Sum2Are Area
				from [UPCN_COM_PROD].[dbo].CONTRATO CO
				where C.SucCod = CO.SucCod and C.CliCod = CO.CliCod and C.SumNro = CO.SumNro and CO.SrvCod = 1
			) CO
			outer apply (
				select LEA.socio, LEA.suministro, 
			        CASE 
						WHEN MAX(CASE WHEN medio_aviso = 'Ambos' THEN 1 ELSE 0 END) = 1 THEN 'Ambos'
						WHEN MAX(CASE WHEN medio_aviso = 'E-mail' THEN 1 ELSE 0 END) = 1 
							 AND MAX(CASE WHEN medio_aviso = 'SMS' THEN 1 ELSE 0 END) = 1 THEN 'Ambos'
						WHEN MAX(CASE WHEN medio_aviso = 'E-mail' THEN 1 ELSE 0 END) = 1 THEN 'E-mail'
						WHEN MAX(CASE WHEN medio_aviso = 'SMS' THEN 1 ELSE 0 END) = 1 THEN 'SMS'
						ELSE 'Ninguno'
					END AS medio_aviso
				from [UPCN_SISTEMAS].dbo.log_envio_avisos LEA 
				where C.CliCod = LEA.socio and C.SumNro = LEA.suministro and real1_test0 = 1
					and LEA.fecha_referencia_aviso like '%' + FORMAT(T.CrtFecEmi, 'yyyy_MM_dd') + '%'
				group by LEA.socio, LEA.suministro
			) LEA
		where C.SucCod = 1
			and C.CrtFecLis >= '01/01/2023'
			and (T.CrtFecEmi <= P.Pa1Fec or P.Pa1Fec is null)			
			and T.CrtFecEmi != '01/01/1753' -- Excluye fechas nulas
			--and P.Pa1Fec != '01/01/1753' -- Excluye fechas nulas
		group by C.CliCod, C.SumNro, C.Crt1Tpo, C.Crt1Let, C.Crt1PtoV, C.Crt1Nro, T.CrtFecEmi, P.Pa1Fec, T.CrtFecVtoAvi, Area
	) x
	cross join dias d
	group by CrtFecEmi, CrtFecVtoAvi, Area, d.dia
) y

GO
