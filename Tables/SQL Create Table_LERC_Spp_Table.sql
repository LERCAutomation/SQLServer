USE NBNData
GO

/*---------------------------------------------------------------------------*\
	Create LERC_Spp table
\*---------------------------------------------------------------------------*/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[LERC_Spp_Table]') AND type in (N'U'))
	DROP TABLE [dbo].[LERC_Spp_Table]
GO

CREATE TABLE [dbo].[LERC_Spp_Table](

	[TaxonName] [varchar](75) NULL,
	[CommonName] [varchar](75) NULL,
	[TaxonRank] [varchar](20) NULL,
	[TaxonGroup] [varchar](60) NULL,
	[TaxonClass] [varchar](75) NULL,
	[TaxonOrder] [varchar](75) NULL,
	[TaxonFamily] [varchar](75) NULL,
	[SortOrder] [varchar](36) NULL,
	[GroupOrder] [int] NULL,

	[Abundance] [varchar](150) NULL,
	[AbundanceCount] [int] NULL,

	[RecDate] [varchar](40) NULL,
	[RecYear] [int] NULL,
	[RecMonthStart] [int] NULL,
	[RecMonthEnd] [int] NULL,
	[VagueDateStart] [int] NULL,
	[VagueDateEnd] [int] NULL,
	[VagueDateType] [varchar](2) NULL,

	[Recorder] [varchar](60) NULL,
	[Determiner] [varchar](60) NULL,

	[GridRef] [varchar](12) NULL,
	[RefSystem] [varchar](4) NULL,
	[Grid10k] [varchar](4) NULL,
	[Grid1k] [varchar](6) NULL,
	[GRPrecision] [int] NULL,
	[GRQualifier] [varchar](20) NULL,
	[Easting] [int] NULL,
	[Northing] [int] NULL,
	[Location] [varchar](100) NULL,
	[Location2] [varchar](100) NULL,

	[SampleType] [varchar](20) NULL,
	[RecType] [varchar](40) NULL,
	[Provenance] [varchar](16) NULL,

	[StatusEuro] [varchar](50) NULL,
	[StatusUK] [varchar](100) NULL,
	[StatusOther] [varchar](150) NULL,
	[StatusINNS] [varchar](50) NULL,

	[SurveyName] [varchar](100) NULL,
	[SurveyRunBy] [varchar](75) NULL,
	[SurveyTags] [varchar](250) NULL,
	[SurveyRef] [varchar](30) NULL,

	[Comments] [varchar](254) NULL,
	[SampleComments] [varchar](254) NULL,
	[DeterminerComments] [varchar](254) NULL,
	[ObsSource] [varchar](254) NULL,

	[PrivateLocation] [varchar](100) NULL,
	[PrivateCode] [varchar](20) NULL,
	[PrivateRecorder] [varchar](150) NULL,
	[PrivateDeterminer] [varchar](60) NULL,

	[Confidential] [char](1) NULL,
	[Sensitive] [char](1) NULL,
	[NegativeRec] [char](1) NULL,
	[HistoricRec] [char](1) NULL,

	[Verification] [varchar](21) NULL,

	[RecOccKey] [char](16) NOT NULL,
	[RecSamKey] [char](16) NULL,
	[RecSurKey] [char](16) NULL,
	[RecLocKey] [char](16) NULL,
	[RecTLIKey] [char](16) NULL,
	[RecTVKey] [char](16) NULL,

	[LastUpdated] [date] NULL,
	[VersionDate] [date] NULL,

	[MI_STYLE] [varchar](254) NULL,
	[MI_PRINX] [int] IDENTITY(1,1) NOT NULL,
	[SP_GEOMETRY] [geometry] NULL,

 CONSTRAINT [PK_LERC_Spp_Table_MI_PRINX] PRIMARY KEY CLUSTERED 
(
	[MI_PRINX] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

-- Refresh dependent SQL views
DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql += N'EXEC sp_refreshview ''' 
  + QUOTENAME(s.name) + '.' + QUOTENAME(v.name) + ''';'
FROM sys.sql_expression_dependencies AS d
INNER JOIN sys.views AS v
ON d.referencing_id = v.[object_id]
INNER JOIN sys.schemas AS s
ON v.[schema_id] = s.[schema_id]
WHERE d.referenced_id = OBJECT_ID('dbo.LERC_Spp_Table')
GROUP BY s.name, v.name;

EXEC sp_executesql @sql;
