/*===========================================================================*\
  HLSelectSppRecords is a SQL stored procedure to create an intermediate
  SQL Server table containing a subset of records based on their spatial
  intersection with a given record in another table.
  
  Copyright © 2017 Hester Lyons Consulting & Andy Foy Consulting
  
  This file is used by the 'DataExtractor' tool, versions of which are
  available for MapInfo and ArcGIS.
  
  HLSelectSppRecords is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.
  
  HLSelectSppRecords is distributed in the hope that it will be useful,
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
If EXISTS (SELECT ROUTINE_NAME FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_SCHEMA = 'dbo' AND ROUTINE_NAME = 'HLSelectSppRecords')
	DROP PROCEDURE dbo.HLSelectSppRecords
GO

-- Create the stored procedure
CREATE PROCEDURE dbo.HLSelectSppRecords
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

  Created:			Aug 2017
  Last revised: 	Aug 2017

 *****************  Version 2  *****************
 Author: Andy Foy			Date: 14/08/2017
 A. Force temporary tables to collate using the
	current database standard.
 B. Simplify (reduce) partner geometry slightly
	to speed up spatial selection.
 C. Remove split parameter as no longer needed.

 *****************  Version 1  *****************
 Author: Hester Lyons		Date: 11/08/2017
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

	DECLARE @TempTable varchar(50)
	SET @TempTable = @SpeciesTable + '_' + @UserId

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
	If EXISTS (SELECT column_name FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE WHERE TABLE_SCHEMA = @Schema AND TABLE_NAME = @TempTable AND COLUMN_NAME = 'RecOccKey' AND CONSTRAINT_NAME = 'PK_' + @TempTable + '_INX')
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

	If @IsSpatial = 1
	BEGIN
		If @debug = 1
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
		' RecOccKey char(16) NOT NULL,' +
		' CONSTRAINT PK_' + @TempTable + '_INX_IX PRIMARY KEY (RecOccKey)' +
		' )'

	EXEC (@sqlcommand)

	If @SelectType = 1 AND @IsSpatial = 1 AND @PartnerGeom IS NOT NULL
	BEGIN
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Performing spatial selection only ...'

		SET @sqlcommand = 
			'INSERT INTO ' + @Schema + '.' + @TempTable + '_INX' +
			' SELECT Spp.RecOccKey' + 
			' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
			' WHERE Spp.' + @SpatialColumn + '.STIntersects(@I1) = 1'
			--' ORDER BY Spp.RecOccKey'

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
			' INNER JOIN ' + @Schema + '.' + @TempTable + '_INX As Keys ON Keys.RecOccKey = Spp.RecOccKey'

		EXEC (@sqlcommand)

	END
	ELSE
	BEGIN
		If (@SelectType = 2 AND @PartnerTags <> '') Or (@SelectType = 3 AND @PartnerGeom IS NULL)
		BEGIN
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
				PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Performing spatial and tags selection ...'

				SET @sqlcommand = 
					'INSERT INTO ' + @Schema + '.' + @TempTable + '_INX' +
					' SELECT Spp.RecOccKey' + 
					' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
					' INNER JOIN #TagsTable As Tags ON Tags.SurveyKey = Spp.' + @SurveyKeyColumn +
					' WHERE Tags.TagFound = 1' +
					' UNION' +
					' SELECT Spp.RecOccKey' + 
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
					' INNER JOIN ' + @Schema + '.' + @TempTable + '_INX As Keys ON Keys.RecOccKey = Spp.RecOccKey'

				EXEC (@sqlcommand)

			END
			ELSE
			BEGIN
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
	IF OBJECT_ID('tempdb..#TagsTable') IS NOT NULL
		DROP TABLE #TagsTable


	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Ended.'

END
GO
