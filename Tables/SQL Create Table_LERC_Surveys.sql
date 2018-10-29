USE NBNData
GO

/*---------------------------------------------------------------------------*\
	Create LERC_Surveys table
\*---------------------------------------------------------------------------*/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[LERC_Surveys]') AND type in (N'U'))
DROP TABLE [dbo].[LERC_Surveys]
GO

CREATE TABLE [dbo].[LERC_Surveys](
	[SurveyName] [varchar](100) NOT NULL,
	[DefaultLocation] [varchar](100) NULL,
	[DefaultGR] [varchar](6) NULL,
	[Confidential] [char](1) NULL,
	[Exclude] [char](1) NULL,
 CONSTRAINT [PK_LERC_Surveys] PRIMARY KEY CLUSTERED 
(
	[SurveyName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/*---------------------------------------------------------------------------*\
	Populate LERC_Surveys table
\*---------------------------------------------------------------------------*/
INSERT [dbo].[LERC_Surveys] ([SurveyName], [DefaultLocation], [DefaultGR], [Confidential], [Exclude]) VALUES ('Dummy Survey', NULL, NULL, 'N', 'N')
GO
