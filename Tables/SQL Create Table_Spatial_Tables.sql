USE NBNData
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[Spatial_Tables](
	[TableName] [varchar](32) NOT NULL,
	[OwnerName] [varchar](32) NOT NULL,
	[XColumn] [varchar](32) NOT NULL,
	[YColumn] [varchar](32) NOT NULL,
	[SizeColumn] [varchar](32) NOT NULL,
	[IsSpatial] [bit] NOT NULL,
	[SpatialColumn] [varchar](32) NULL,
	[SRID] [int] NULL,
	[CoordSystem] [varchar](254) NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO
