/****** Object:  View [dbo].[ReporteAvisosCorte]    Script Date: 23/06/2025 07:15:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/* drop view [dbo].[ReporteAvisosCorte] */
create view [dbo].[ReporteAvisosCorte] as
select 
	C.CliCod Socio,
	C.SumNro Suministro,
	C.Crt1Tpo CpteTipo,
	C.Crt1Let CpteLetra,
	C.Crt1PtoV CptePtoVta, 
	C.Crt1Nro CpteNumero,
	T.CrtNroAvi Protocolo,
	T.CrtAre Area,	
	T.CrtFecEmi as FechaEmision,
	T.CrtFecLis as FechaListado,
	T.CrtFecVtoAvi as FechaVencimiento,
	T.CrtFecRCrt as FechaRealCorte,
	P.Pa1Fec as FechaPago,
	DATEDIFF(DAY, T.CrtFecEmi, P.Pa1Fec) as DemoraPagoDias,
	-- Medio de aviso asignado según jerarquía
	CASE 
		WHEN MAX(CASE WHEN LEA.medio_aviso = 'Ambos' THEN 1 ELSE 0 END) = 1 THEN 'Ambos'
		WHEN MAX(CASE WHEN LEA.medio_aviso = 'E-mail' THEN 1 ELSE 0 END) = 1 
			 AND MAX(CASE WHEN LEA.medio_aviso = 'SMS' THEN 1 ELSE 0 END) = 1 THEN 'Ambos'
		WHEN MAX(CASE WHEN LEA.medio_aviso = 'E-mail' THEN 1 ELSE 0 END) = 1 THEN 'E-mail'
		WHEN MAX(CASE WHEN LEA.medio_aviso = 'SMS' THEN 1 ELSE 0 END) = 1 THEN 'SMS'
		ELSE 'Ninguno'
	END as MedioAviso,
	Tarifa
from [UPCN_COM_PROD].[dbo].[TRCOR1] C
	outer apply (
		select top(1) * 
		from [UPCN_COM_PROD].[dbo].PAGAD3 P 
		where C.SucCod = P.SucCod and C.Crt1Tpo = P.Pa3Tpo
			and C.Crt1Let = P.Pa3Let and C.Crt1PtoV = P.Pa3PtoV and C.Crt1Nro = P.Pa3Nro
	) P
	join [UPCN_COM_PROD].dbo.TRCORT T 
		on C.SucCod = T.SucCod and C.CrtFecLis = T.CrtFecLis and C.CliCod = T.CliCod and C.SumNro = T.SumNro
	outer apply (
		select socio, suministro, medio_aviso
		from [UPCN_SISTEMAS].dbo.log_envio_avisos
		where C.CliCod = socio and C.SumNro = suministro and real1_test0 = 1
			and fecha_referencia_aviso like '%' + FORMAT(T.CrtFecEmi, 'yyyy_MM_dd') + '%'
	) LEA
	outer apply (
		select top(1) FS.Fac1EttCod Tarifa
		from [UPCN_COM_PROD].dbo.FACTUS FS
		where FS.SucCod = 1 and C.CliCod = FS.CliCod and C.SumNro = FS.SumNro
		order by FS.Fac1Srv
	) FS
where C.SucCod = 1
	and C.CrtFecLis >= '2023-01-01'
	and (T.CrtFecEmi <= P.Pa1Fec or P.Pa1Fec is null)
	and T.CrtFecEmi != '1753-01-01'
	and T.CrtTpoSC = 'S'
	and C.CrtTpoSC = 'S'
-- Opcional: and P.Pa1Fec != '1753-01-01'
group by 
	C.CliCod, C.SumNro, C.Crt1Tpo, C.Crt1Let, C.Crt1PtoV, C.Crt1Nro,
	T.CrtFecEmi, P.Pa1Fec, T.CrtFecVtoAvi, T.CrtNroAvi, T.CrtAre, T.CrtFecLis, T.CrtFecRCrt, Tarifa

GO
