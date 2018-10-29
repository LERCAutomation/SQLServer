USE NBNData
GO

/*---------------------------------------------------------------------------*\
	Create LERC_SQL_Update_Results table
\*---------------------------------------------------------------------------*/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[LERC_SQL_Update_Results]') AND type in (N'U'))
DROP TABLE [dbo].[LERC_SQL_Update_Results]
GO

CREATE TABLE [dbo].[LERC_SQL_Update_Results](
	[RowID] [int] IDENTITY(1,1) NOT NULL,
	[TimeStamp] [datetime] NULL,
	[Comment] [varchar](250) NULL
) ON [PRIMARY]
GO
