USE NBNData
GO

/*---------------------------------------------------------------------------*\
	Create Spatial_Tables table
\*---------------------------------------------------------------------------*/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Spatial_Tables]') AND type in (N'U'))
DROP TABLE [dbo].[Spatial_Tables]
GO

CREATE TABLE [dbo].[Spatial_Tables](
	[TableName] [varchar](32) NOT NULL,
	[OwnerName] [varchar](32) NOT NULL,
	[XColumn] [varchar](32) NOT NULL,
	[YColumn] [varchar](32) NOT NULL,
	[SizeColumn] [varchar](32) NOT NULL,
	[IsSpatial] [bit] NOT NULL,
	[SpatialColumn] [varchar](32) NOT NULL,
	[SRID] [int] NOT NULL,
	[CoordSystem] [varchar](254) NOT NULL,
	[SurveyKeyColumn] [varchar](32) NOT NULL
) ON [PRIMARY]
GO

/*---------------------------------------------------------------------------*\
	Populate Spatial_Tables table
\*---------------------------------------------------------------------------*/
INSERT [dbo].[Spatial_Tables] ([TableName], [OwnerName], [XColumn], [YColumn], [SizeColumn], [IsSpatial], [SpatialColumn], [SRID], [CoordSystem], [SurveyKeyColumn]) VALUES (N'LERC_Spp_Table', N'dbo', N'Easting', N'Northing', N'GRPrecision', 1, N'SP_GEOMETRY', 27700, N'Earth Projection 8, 79, "m", -2, 49, 0.9996012717, 400000, -100000 Bounds (-7845061.1011, -15524202.1641) (8645061.1011, 4470074.53373)', 'RecSurKey')
