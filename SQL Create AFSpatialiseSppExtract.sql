/*===========================================================================*\
  AFSpatialiseSppExtract is a SQL stored procedure to spatialise a SQL
  Server table by creating Geometry from X & Y grid reference values and
  a grid reference precision.
  
  Copyright © 2015 Andy Foy Consulting
  
  This file is used by the 'DataSelector' and 'DataExtractor' tools, versions
  of which are available for MapInfo and ArcGIS.
  
  AFSpatialiseSppExtract is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.
  
  AFSpatialiseSppExtract is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
  
  A copy of the GNU General Public License is available from
  <http://www.gnu.org/licenses/>.
\*===========================================================================*/

USE [NBNData]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*===========================================================================*\
  Description:		Prepares an existing SQL table that contains spatial data
					so that it can be used 'spatially' by SQL Server and MapInfo

  Parameters:
	@Schema			The schema for the table to be spatialised.
	@Table			The name of the table to be spatialised.
	@XMin			The minimum value for the eastings to be spatialised.
	@XMin			The maximum value for the eastings to be spatialised.
	@XMin			The minimum value for the nothings to be spatialised.
	@XMin			The maximum value for the nothings to be spatialised.
	@SizeMin		The minimum value for the precision to be spatialised.
	@SizeMax		The maximum value for the precision to be spatialised.
	@PointMax		The maximum value for the precision when points will be
					created instead of polygons.
	@PointPos		The position for plotting points (1 = Lower Left,
					2 = Mid, 3 = Upper Right)

  Created:			Nov 2012

 *****************  Version 4  *****************
 Author: Andy Foy		Date: 21/09/2015
 A. Remove hard-coded column names.
 B. Lookup table column names and spatial variables
	from Spatial_Tables.

 *****************  Version 3  *****************
 Author: Andy Foy		Date: 04/06/2015
 A. Add parameter for maximum size for plotting points.
 B. Plot points at lower left position not mid cell.

\*===========================================================================*/

-- Drop the procedure if it already exists
if exists (select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'AFSpatialiseSppExtract')
	DROP PROCEDURE dbo.AFSpatialiseSppExtract
GO

-- Create the stored procedure
CREATE PROCEDURE dbo.AFSpatialiseSppExtract
	@Schema varchar(50),
	@Table varchar(50),
	@XMin Int,
	@XMax Int,
	@YMin Int,
	@YMax Int,
	@SizeMin Int,
	@SizeMax Int,
	@PointMax Int,
	@PointPos Int

AS
BEGIN
	SET NOCOUNT ON

	DECLARE @debug int
	Set @debug = 0

	If @PointPos IS NULL OR @PointPos NOT IN (1, 2, 3)
		SET @PointPos = 1

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Started.'

	DECLARE @sqlCommand nvarchar(2000)
	DECLARE @params nvarchar(2000)

	-- Lookup table column names and spatial variables from Spatial_Tables
	DECLARE @IsSpatial bit
	DECLARE @XColumn varchar(32), @YColumn varchar(32), @SizeColumn varchar(32), @SpatialColumn varchar(32)
	DECLARE @SRID int, @CoordSystem varchar(254)
	
	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Retrieving table spatial details ...'

	DECLARE @SpatialTable varchar(100)
	SET @SpatialTable ='Spatial_Tables'

	-- Retrieve the table column names and spatial variables
	SET @sqlcommand = 'SELECT @O1 = XColumn, ' +
							 '@O2 = YColumn, ' +
							 '@O3 = SizeColumn, ' +
							 '@O4 = IsSpatial, ' +
							 '@O5 = SpatialColumn, ' +
							 '@O6 = SRID, ' +
							 '@O7 = CoordSystem ' +
						'FROM ' + @Schema + '.' + @SpatialTable + ' ' +
						'WHERE TableName = ''' + @Table + ''' AND OwnerName = ''' + @Schema + ''''

	SET @params =	'@O1 varchar(32) OUTPUT, ' +
					'@O2 varchar(32) OUTPUT, ' +
					'@O3 varchar(32) OUTPUT, ' +
					'@O4 bit OUTPUT, ' +
					'@O5 varchar(32) OUTPUT, ' +
					'@O6 int OUTPUT, ' +
					'@O7 varchar(254) OUTPUT'
		
	EXEC sp_executesql @sqlcommand, @params,
		@O1 = @XColumn OUTPUT, @O2 = @YColumn OUTPUT, @O3 = @SizeColumn OUTPUT, @O4 = @IsSpatial OUTPUT, 
		@O5 = @SpatialColumn OUTPUT, @O6 = @SRID OUTPUT, @O7 = @CoordSystem OUTPUT
	
	-- Add a new non-clustered index on the XColumn field if it doesn't already exists
	if not exists (select name from sys.indexes where name = 'IX_' + @Table + '_' + @XColumn)
	BEGIN
		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Adding XColumn field index ...'

		Set @sqlCommand = 'CREATE INDEX IX_' + @Table + '_' + @XColumn +
			' ON ' + @Schema + '.' + @Table +' (' + @XColumn+ ')'
		EXEC (@sqlcommand)
	END
	
	-- Add a new non-clustered index on the YColumn field if it doesn't already exists
	if not exists (select name from sys.indexes where name = 'IX_' + @Table + '_' + @YColumn)
	BEGIN
		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Adding YColumn field index ...'

		Set @sqlCommand = 'CREATE INDEX IX_' + @Table + '_' + @YColumn +
			' ON ' + @Schema + '.' + @Table +' (' + @YColumn+ ')'
		EXEC (@sqlcommand)
	END

	-- Add a new non-clustered index on the SizeColumn field if it doesn't already exists
	if not exists (select name from sys.indexes where name = 'IX_' + @Table + '_' + @SizeColumn)
	BEGIN
		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Adding SizeColumn field index ...'

		Set @sqlCommand = 'CREATE INDEX IX_' + @Table + '_' + @SizeColumn +
			' ON ' + @Schema + '.' + @Table +' (' + @SizeColumn+ ')'
		EXEC (@sqlcommand)
	END

	-- Add a new MapInfo style field if it doesn't already exists
	if not exists (select column_name from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = @Schema and TABLE_NAME = @Table and COLUMN_NAME = 'MI_STYLE')
	BEGIN
		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Adding new MI_STYLE field ...'

		SET @sqlcommand = 'ALTER TABLE ' + @Schema + '.' + @Table +
			' ADD MI_STYLE VarChar(254)'
		EXEC (@sqlcommand)
	END

	-- Add a new primary key if it doesn't already exists
	if not exists (select column_name from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = @Schema and TABLE_NAME = @Table and COLUMN_NAME = 'MI_PRINX')
	BEGIN
		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Adding new MI_PRINX field ...'

		SET @sqlcommand = 'ALTER TABLE ' + @Schema + '.' + @Table +
			' ADD MI_PRINX Int IDENTITY'
		EXEC (@sqlcommand)
	END

	-- Add a new geometry field if it doesn't already exists
	if not exists (select column_name from INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA = @Schema and TABLE_NAME = @Table and COLUMN_NAME = @SpatialColumn)
	BEGIN
		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Adding new spatial field ...'

		SET @sqlcommand = 'ALTER TABLE ' + @Schema + '.' + @Table +
			' ADD ' + @SpatialColumn + ' Geometry'
		EXEC (@sqlcommand)
	END

	-- Add a new sequential index on the primary key if it doesn't already exists
	if not exists (select column_name from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_SCHEMA = @Schema and TABLE_NAME = @Table and COLUMN_NAME = 'MI_PRINX' and CONSTRAINT_NAME = 'PK_' + @Table + '_MI_PRINX')
	BEGIN
		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Adding new primary index ...'

		SET @sqlcommand = 'ALTER TABLE ' + @Schema + '.' + @Table +
			' ADD CONSTRAINT PK_' + @Table + '_MI_PRINX' +
			' PRIMARY KEY(MI_PRINX)'
		EXEC (@sqlcommand)
	END
	
	-- Drop the synonym for the table passed to the procedure if it already exists
	if exists (select name from sys.synonyms where name = 'Species_Temp')
	BEGIN
		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Dropping table synonym ...'

		Set @sqlCommand = 'DROP SYNONYM Species_Temp'
		EXEC (@sqlcommand)
	END

	-- Create a synonym for the table passed to the procedure
	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Creating table synonym ...'
	Set @sqlCommand = 'CREATE SYNONYM Species_Temp' +
		' FOR ' + @Schema + '.' + @Table
	EXEC (@sqlcommand)

	-- Drop the view for the table (via the synonym) if it already exists
	if exists (select table_name from INFORMATION_SCHEMA.VIEWS where TABLE_NAME = 'Species_Temp_View')
	BEGIN
		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Dropping table view ...'

		Set @sqlCommand = 'DROP VIEW Species_Temp_View'
		EXEC (@sqlcommand)
	END

	-- Create a view for the table (via the synonym)
	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Creating table view ...'

	Set @sqlCommand = 'CREATE VIEW Species_Temp_View' +
		' AS SELECT ' + @XColumn + ' As XCOORD,' +
		' ' + @YColumn + ' As YCOORD,' +
		' ' + @SizeColumn + ' As GRIDSIZE,' +
		' ' + @SpatialColumn + ' As SP_GEOMETRY' +
		' FROM Species_Temp'
	EXEC (@sqlcommand)

	-- Drop the spatial index on the geometry field if it already exists
	if exists (select name from sys.indexes where name = 'SIndex_' + @Table + '_SP_Geometry')
	BEGIN
		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Dropping the spatial index ...'

		SET @sqlcommand = 'DROP INDEX SIndex_' + @Table + '_SP_Geometry ON ' + @Schema + '.' + @Table
		EXEC (@sqlcommand)
	END

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Updating valid geometries ...'

	-- Set the geometry for points based on the Xcolumn, YColumn and SizeColumn values
	If @PointPos = 1
	BEGIN
		UPDATE Species_Temp_View
			SET SP_GEOMETRY = geometry::STPointFromText('POINT(' +
			dbo.AFReturnLowerEastings(XCOORD,GRIDSIZE) + ' ' + dbo.AFReturnLowerNorthings(YCOORD,GRIDSIZE) + ')', @SRID)
			WHERE XCOORD >= @XMin
			AND XCOORD <= @XMax
			AND YCOORD >= @YMin
			AND YCOORD <= @YMax
			AND GRIDSIZE >= @SizeMin
			AND GRIDSIZE <= @SizeMax
			AND GRIDSIZE <= @PointMax
	END

	If @PointPos = 2
	BEGIN
		UPDATE Species_Temp_View
			SET SP_GEOMETRY = geometry::STPointFromText('POINT(' +
			dbo.AFReturnMidEastings(XCOORD,GRIDSIZE) + ' ' + dbo.AFReturnMidNorthings(YCOORD,GRIDSIZE) + ')', @SRID)
			WHERE XCOORD >= @XMin
			AND XCOORD <= @XMax
			AND YCOORD >= @YMin
			AND YCOORD <= @YMax
			AND GRIDSIZE >= @SizeMin
			AND GRIDSIZE <= @SizeMax
			AND GRIDSIZE <= @PointMax
	END

	If @PointPos = 3
	BEGIN
		UPDATE Species_Temp_View
			SET SP_GEOMETRY = geometry::STPointFromText('POINT(' +
			dbo.AFReturnUpperEastings(XCOORD,GRIDSIZE) + ' ' + dbo.AFReturnUpperNorthings(YCOORD,GRIDSIZE) + ')', @SRID)
			WHERE XCOORD >= @XMin
			AND XCOORD <= @XMax
			AND YCOORD >= @YMin
			AND YCOORD <= @YMax
			AND GRIDSIZE >= @SizeMin
			AND GRIDSIZE <= @SizeMax
			AND GRIDSIZE <= @PointMax
	END

	-- Set the geometry for polygons based on the Xcolumn, YColumn and SizeColumn values
	UPDATE Species_Temp_View
		SET SP_GEOMETRY = geometry::STPolyFromText('POLYGON((' +
		dbo.AFReturnLowerEastings(XCOORD,GRIDSIZE) + ' ' + dbo.AFReturnLowerNorthings(YCOORD,GRIDSIZE) + ', ' +
		dbo.AFReturnUpperEastings(XCOORD,GRIDSIZE) + ' ' + dbo.AFReturnLowerNorthings(YCOORD,GRIDSIZE) + ', ' +
		dbo.AFReturnUpperEastings(XCOORD,GRIDSIZE) + ' ' + dbo.AFReturnUpperNorthings(YCOORD,GRIDSIZE) + ', ' +
		dbo.AFReturnLowerEastings(XCOORD,GRIDSIZE) + ' ' + dbo.AFReturnUpperNorthings(YCOORD,GRIDSIZE) + ', ' +
		dbo.AFReturnLowerEastings(XCOORD,GRIDSIZE) + ' ' + dbo.AFReturnLowerNorthings(YCOORD,GRIDSIZE) + '))', @SRID)
		WHERE XCOORD >= @XMin
		AND XCOORD <= @XMax
		AND YCOORD >= @YMin
		AND YCOORD <= @YMax
		AND GRIDSIZE >= @SizeMin
		AND GRIDSIZE <= @SizeMax
		AND GRIDSIZE > @PointMax

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Determining spatial extent ...'

	-- Calculate the geometric extent of the records (plus their precision)
	DECLARE
		@X1 int,
		@X2 int,
		@Y1 int,
		@Y2 int

	-- Retrieve the geometric extent values and store as variables
	SELECT  @X1 = MIN(XCOORD),
			@Y1 = MIN(YCOORD),
			@X2 = MAX(XCOORD) + MAX(GRIDSIZE),
			@Y2 = MAX(YCOORD) + MAX(GRIDSIZE)
	From Species_Temp_View
		WHERE XCOORD >= @XMin AND XCOORD <= @XMax AND YCOORD >= @YMin AND YCOORD <= @YMax AND GRIDSIZE >= @SizeMin AND GRIDSIZE <= @SizeMax

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Creating spatial index ...'

	-- Create the spatial index bounded by the geometric extent variables
	SET @sqlcommand = 'CREATE SPATIAL INDEX SIndex_' + @Table + '_SP_Geometry ON ' + @Schema + '.' + @Table + ' ( SP_Geometry )' + 
		' WITH ( ' +
		' BOUNDING_BOX = (XMIN=' + CAST(@X1 As varchar) + ', YMIN=' + CAST(@Y1 As varchar) + ', XMAX=' + CAST(@X2 AS varchar) + ', YMAX=' + CAST(@Y2 As varchar) + '),' +
		' GRIDS = (' +
			' LEVEL_1 = MEDIUM,' +
			' LEVEL_2 = MEDIUM,' +
			' LEVEL_3 = MEDIUM,' +
			' LEVEL_4 = MEDIUM),' +
		' CELLS_PER_OBJECT = 16' +
		')'
	EXEC (@sqlcommand)

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Dropping the synonym and view ...'

	-- Drop the table synonym
	DROP SYNONYM Species_Temp

	-- Drop the table view
	DROP View Species_Temp_View

	-- If the MapInfo MapCatalog exists then update it
	if exists (select TABLE_NAME from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'MAPINFO' and TABLE_NAME = 'MAPINFO_MAPCATALOG')
	BEGIN

		-- Delete the MapInfo MapCatalog entry if it already exists
		if exists (select TABLENAME from [MAPINFO].[MAPINFO_MAPCATALOG] where TABLENAME = @Table)
		BEGIN
			If @debug = 1
				PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Deleting the MapInfo MapCatalog entry ...'
			SET @sqlcommand = 'DELETE FROM [MAPINFO].[MAPINFO_MAPCATALOG]' +
				' WHERE TABLENAME = ''' + @Table + ''''
			EXEC (@sqlcommand)
		END

		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Inserting the MapInfo MapCatalog entry ...'

		-- Adding table to MapInfo MapCatalog
		INSERT INTO [MAPINFO].[MAPINFO_MAPCATALOG]
			([SPATIALTYPE]
			,[TABLENAME]
			,[OWNERNAME]
			,[SPATIALCOLUMN]
			,[DB_X_LL]
			,[DB_Y_LL]
			,[DB_X_UR]
			,[DB_Y_UR]
			,[COORDINATESYSTEM]
			,[SYMBOL]
			,[XCOLUMNNAME]
			,[YCOLUMNNAME]
			,[RENDITIONTYPE]
			,[RENDITIONCOLUMN]
			,[RENDITIONTABLE]
			,[NUMBER_ROWS]
			,[VIEW_X_LL]
			,[VIEW_Y_LL]
			,[VIEW_X_UR]
			,[VIEW_Y_UR])
		 VALUES
			(17.3
			,@Table
			,@Schema
			,@SpatialColumn
			,@X1
			,@Y1
			,@X2
			,@Y2
			,@CoordSystem
			,'Pen (1,2,0)  Brush (1,16777215,16777215)'
			,'NO_COLUMN'
			,'NO_COLUMN'
			,NULL
			,'MI_STYLE'
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL)

	END
	ELSE
	-- If the MapInfo MapCatalog doesn't exist then skip updating it
	BEGIN
		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'MapInfo MapCatalog not found - skipping update ...'
	END

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Ended.'

END
GO
