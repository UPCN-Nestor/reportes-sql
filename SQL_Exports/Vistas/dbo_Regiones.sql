/****** Object:  View [dbo].[Regiones]    Script Date: 23/06/2025 07:15:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/*
	28/03/2025: Usado en ReporteGlobal
*/
/* DROP VIEW  [dbo].[Regiones] */
create view [dbo].[Regiones] 
as
with Areas as (select AreCod from [UPCN_COM_PROD].dbo.[AREA] where SucCod = 1)
select
	Areas.AreCod,
	CASE 
        WHEN AreCod IN (1018, 1020, 1026) THEN 'Quequén'
        WHEN AreCod IN (3036, 3037, 3040) THEN 'Grandes'
        WHEN AreCod IN (1028, 1030) THEN 'Rural y Suburbano'
        WHEN AreCod IN (5510, 5520, 5550, 5580) THEN 'Servicios Sociales'
        WHEN AreCod = 6610 THEN 'Telecomunicaciones'
        WHEN AreCod = 3039 THEN 'Peaje (T5)'
        ELSE 'Necochea'
    END AS Region
FROM Areas

GO
