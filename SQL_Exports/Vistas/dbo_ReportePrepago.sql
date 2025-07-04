/****** Object:  View [dbo].[ReportePrepago]    Script Date: 23/06/2025 07:15:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Script for SelectTopNRows command from SSMS  ******/

CREATE VIEW ReportePrepago AS
SELECT c.fecha_creacion "Fecha Compra", 
	co.nombre Vendedor, 
	c.importe Importe,
	c.kw Kwh
FROM [UPCN_SISTEMAS_PREPAGO].[dbo].[compra] c
	JOIN [UPCN_SISTEMAS_PREPAGO].dbo.jhi_user u on (c.vendedor_id = u.id)
    JOIN [UPCN_SISTEMAS_PREPAGO].dbo.comerciante co on (co.id = u.comerciante_id)
WHERE c.estado_pago = 'Generado'

  --where fecha_creacion between '01/01/2023' and '01/02/2023' 
 

GO
