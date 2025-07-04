/****** Object:  View [dbo].[ReporteSueldos]    Script Date: 23/06/2025 07:15:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








/*
	22/10/2024: Usado en ReporteGlobal.pbix
*/

/* drop view ReporteSueldos */
create view [dbo].[ReporteSueldos] as
select LiqAno Año, LiqMes Mes, CONCAT('01/', RIGHT('00' + CAST(LiqMes as VARCHAR(2)), 2), '/', LiqAno) Fecha, 
	LiqLeg Legajo, 
	E1.EmpNom Nombre,
	CONCAT(E2.CafCod, ' | ', FR.ObrDsc) AS Frente,
	TL.TpoLiqDsc 'Tipo Liquidacion',
	Liq1Cnc Concepto,
	CONCAT(RIGHT(CONCAT('0000', Liq1Cnc), 4), ' | ', C.ConDsc) 'Descripción Concepto',
	Liq1Cal Importe,
	CONCAT(Liq1TpoCo, ' | ',
		CASE WHEN Liq1TpoCo = 1 THEN 'Remunerativo' ELSE
		CASE WHEN Liq1TpoCo = 2 THEN 'No remunerativo' ELSE
		CASE WHEN Liq1TpoCo = 3 THEN 'Salario familiar' ELSE
		CASE WHEN Liq1TpoCo = 4 THEN 'Retenciones' ELSE
		CASE WHEN Liq1TpoCo = 5 THEN 'Deducciones vs.' ELSE
		CASE WHEN Liq1TpoCo = 6 THEN 'Aportes' ELSE
		CASE WHEN Liq1TpoCo = 7 THEN 'Provisión' ELSE ''
		END END END END END END END		
	) 'Tipo Concepto',
	LiqConTD 'Transitorio o definitivo',
	CASE WHEN (L1.Liq1TpoCo < 3 OR L1.Liq1TpoCo = 6) AND L1.LiqConTD = 'D' THEN Liq1Cal 
		ELSE 0 END ImporteParaBruto,
	CASE WHEN L1.Liq1TpoCo < 3 AND L1.LiqConTD = 'D' THEN Liq1Cal 
		WHEN (L1.Liq1TpoCo = 4 OR L1.Liq1TpoCo = 5) AND L1.LiqConTD = 'D' THEN -Liq1Cal 
		ELSE 0 END ImporteParaNeto,
	CASE WHEN L1.LiqConTD = 'D' THEN Liq1Cal ELSE 0 END ImporteSoloDefinitivos,
	CASE WHEN L1.Liq1Cnc BETWEEN 6807 AND 6997 THEN Liq1Cal ELSE 0 END TotalOrdenesPago,
	CASE WHEN L1.Liq1Cnc BETWEEN 3000 AND 3019 AND L1.LiqConTD = 'D' THEN 'BAE'
		WHEN L1.Liq1Cnc BETWEEN 6790 AND 6799 AND L1.LiqConTD = 'D' THEN 'Imp. Ganancias'
		WHEN (L1.Liq1Cnc = 3500 OR L1.Liq1Cnc = 3510) AND L1.LiqConTD = 'D' THEN 'SAC'
		WHEN L1.Liq1Cnc = 2084 AND L1.LiqConTD = 'D' THEN 'Plus Vacacional'
		WHEN L1.Liq1Cnc BETWEEN 2006 AND 2046 AND L1.LiqConTD = 'D' THEN 'Hs. Extras' /***** REVISAR *****/
		WHEN (L1.Liq1Cnc = 4450 OR L1.Liq1Cnc = 4460) AND L1.LiqConTD = 'D' THEN 'Art. 9'
		WHEN (L1.Liq1Cnc = 130 OR L1.Liq1Cnc = 135) AND L1.LiqConTD = 'D' THEN 'Jubilados Luz/Gas'
		WHEN (L1.Liq1TpoCo = 6) THEN 'Aportes'		
		ELSE 'General'
	END GrupoDeInteres,
	(SELECT ConCta FROM [UPCN_RRHH_PROD].dbo.CONCEPLEVEL1 C1 
		WHERE L1.LiqSuc = C1.SucCod and C1.ConCod = L1.Liq1Cnc and C1.ConCodDC = 'C'
			AND C1.ConVig = '01/01/1753' AND C1.ConSS = E2.CafCod) AS CuentaCredito,
	(SELECT ConCta FROM [UPCN_RRHH_PROD].dbo.CONCEPLEVEL1 C2
		WHERE L1.LiqSuc = C2.SucCod and C2.ConCod = L1.Liq1Cnc and C2.ConCodDC = 'D'
			AND C2.ConVig = '01/01/1753' AND C2.ConSS = E2.CafCod) AS CuentaDebito,
	FIJOS.EmpCVal1 'Cpto val.fijo 1',
	FIJOS.EmpCVal2 'Cpto val.fijo 2',
	E2.CenCod CodCentroCosto,
	CTO.CctDsc CentroCosto
from [UPCN_RRHH_PROD].dbo.LIQUID1 L1
	join [UPCN_RRHH_PROD].dbo.EMPLE1 E1 ON (L1.LiqSuc = E1.SucCod AND L1.LiqLeg = E1.EmpLeg)
	join [UPCN_RRHH_PROD].dbo.EMPLE2 E2 ON (L1.LiqSuc = E2.SucCod AND L1.LiqLeg = E2.EmpLeg AND E2.EmpVig = '01/01/1753')
	join [UPCN_RRHH_PROD].dbo.CONCE21 C ON (L1.LiqSuc = C.SucCod and L1.Liq1Cnc = C.ConCod and C.ConVig = '01/01/1753')
	left join [UPCN_RRHH_PROD].dbo.FRENTE FR ON (E2.CafCod = FR.ObrCod)
	join [UPCN_RRHH_PROD].dbo.TIPLIQ TL ON (L1.LiqTpoLiq = TL.TpoLiqCod)
	outer apply ( 
		/* 05/07/2024: Pedido por Johanna y Gaby al presentar Planilla22 v1. 
		Lo armo así para asegurarme de no duplicar filas.
		ESTO VA A HABER QUE REHACERLO EN UN REPORTE QUE ARRANQUE DEL LEGAJO ("INFORME DE PERSONAL"), 
		ACÁ SE PIERDEN FILAS DE CONCEPTOS QUE TIENEN VALORES FIJOS PERO NO FUERON LIQUIDADOS (O AUN NO).
		*/
		select top(1) FL1.EmpCVal1, FL1.EmpCVal2
		from [UPCN_RRHH_PROD].[dbo].[FIJOSLEVEL1] FL1
		where SucCod = 1 and EmpVig = '01/01/1753' and EmpCCodVig = '01/01/1753' and EmpCVig = '01/01/1753'
			and FL1.EmpLeg = L1.LiqLeg and FL1.EmpCCod = L1.Liq1Cnc
	) FIJOS
	left join [UPCN_ERP_PROD].[dbo].[CTOCTO] CTO ON (E2.CenCod = CTO.CctCod)
where L1.LiqSuc = 1 --and LiqLeg < 5000 
	--and L1.Liq1Cnc in (100, 3800, 6798, 8995)
	and LiqTpoLiq in ('0', '4', '7', 'I', 'J')
	--and L1.LiqConTD = 'D'
	--and LiqAno >= 2023 --and LiqMes in (3,4)
	and (LiqAno >= 2020 and LiqAno < 2100) --!

	-- TEST
	--and LiqAno = 2023 and LiqMes = 6 and LiqLeg = 270

GO
