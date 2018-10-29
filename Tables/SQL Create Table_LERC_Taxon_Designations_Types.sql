USE NBNData
GO

/*---------------------------------------------------------------------------*\
	Create LERC_Taxon_Designation_Types table
\*---------------------------------------------------------------------------*/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[LERC_Taxon_Designation_Types]') AND type in (N'U'))
DROP TABLE [dbo].[LERC_Taxon_Designation_Types]
GO

CREATE TABLE [dbo].[LERC_Taxon_Designation_Types](
	[TAXON_DESIGNATION_TYPE_KEY] [char](16) NOT NULL,
	[Status_Abbreviation] [varchar](30) NULL,
	[Sort_Order] [int] NULL,
 CONSTRAINT [PK_LERC_Taxon_Designation_Types] PRIMARY KEY CLUSTERED 
(
	[TAXON_DESIGNATION_TYPE_KEY] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
