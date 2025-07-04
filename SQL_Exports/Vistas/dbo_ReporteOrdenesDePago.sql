/****** Object:  View [dbo].[ReporteOrdenesDePago]    Script Date: 23/06/2025 07:15:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* drop  view [dbo].[ReporteOrdenesDePago] */
Create view [dbo].[ReporteOrdenesDePago] as
SELECT OP2.OP2Fec Fecha, OP2.OP1Nro OrdenPago, Op2Prv CodProveedor, P.PrvNom Nombre, OP2Imp Importe
  FROM [UPCN_ERP_PROD].[dbo].[ORDPA2] OP2
	JOIN [UPCN_ERP_PROD].[dbo].[PROVE1] P ON (OP2.OP2Prv = P.PrvCod AND P.SucCod = 1)
  where YEAR(OP2Fec) >= YEAR(GETDATE())-1

GO
