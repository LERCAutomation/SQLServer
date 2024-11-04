/*===========================================================================*\
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
	@UserId varchar(50),
	@UseCentroids int
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
  Last revised:		Oct 2024

 *****************  Version 18  ****************
 Author: Andy Foy		Date: 01/10/2024
 A. Add 'WITH RESULT SETS NONE' when executing SQL.

 *****************  Version 17  ****************
 Author: Andy Foy		Date: 04/02/2020
 A. Performance improvements.

 *****************  Version 16  ****************
 Author: Andy Foy		Date: 23/09/2019
 A. Add check that partner is found in partner table.

 *****************  Version 15  ****************
 Author: Andy Foy		Date: 29/05/2019
 A. Select all records if partner geometry is null.

 *****************  Version 14  ****************
 Author: Andy Foy		Date: 15/05/2019
 A. Ensure keys added to index temporary table are unique.

 *****************  Version 13  ****************
 Author: Andy Foy		Date: 11/04/2019
 A. Fix bug when partner tags column is blank.

 *****************  Version 12  ****************
 Author: Andy Foy		Date: 13/12/2018
 A. Use schema parameter when calling stored procedures
    and user functions.

 *****************  Version 11  ****************
 Author: Andy Foy		Date: 13/07/2018
 A. Add parameter for name of the spatial column in the
 	partner table.
 B. Add option to perform polygon selection using centroids.

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
	Set @debug = 1

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Started.'

	DECLARE @sqlCommand nvarchar(2000)
	DECLARE @params nvarchar(2000)
	DECLARE @RecCnt Int
	DECLARE @PrimaryKey nvarchar(128)
	DECLARE @DataType nvarchar(128)
	DECLARE @DataLength int

	SET @PrimaryKey = 'RecOccKey'
	SET @DataType = 'varchar'
	SET @DataLength = 16

	DECLARE @TempTable varchar(50)
	SET @TempTable = @SpeciesTable + '_' + @UserId

	/*---------------------------------------------------------------------------*\
		Drop any existing temporary tables
	\*---------------------------------------------------------------------------*/
	
	-- Drop the temporary survey tags table if it already exists
	If OBJECT_ID('tempdb..#TagsTable') IS NOT NULL
		DROP TABLE #TagsTable

	-- Drop the temporary table if it already exists
	If EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @Schema AND TABLE_NAME = @TempTable)
	BEGIN
		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Dropping temporary table ...'
		SET @sqlcommand = 'DROP TABLE ' + @Schema + '.' + @TempTable
		EXEC (@sqlcommand)
		WITH RESULT SETS NONE
	END

	/*---------------------------------------------------------------------------*\
		Lookup survey tags and spatial geometry variables from Partner table
	\*---------------------------------------------------------------------------*/

	DECLARE @PartnerName varchar(50)
	DECLARE @PartnerGeom geometry
	DECLARE @PartnerTags varchar(254)

	-- Retrieve the variables from the partner table
	SET @sqlcommand = 'SELECT @O1 = ' + @PartnerColumn + ',' +
							 '@O2 = ' + @PartnerSpatialColumn + '.Reduce(1),' +
							 '@O3 = ' + @TagsColumn +
					  ' FROM ' + @Schema + '.' + @PartnerTable +
					  ' WHERE ' + @PartnerColumn + ' = ''' + @Partner + ''''

	SET @params =	'@O1 varchar(50) OUTPUT, ' +
					'@O2 geometry OUTPUT, ' +
					'@O3 varchar(254) OUTPUT'
	
	EXEC sp_executesql @sqlcommand, @params,
		@O1 = @PartnerName OUTPUT, @O2 = @PartnerGeom OUTPUT, @O3 = @PartnerTags OUTPUT
		WITH RESULT SETS NONE

	If @PartnerName IS NULL
	BEGIN
		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Partner not found in partner table.'
	END
	ELSE
	BEGIN
	
		/*---------------------------------------------------------------------------*\
			Create a temporary survey tags table (if required)
		\*---------------------------------------------------------------------------*/

		If @SelectType <> 1
		BEGIN

			-- Remove any leading/training spaces
			SET @PartnerTags = LTRIM(RTRIM(@PartnerTags))
			If NULLIF(@PartnerTags, '') IS NULL
				SET @PartnerTags = ''''''

			If @debug = 1
				PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Partner tags = ' + @PartnerTags

			-- Add a opening single quote if it's missing
			If LEN(@PartnerTags) < 2 OR LEFT(@PartnerTags, 2) <> ''''''
				SET @PartnerTags = '''' + @PartnerTags

			-- Add a closing single quote if it's missing
			If LEN(@PartnerTags) < 2 OR RIGHT(@PartnerTags, 2) <> ''''''
				SET @PartnerTags = @PartnerTags + ''''

			CREATE TABLE #TagsTable
			(
				SurveyKey char(16) COLLATE database_default NOT NULL,
				TagFound int NOT NULL
			)

			SET @sqlcommand = 'INSERT INTO #TagsTable (SurveyKey, TagFound) ' +
				'SELECT SURVEY_KEY, ' + @Schema + '.AFSurveyTagFound(SURVEY_KEY, ''' + @PartnerTags + ''') ' +
				'FROM NBNData.dbo.SURVEY'
			EXEC (@sqlcommand)
			WITH RESULT SETS NONE

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
			WITH RESULT SETS NONE
		
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
			Select the records into the temporary table
		\*---------------------------------------------------------------------------*/

		SET @RecCnt = 0

		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Performing selection for partner = ' + @Partner + ' ...'

		-- Create the temporary table
		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Creating temporary table ' + @Schema + '.' + @TempTable

		SET @sqlcommand = 
			'SELECT Spp.*' +
			' INTO ' + @Schema + '.' + @TempTable +
			' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
			' WHERE 1=2'
		EXEC (@sqlcommand)
		WITH RESULT SETS NONE

		If (@SelectType = 1 OR @SelectType = 3) AND @IsSpatial = 1
		BEGIN
	
			If @debug = 1
				PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Performing spatial selection ...'

			If @PartnerGeom IS NOT NULL
			BEGIN

				If @UseCentroids = 0
				BEGIN

					-- Select all points and polygons that intersect the partner
					SET @sqlcommand = 
						'INSERT INTO ' + @Schema + '.' + @TempTable +
						' SELECT Spp.*' +
						' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
						' WHERE Spp.' + @SpatialColumn + '.STIntersects(@I1) = 1'
					SET @params = '@I1 geometry'
					EXEC sp_executesql @sqlcommand, @params,
						@I1 = @PartnerGeom
						WITH RESULT SETS NONE

					Set @RecCnt = @@ROWCOUNT
		
				END
				ELSE
				BEGIN

					-- Select points that intersect the partner
					SET @sqlcommand = 
						'INSERT INTO ' + @Schema + '.' + @TempTable +
						' SELECT Spp.*' +
						' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
						' WHERE Spp.' + @SpatialColumn + '.STIntersects(@I1) = 1' +
						' AND ' + @SpatialColumn + '.STGeometryType() LIKE ''%Point'''
					SET @params = '@I1 geometry'
					EXEC sp_executesql @sqlcommand, @params,
						@I1 = @PartnerGeom
						WITH RESULT SETS NONE

					Set @RecCnt = @@ROWCOUNT

					-- Select polygons (using their centroids) that intersect the partner
					SET @sqlcommand = 
						'INSERT INTO ' + @Schema + '.' + @TempTable +
						' SELECT Spp.*' +
						' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
						' WHERE Spp.' + @SpatialColumn + '.STCentroid().STIntersects(@I1) = 1' +
						' AND ' + @SpatialColumn + '.STGeometryType() LIKE ''%Polygon'''
					SET @params = '@I1 geometry'
					EXEC sp_executesql @sqlcommand, @params,
						@I1 = @PartnerGeom
						WITH RESULT SETS NONE

					Set @RecCnt = @RecCnt  + @@ROWCOUNT

				END
			
			END
			ELSE
			BEGIN
		
				-- Select ALL points and polygons
				SET @sqlcommand = 
					'INSERT INTO ' + @Schema + '.' + @TempTable +
					' SELECT Spp.*' +
					' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp'
				EXEC (@sqlcommand)
				WITH RESULT SETS NONE

				Set @RecCnt = @@ROWCOUNT

			END

		END
	
		If (@SelectType = 2 OR @SelectType = 3) AND REPLACE(@PartnerTags, '''', '') <> ''
		BEGIN
	
			If @debug = 1
				PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Performing tags selection ...'

			-- Select all points and polygons that match the partner's survey tags
			SET @sqlcommand = 
				'INSERT INTO ' + @Schema + '.' + @TempTable +
				' SELECT Spp.*' +
				' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
				' INNER JOIN #TagsTable As Tags ON Tags.SurveyKey = Spp.' + @SurveyKeyColumn +
				' WHERE Tags.TagFound = 1' +
				' AND NOT EXISTS (SELECT ' + @PrimaryKey + ' FROM ' + @Schema + '.' + @TempTable + ' Tmp WHERE Tmp.' + @PrimaryKey + ' = Spp.' + @PrimaryKey + ')'
			EXEC (@sqlcommand)
			WITH RESULT SETS NONE

			Set @RecCnt = @RecCnt  + @@ROWCOUNT

		END
	
		/*---------------------------------------------------------------------------*\
			Report the number of records selected
		\*---------------------------------------------------------------------------*/

		IF @RecCnt = 0
		BEGIN

			If @debug = 1
				PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'No temporary records inserted.'

		END
		ELSE
		BEGIN

			If @debug = 1
				PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + Cast(@RecCnt As varchar) + ' records selected ...'

		END

		/*---------------------------------------------------------------------------*\
			Drop any temporary tables no longer required
		\*---------------------------------------------------------------------------*/

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
			SET @sqlcommand = 'EXECUTE ' + @Schema + '.AFUpdateMICatalog ''' + @Schema + ''', ''' + @TempTable + ''', ''' + @XColumn + ''', ''' + @YColumn +
				''', ''' + @SizeColumn + ''', ''' + @SpatialColumn + ''', ''' + @CoordSystem + ''', ''' + Cast(@RecCnt As varchar) + ''', ''' + Cast(@IsSpatial As varchar) + ''''
			EXEC (@sqlcommand)
			WITH RESULT SETS NONE
		END

	END

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Ended.'

END
GO
