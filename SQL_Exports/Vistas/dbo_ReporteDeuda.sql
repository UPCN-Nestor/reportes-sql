/****** Object:  View [dbo].[ReporteDeuda]    Script Date: 21/03/2025 07:15:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.ReporteDeuda
AS
SELECT        CU.CliCod AS Socio, CU.SumNro AS Suministro, CU.SumNomPos AS Nombre, CA.CtgEttCod AS Tarifa, CO.Sum2Ctg, IM.InmDom AS Domicilio, CO.Sum2Are, CO.Sum2Rut, CASE WHEN CO.Sum2Sts IN (0, 1, 2, 3) 
                         THEN 'CONECTADO' ELSE 'DESCONECTADO' END AS Estado, CS.CompTpo, CS.CompLet, CS.CompPtoV, CS.CompNro, CS.CompVto1, CS.CompEnerSN, CS.CompImp AS Saldo, CS.CompSdo AS Importe
FROM            UPCN_COM_PROD.dbo.CUENTA AS CU INNER JOIN
                         UPCN_COM_PROD.dbo.INMUEBLE AS IM ON CU.SucCod = IM.SucCod AND CU.InmCod = IM.InmCod INNER JOIN
                         UPCN_COM_PROD.dbo.CONTRATO AS CO ON CU.SucCod = CO.SucCod AND CU.CliCod = CO.CliCod AND CU.SumNro = CO.SumNro AND CO.SrvCod = 1 INNER JOIN
                         UPCN_COM_PROD.dbo.CATEGO AS CA ON CO.SucCod = CA.SucCod AND CO.Sum2Ctg = CA.CtgCod INNER JOIN
                         UPCN_COM_PROD.dbo.COMSAL AS CS ON CU.SucCod = CS.SucCod AND CU.CliCod = CS.CliCod AND CU.SumNro = CS.SumNro

GO
