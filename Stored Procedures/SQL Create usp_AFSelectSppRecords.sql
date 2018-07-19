﻿/*===========================================================================*\
  AFSelectSppRecords is a SQL stored procedure to create an intermediate
  SQL Server table containing a subset of records based on their spatial
  intersection with a given record in another table.
  
  Copyright © 2012-2013, 2015-2018 Andy Foy Consulting
  
  This file is used by the 'DataExtractor' tool, versions of which are
  available for MapInfo and ArcGIS.
  
  AFSelectSppRecords is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.
  
  AFSelectSppRecords is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
  
  A copy of the GNU General Public License is available from
  <http://www.gnu.org/licenses/>.
\*===========================================================================*/

USE NBNData
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Drop the procedure if it already exists
If EXISTS (SELECT ROUTINE_NAME FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_SCHEMA = 'dbo' AND ROUTINE_NAME = 'AFSelectSppRecords')
	DROP PROCEDURE dbo.AFSelectSppRecords
GO

-- Create the stored procedure
CREATE PROCEDURE dbo.AFSelectSppRecords
	@Schema varchar(50),
	@PartnerTable varchar(50),
	@PartnerColumn varchar(50),
	@Partner varchar(50),
	@TagsColumn varchar(50),
	@PartnerSpatialColumn varchar(50),
	@SelectType int,
	@SpeciesTable varchar(50),
	@UserId varchar(50)
AS
BEGIN

/*===========================================================================*\
  Description:		Select species records that intersect with the partner
					polygon(s) passed by the calling routine.

  Parameters:
	@Schema					The schema for the partner and species table.
	@PartnerTable			The name of the partner table used for selecting.
	@PartnerColumn			The name of the column containing the partner to be used.
	@Partner				The partner to be used for selecting.
	@TagsColumn				The name of the column containing the survey tags to check.
	@PartnerSpatialColumn	The name of the column containing the spatial geometry.
	@SelectType				Whether the selection is based on the partner's spatial
							boundary, survey tags or both.
	@SpeciesTable			The name of the table containing the species records.
	@UserId					The userid of the user executing the selection.
	@UseCentroids			Whether the selection is based on polygon centroids or the
							whole polygon. 0 = polygon, 1 = centroid

  Created:			Nov 2012
  Last revised: 	Jul 2018

 *****************  Version 11  ****************
 Author: Andy Foy		Date: 13/07/2018
 A. Add parameter for name of the spatial column in the
 	partner table.
 B. Add option to perform polygon selection using centroids.
 C. Remove hard-coding and get the primary key column name.

 *****************  Version 10  ****************
 Author: Andy Foy		Date: 16/11/2017
 A. Suppress print statements unless in debug mode.

 *****************  Version 9  *****************
 Author: Andy Foy		Date: 28/07/2017
 A. Force temporary tables to collate using the
	current database standard.

 *****************  Version 8  *****************
 Author: Andy Foy		Date: 03/05/2017
 A. Simplify (reduce) partner geometry slightly
	to speed up spatial selection.

 *****************  Version 7  *****************
 Author: Andy Foy		Date: 25/07/2016
 A. Only create temporary survey tag table if it's
    going to be used.
 B. Added clearer comments.

 *****************  Version 6  *****************
 Author: Andy Foy		Date: 11/07/2016
 A. Make sure temporary index table is dropped before
    deleting table.

 *****************  Version 5  *****************
 Author: Andy Foy		Date: 14/03/2016
 A. Increase length of partner tags variable.
 B. Rename procedure to AFSelectSppRecords.

 *****************  Version 4  *****************
 Author: Andy Foy		Date: 03/12/2015
 A. Include records where one or more of the survey
    tags are in the partner's survey tag string.
 B. Enable selections to be based on the partner's
    spatial boundary, survey tags or both.

 *****************  Version 3  *****************
 Author: Andy Foy		Date: 11/09/2015
 A. Remove hard-coded column names.
 B. Enable subsets to be non-spatial (i.e. have
	no geometry column.
 C. Lookup table column names and spatial variables
	from Spatial_Tables.

 *****************  Version 2  *****************
 Author: Andy Foy		Date: 08/06/2015
 A. Include userid as parameter to use in temporary SQL
	table name to enable concurrent use of tool.

 *****************  Version 1  *****************
 Author: Andy Foy		Date: 01/11/2012
 A. Initial version of code.

\*===========================================================================*/

	SET NOCOUNT ON

	/*---------------------------------------------------------------------------*\
		Set any default parameter values and declare any variables
	\*---------------------------------------------------------------------------*/

	If @UserId IS NULL
		SET @UserId = 'temp'

	DECLARE @debug int
	Set @debug = 0

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Started.'

	DECLARE @sqlCommand nvarchar(2000)
	DECLARE @params nvarchar(2000)
	DECLARE @RecCnt Int
	DECLARE @PrimaryKey nvarchar(128)
	DECLARE @DataType nvarchar(128)
	DECLARE @DataLength int

	DECLARE @TempTable varchar(50)
	SET @TempTable = @SpeciesTable + '_' + @UserId

	/*---------------------------------------------------------------------------*\
		Get the name of the primary key column for the species table
	\*---------------------------------------------------------------------------*/

	SET @sqlcommand = 'SELECT @O1 = CO.COLUMN_NAME,' +
					  ' @O2 = CO.DATA_TYPE,' +
					  ' @O3 = CO.CHARACTER_MAXIMUM_LENGTH' +
					  ' FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS TC' +
					  ' INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS KU' +
			          ' ON TC.CONSTRAINT_NAME = KU.CONSTRAINT_NAME' +
			          ' AND TC.CONSTRAINT_TYPE = 'PRIMARY KEY''' +
					  ' INNER JOIN INFORMATION_SCHEMA.COLUMNS CO' +
					  ' ON CO.TABLE_NAME = KU.TABLE_NAME
					  ' AND CO.COLUMN_NAME = KU.COLUMN_NAME
					  ' WHERE KU.TABLE_SCHEMA = ''' + @Schema + '''' +
			          ' AND KU.TABLE_NAME = ''' + @SpeciesTable + ''''

	SET @params =	'@O1 nvarchar(128) OUTPUT,'
					'@O2 nvarchar(128) OUTPUT,' +
					'@O3 int OUTPUT' +
		
	EXEC sp_executesql @sqlcommand, @params,
		@O1 = @PrimaryKey OUTPUT, @O2 = @DataType OUTPUT, @O3 = @DataLength OUTPUT

	If @DataLength IS NOT NULL
		SET @DataType = @DataType + '(' + CAST(@DataLength As varchar) + ')'

	/*---------------------------------------------------------------------------*\
		Drop any existing temporary tables
	\*---------------------------------------------------------------------------*/
	
	-- Drop the temporary table if it already exists
	If EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @Schema AND TABLE_NAME = @TempTable)
	BEGIN
		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Dropping temporary table ...'
		SET @sqlcommand = 'DROP TABLE ' + @Schema + '.' + @TempTable
		EXEC (@sqlcommand)
	END

	-- Drop the index on the sequential primary key of the temporary index table if it already exists
	If EXISTS (SELECT column_name FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE WHERE TABLE_SCHEMA = @Schema AND TABLE_NAME = @TempTable AND COLUMN_NAME = ' + @PrimaryKey + ' AND CONSTRAINT_NAME = 'PK_' + @TempTable + '_INX')
	BEGIN
		SET @sqlcommand = 'ALTER TABLE ' + @Schema + '.' + @TempTable + '_INX' +
			' DROP CONSTRAINT PK_' + @TempTable + '_INX_IX'
		EXEC (@sqlcommand)
	END
	
	-- Drop the temporary index table if it already exists
	If EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @Schema AND TABLE_NAME = @TempTable + '_INX')
	BEGIN
		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Dropping temporary index table ...'
		SET @sqlcommand = 'DROP TABLE ' + @Schema + '.' + @TempTable + '_INX'
		EXEC (@sqlcommand)
	END

	/*---------------------------------------------------------------------------*\
		Lookup survey tags and spatial geometry variables from Partner table
	\*---------------------------------------------------------------------------*/

	DECLARE @PartnerGeom geometry
	DECLARE @PartnerTags varchar(254)

	-- Retrieve the variables from the partner table
	SET @sqlcommand = 'SELECT @O1 = ' + @PartnerSpatialColumn + '.Reduce(1),' +
							 '@O2 = ' + @TagsColumn +
					  ' FROM ' + @Schema + '.' + @PartnerTable +
					  ' WHERE ' + @PartnerColumn + ' = ''' + @Partner + ''''

	SET @params =	'@O1 geometry OUTPUT, ' +
					'@O2 varchar(254) OUTPUT'
		
	EXEC sp_executesql @sqlcommand, @params,
		@O1 = @PartnerGeom OUTPUT, @O2 = @PartnerTags OUTPUT
	
	/*---------------------------------------------------------------------------*\
		Create a temporary survey tags table (if required)
	\*---------------------------------------------------------------------------*/

	If @SelectType <> 1
	BEGIN

		If @PartnerTags IS NULL
			SET @PartnerTags = ''
	
		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Partner tags = ' + @PartnerTags

		CREATE TABLE #TagsTable
		(
			SurveyKey char(16) COLLATE database_default NOT NULL,
			TagFound int NOT NULL
		)

		INSERT INTO #TagsTable (SurveyKey, TagFound)
		SELECT SURVEY_KEY, dbo.AFSurveyTagFound(SURVEY_KEY, @PartnerTags)
		FROM SURVEY

	END
	
	/*---------------------------------------------------------------------------*\
		Lookup table column names and spatial variables from Spatial_Tables
	\*---------------------------------------------------------------------------*/

	DECLARE @IsSpatial bit
	DECLARE @XColumn varchar(32), @YColumn varchar(32), @SizeColumn varchar(32), @SpatialColumn varchar(32)
	DECLARE @CoordSystem varchar(254), @SurveyKeyColumn varchar(32)
	
	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Retrieving table spatial details ...'

	DECLARE @SpatialTable varchar(100)
	SET @SpatialTable ='Spatial_Tables'

	-- Retrieve the table column names and spatial variables
	SET @sqlcommand = 'SELECT @O1 = XColumn,' +
							 ' @O2 = YColumn,' +
							 ' @O3 = SizeColumn,' +
							 ' @O4 = IsSpatial,' +
							 ' @O5 = SpatialColumn,' +
							 ' @O6 = CoordSystem,' +
							 ' @O7 = SurveyKeyColumn' +
						' FROM ' + @Schema + '.' + @SpatialTable +
						' WHERE TableName = ''' + @SpeciesTable + ''' AND OwnerName = ''' + @Schema + ''''

	SET @params =	'@O1 varchar(32) OUTPUT,' +
					'@O2 varchar(32) OUTPUT,' +
					'@O3 varchar(32) OUTPUT,' +
					'@O4 bit OUTPUT,' +
					'@O5 varchar(32) OUTPUT,' +
					'@O6 varchar(254) OUTPUT,' +
					'@O7 varchar(32) OUTPUT'
		
	EXEC sp_executesql @sqlcommand, @params,
		@O1 = @XColumn OUTPUT, @O2 = @YColumn OUTPUT, @O3 = @SizeColumn OUTPUT, @O4 = @IsSpatial OUTPUT, 
		@O5 = @SpatialColumn OUTPUT, @O6 = @CoordSystem OUTPUT, @O7 = @SurveyKeyColumn OUTPUT
		
	/*---------------------------------------------------------------------------*\
		Report if the tables are spatially enabled
	\*---------------------------------------------------------------------------*/

	If @debug = 1
	BEGIN
		If @IsSpatial = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Table is spatial.'
		ELSE
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Table is not spatial.'
	END

	If @debug = 1
	BEGIN
		IF @PartnerGeom IS NULL
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Partner geometry is null.'
		ELSE
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Partner geometry is not null.'
	END

	/*---------------------------------------------------------------------------*\
		Select the species record primary keys into a temporary table
	\*---------------------------------------------------------------------------*/

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Performing selection for partner = ' + @Partner + ' ...'

	-- Create a temporary index table
	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Creating temporary table ' + @Schema + '.' + @TempTable + '_INX'

	SET @sqlcommand = 'CREATE TABLE ' + @Schema + '.' + @TempTable + '_INX (' +
		' INX ' + @DataType + ' NOT NULL,' +
		' CONSTRAINT PK_' + @TempTable + '_INX_IX PRIMARY KEY (INX)' +
		' )'
	EXEC (@sqlcommand)

	If @SelectType = 1 AND @IsSpatial = 1 AND @PartnerGeom IS NOT NULL
	BEGIN
		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Performing spatial selection only ...'

		If @UseCentroids = 0
		BEGIN

			SET @sqlcommand = 
				'INSERT INTO ' + @Schema + '.' + @TempTable + '_INX' +
				' SELECT Spp.' + @PrimaryKey
				' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
				' WHERE Spp.' + @SpatialColumn + '.STIntersects(@I1) = 1'

			SET @params = '@I1 geometry'
	
			EXEC sp_executesql @sqlcommand, @params,
				@I1 = @PartnerGeom
	
			Set @RecCnt = @@ROWCOUNT

		END
		ELSE
		BEGIN

			-- Select points

			SET @sqlcommand = 
				'INSERT INTO ' + @Schema + '.' + @TempTable + '_INX' +
				' SELECT Spp.' + @PrimaryKey
				' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
				' WHERE Spp.' + @SpatialColumn + '.STIntersects(@I1) = 1' +
				' AND ' + @SpatialColumn + '.STGeometryType() LIKE ''%Point'''

			SET @params = '@I1 geometry'
	
			EXEC sp_executesql @sqlcommand, @params,
				@I1 = @PartnerGeom
	
			Set @RecCnt = @@ROWCOUNT

			-- Select polygons (using their centroids)

			SET @sqlcommand = 
				'INSERT INTO ' + @Schema + '.' + @TempTable + '_INX' +
				' SELECT Spp.' + @PrimaryKey
				' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
				' WHERE Spp.' + @SpatialColumn + '.STCentroid().STIntersects(@I1) = 1' +
				' AND ' + @SpatialColumn + '.STGeometryType() LIKE ''%Polygon'''

			SET @params = '@I1 geometry'
	
			EXEC sp_executesql @sqlcommand, @params,
				@I1 = @PartnerGeom
	
			Set @RecCnt = @RecCnt + @@ROWCOUNT

		END

		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + Cast(@RecCnt As varchar) + ' temporary records inserted ...'

		SET @sqlcommand = 
			'SELECT Spp.*' + 
			' INTO ' + @Schema + '.' + @TempTable +
			' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
			' INNER JOIN ' + @Schema + '.' + @TempTable + '_INX As Keys ON Keys.INX = Spp.' + @PrimaryKey

		EXEC (@sqlcommand)
	END
	ELSE
	BEGIN
		If (@SelectType = 2 AND @PartnerTags <> '') Or (@SelectType = 3 AND @PartnerGeom IS NULL)
		BEGIN
			If @debug = 1
				PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Performing tags selection only ...'

			SET @sqlcommand = 
				'SELECT Spp.*' + 
				' INTO ' + @Schema + '.' + @TempTable +
				' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
				' INNER JOIN #TagsTable As Tags ON Tags.SurveyKey = Spp.' + @SurveyKeyColumn +
				' WHERE Tags.TagFound = 1'

				EXEC (@sqlcommand)
		END
		ELSE
		BEGIN
			If @SelectType = 3 AND (@PartnerTags <> '' Or (@IsSpatial = 1 AND @PartnerGeom IS NOT NULL))
			BEGIN
				If @debug = 1
					PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Performing spatial and tags selection ...'

				SET @sqlcommand = 
					'INSERT INTO ' + @Schema + '.' + @TempTable + '_INX' +
					' SELECT Spp.' + @PrimaryKey
					' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
					' INNER JOIN #TagsTable As Tags ON Tags.SurveyKey = Spp.' + @SurveyKeyColumn +
					' WHERE Tags.TagFound = 1' +
					' UNION' +
					' SELECT Spp.' + @PrimaryKey
					' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
					' WHERE Spp.' + @SpatialColumn + '.STIntersects(@I1) = 1'

				SET @params = '@I1 geometry'

				EXEC sp_executesql @sqlcommand, @params,
					@I1 = @PartnerGeom

				Set @RecCnt = @@ROWCOUNT

				If @debug = 1
					PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + Cast(@RecCnt As varchar) + ' temporary records inserted ...'

				SET @sqlcommand = 
					'SELECT Spp.*' + 
					' INTO ' + @Schema + '.' + @TempTable +
					' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
					' INNER JOIN ' + @Schema + '.' + @TempTable + '_INX As Keys ON Keys.INX = Spp.' + @PrimaryKey

				EXEC (@sqlcommand)
			END
			ELSE
			BEGIN
				If @debug = 1
					PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'No selection performed.'

				SET @sqlcommand = 
					'SELECT Spp.*' +
					' INTO ' + @Schema + '.' + @TempTable +
					' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
					' WHERE 1=2'

				EXEC (@sqlcommand)

			END
		END
	END

	/*---------------------------------------------------------------------------*\
		Report the number of records selected
	\*---------------------------------------------------------------------------*/

	Set @RecCnt = @@ROWCOUNT

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + Cast(@RecCnt As varchar) + ' records selected ...'

	/*---------------------------------------------------------------------------*\
		Drop any temporary tables no longer required
	\*---------------------------------------------------------------------------*/

	-- Drop the temporary index table
	SET @sqlcommand = 'DROP TABLE ' + @Schema + '.' + @TempTable + '_INX'
	EXEC (@sqlcommand)

	-- Drop the temporary survey tags table (if it exists)
	If OBJECT_ID('tempdb..#TagsTable') IS NOT NULL
		DROP TABLE #TagsTable

	/*---------------------------------------------------------------------------*\
		Update the MapInfo MapCatalog if it exists
	\*---------------------------------------------------------------------------*/

	-- If the MapInfo MapCatalog exists then update it
	If EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'MAPINFO' AND TABLE_NAME = 'MAPINFO_MAPCATALOG')
	BEGIN
		-- Update the MapInfo MapCatalog entry
		SET @sqlcommand = 'EXECUTE dbo.AFUpdateMICatalog ''' + @Schema + ''', ''' + @TempTable + ''', ''' + @XColumn + ''', ''' + @YColumn +
			''', ''' + @SizeColumn + ''', ''' + @SpatialColumn + ''', ''' + @CoordSystem + ''', ''' + Cast(@RecCnt As varchar) + ''', ''' + Cast(@IsSpatial As varchar) + ''''
		EXEC (@sqlcommand)
	END

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Ended.'

END
GO
