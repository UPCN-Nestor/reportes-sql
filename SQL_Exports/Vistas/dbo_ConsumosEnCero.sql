/****** Object:  View [dbo].[ConsumosEnCero]    Script Date: 23/06/2025 07:15:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW ConsumosEnCero AS
SELECT XX.*,
    C2.CnsKwAct UltLectura
FROM (SELECT Socio,
             Suministro,
             STRING_AGG(Medidor, ', ')                                                          Medidores,
             SUM(Consumo)                                                                       Consumo,
             CTA.SumNomPos                                                                      Nombre,
             CONCAT(TRIM(INM.InmCllDsc), ' ', INM.InmAlt , ' ', INM.InmPis, ' ', REPLACE(INM.InmDto, '"','')) Domicilio,
             MAX(FechaUltimaToma) FechaUltimaToma,
			 INM.InmLatitud Lat,
			 INM.InmLongitud Lon,
			 Area
      FROM (SELECT C.CliCod                             Socio,
                   C.SumNro                             Suministro,
                   CONCAT(CO.CnsTpoMdd, '-', CO.CnsMdd) Medidor,
                   SUM(CO.CnsKwCns)                     Consumo,
                   MAX(CnsFec)                          FechaUltimaToma,
				   C.Sum2Are Area				  
            FROM [UPCN_COM_PROD].dbo.CONSUM CO
                     JOIN [UPCN_COM_PROD].dbo.CONTRATO C
                          ON (CO.CnsSuc = C.SucCod AND CO.CliCod = C.CliCod AND CO.SumNro = C.SumNro AND
                              CO.CnsSrv = C.SrvCod)
            WHERE CO.CnsSuc = 1
              AND C.Sum2Sts IN (1, 2)
              AND C.CliCod <> 1100
              AND CO.CnsSrv = 1
              AND CO.CnsFec > '01/01/2024'
            GROUP BY C.CliCod, C.SumNro, CO.CnsTpoMdd, CO.CnsMdd, C.Sum2Are
            ) X
               JOIN [UPCN_COM_PROD].dbo.CUENTA CTA ON (X.Socio = CTA.CliCod AND X.Suministro = CTA.SumNro AND CTA.SucCod = 1)
               JOIN [UPCN_COM_PROD].dbo.INMUEBLE INM ON (CTA.SucCod = INM.SucCod AND CTA.InmCod = INM.InmCod)
      GROUP BY Socio, Suministro, CTA.SumNomPos, INM.InmCllDsc, INM.InmAlt, INM.InmPis, INM.InmDto, INM.InmLatitud, INM.InmLongitud, Area
      HAVING SUM(Consumo) < 20
    ) XX
    JOIN [UPCN_COM_PROD].dbo.CONSUM C2 ON (C2.CnsSuc = 1 AND C2.CnsSrv = 1 AND XX.Socio = C2.CliCod AND XX.Suministro = C2.SumNro AND XX.FechaUltimaToma = C2.CnsFec)



GO
