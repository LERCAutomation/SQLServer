USE NBNData
GO

/*---------------------------------------------------------------------------*\
	Create LERC_Taxon_Names table
\*---------------------------------------------------------------------------*/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[LERC_Taxon_Names]') AND type in (N'U'))
DROP TABLE [dbo].[LERC_Taxon_Names]
GO

CREATE TABLE [dbo].[LERC_Taxon_Names](
	[TaxonGroup] [varchar](50) NOT NULL,
	[TaxonName] [varchar](100) NOT NULL,
	[DefaultCommonName] [varchar](100) NULL,
	[DefaultLocation] [varchar](100) NULL,
	[DefaultGR] [varchar](6) NULL,
	[Confidential] [char](1) NULL,
	[EarliestYear] [int] NOT NULL,
	[NonNotableSpp] [char](1) NULL,
	[InvalidSpp] [char](1) NULL,
	[OverrideStatus] [char](1) NULL,
	[DefaultStatusEuro] [varchar](50) NULL,
	[DefaultStatusUK] [varchar](100) NULL,
	[DefaultStatusOther] [varchar](150) NULL,
	[DefaultStatusINNS] [varchar](50) NULL,
 CONSTRAINT [PK_LERC_Taxon_Names] PRIMARY KEY CLUSTERED 
(
	[TaxonGroup] ASC,
	[TaxonName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/*---------------------------------------------------------------------------*\
	Populate LERC_Taxon_Names table
\*---------------------------------------------------------------------------*/
INSERT [dbo].[LERC_Taxon_Names] ([TaxonGroup], [TaxonName], [DefaultCommonName], [DefaultLocation], [DefaultGR], [Confidential], [EarliestYear], [NonNotableSpp], [InvalidSpp], [OverrideStatus], [DefaultStatusD1], [DefaultStatusD2], [DefaultStatusD3], [DefaultStatusD4], [DefaultStatusD5], [DefaultStatusD6], [DefaultStatusD7], [DefaultStatusD8]) VALUES (N'Amphibians', N'Epidalea calamita', NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
GO
