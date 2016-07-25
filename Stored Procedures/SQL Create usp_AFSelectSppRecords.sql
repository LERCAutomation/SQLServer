/*===========================================================================*\
  AFSelectSppRecords is a SQL stored procedure to create an intermediate
  SQL Server table containing a subset of records based on their spatial
  intersection with a given record in another table.
  
  Copyright © 2012-2013, 2015 Andy Foy Consulting
  
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

/*===========================================================================*\
  Description:		Select species records that intersect with the partner
					polygon(s) passed by the calling routine.

  Parameters:
	@Schema			The schema for the partner and species table.
	@PartnerTable	The name of the partner table used for selecting.
	@PartnerColumn	The name of the column containing the partner to be used.
	@Partner		The partner to be used for selecting.
	@TagsColumn		The name of the column containing the survey tags to check.
	@SelectType		Whether the selection is based on the partner's spatial
					boundary, survey tags or both.
	@SpeciesTable	The name of the table containing the species records.
	@UserId			The userid of the user executing the selection.

  Created:			Nov 2012
  Last revised: 	Jul 2016

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
	@SelectType int,
	@SpeciesTable varchar(50),
	@UserId varchar(50)
AS
BEGIN

	SET NOCOUNT ON

	IF @UserId IS NULL
		SET @UserId = 'temp'

	DECLARE @debug int
	Set @debug = 0

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Started.'

	DECLARE @sqlCommand nvarchar(2000)
	DECLARE @params nvarchar(2000)

	DECLARE @TempTable varchar(50)
	SET @TempTable = @SpeciesTable + '_' + @UserId

	-- Drop the index on the sequential primary key of the temporary table if it already exists
	If EXISTS (SELECT column_name FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE WHERE TABLE_SCHEMA = @Schema AND TABLE_NAME = @TempTable AND COLUMN_NAME = 'MI_PRINX' AND CONSTRAINT_NAME = 'PK_' + @TempTable + '_MI_PRINX')
	BEGIN
		SET @sqlcommand = 'ALTER TABLE ' + @Schema + '.' + @TempTable +
			' DROP CONSTRAINT PK_' + @TempTable + '_MI_PRINX'
		EXEC (@sqlcommand)
	END
	
	-- Drop the temporary table if it already exists
	If EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @Schema AND TABLE_NAME = @TempTable)
	BEGIN
		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Dropping temporary table ...'
		SET @sqlcommand = 'DROP TABLE ' + @Schema + '.' + @TempTable
		EXEC (@sqlcommand)
	END

	-- Drop the index on the sequential primary key of the temporary index table if it already exists
	If EXISTS (SELECT column_name FROM INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE WHERE TABLE_SCHEMA = @Schema AND TABLE_NAME = @TempTable AND COLUMN_NAME = 'MI_PRINX' AND CONSTRAINT_NAME = 'PK_' + @TempTable + '_MI_PRINX')
	BEGIN
		SET @sqlcommand = 'ALTER TABLE ' + @Schema + '.' + @TempTable + '_PRINX' +
			' DROP CONSTRAINT PK_' + @TempTable + '_PRINX_PRINX'
		EXEC (@sqlcommand)
	END
	
	-- Drop the temporary index table if it already exists
	If EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @Schema AND TABLE_NAME = @TempTable + '_PRINX')
	BEGIN
		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Dropping temporary index table ...'
		SET @sqlcommand = 'DROP TABLE ' + @Schema + '.' + @TempTable + '_PRINX'
		EXEC (@sqlcommand)
	END


	SET @sqlcommand = 'CREATE TABLE ' + @Schema + '.' + @TempTable + '_PRINX (' +
		' MI_PRINX int NOT NULL,' +
		' CONSTRAINT PK_' + @TempTable + '_PRINX_PRINX PRIMARY KEY (MI_PRINX)' +
		' )'
	-- Lookup survey tags and spatial geometry variables from Partner table
	DECLARE @PartnerGeom geometry
	DECLARE @PartnerTags varchar(254)

	-- Retrieve the variables from the partner table
	SET @sqlcommand = 'SELECT @O1 = SP_GEOMETRY,' +
							 '@O2 = ' + @TagsColumn +
					  ' FROM ' + @Schema + '.' + @PartnerTable +
					  ' WHERE ' + @PartnerColumn + ' = ''' + @Partner + ''''

	SET @params =	'@O1 geometry OUTPUT, ' +
					'@O2 varchar(254) OUTPUT'
		
	EXEC sp_executesql @sqlcommand, @params,
		@O1 = @PartnerGeom OUTPUT, @O2 = @PartnerTags OUTPUT
	
	If @PartnerTags IS NULL
		SET @PartnerTags = ''
	
	CREATE TABLE #TagsTable
	(
		SurveyKey char(16) NOT NULL,
		TagFound int NOT NULL
	)

	INSERT INTO #TagsTable (SurveyKey, TagFound)
	SELECT SURVEY_KEY, dbo.AFSurveyTagFound(SURVEY_KEY, @PartnerTags)
	FROM SURVEY
	
	-- Lookup table column names and spatial variables from Spatial_Tables
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
		
	-- Check if the table is spatially enabled
	If @IsSpatial = 1
	BEGIN
		IF @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Table is spatial.'
	END

	-- Select the species records into the temporary table
	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Performing selection for partner = ' + @Partner + ' ...'

	SET @sqlcommand = 'CREATE TABLE ' + @Schema + '.' + @TempTable + '_PRINX (' +
		' MI_PRINX int NOT NULL,' +
		' CONSTRAINT PK_' + @TempTable + '_PRINX_PRINX PRIMARY KEY (MI_PRINX)' +
		' )'
	EXEC (@sqlcommand)

	If @SelectType = 1 AND @IsSpatial = 1 AND @PartnerGeom IS NOT NULL
	BEGIN
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Performing spatial selection only ...'

		SET @sqlcommand = 
			'INSERT INTO ' + @Schema + '.' + @TempTable + '_PRINX' +
			' SELECT Spp.MI_PRINX' + 
			' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
			' WHERE Spp.' + @SpatialColumn + '.STIntersects(@I1) = 1' +
			' ORDER BY Spp.MI_PRINX'

			SET @params = '@I1 geometry'

			EXEC sp_executesql @sqlcommand, @params,
				@I1 = @PartnerGeom

		SET @sqlcommand = 
			'SELECT Spp.*' + 
			' INTO ' + @Schema + '.' + @TempTable +
			' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
			' INNER JOIN ' + @Schema + '.' + @TempTable + '_PRINX As Keys ON Keys.MI_PRINX = Spp.MI_PRINX'

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
					'INSERT INTO ' + @Schema + '.' + @TempTable + '_PRINX' +
					' SELECT Spp.MI_PRINX' + 
					' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
					' INNER JOIN #TagsTable As Tags ON Tags.SurveyKey = Spp.' + @SurveyKeyColumn +
					' WHERE Tags.TagFound = 1' +
					' UNION' +
					' SELECT Spp.MI_PRINX' + 
					' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
					' WHERE Spp.' + @SpatialColumn + '.STIntersects(@I1) = 1'

				SET @params = '@I1 geometry'

				EXEC sp_executesql @sqlcommand, @params,
					@I1 = @PartnerGeom

				SET @sqlcommand = 
					'SELECT Spp.*' + 
					' INTO ' + @Schema + '.' + @TempTable +
					' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
					' INNER JOIN ' + @Schema + '.' + @TempTable + '_PRINX As Keys ON Keys.MI_PRINX = Spp.MI_PRINX'

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

	DECLARE @RecCnt Int
	Set @RecCnt = @@ROWCOUNT

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + Cast(@RecCnt As varchar) + ' records selected ...'

	SET @sqlcommand = 'DROP TABLE ' + @Schema + '.' + @TempTable + '_PRINX'
	EXEC (@sqlcommand)

	DROP TABLE #TagsTable

	-- If the MapInfo MapCatalog exists then update it
	IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'MAPINFO' AND TABLE_NAME = 'MAPINFO_MAPCATALOG')
	BEGIN

		-- Delete the MapInfo MapCatalog entry if it already exists
		IF EXISTS (SELECT TABLENAME FROM [MAPINFO].[MAPINFO_MAPCATALOG] WHERE TABLENAME = @TempTable)
		BEGIN
			IF @debug = 1
				PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Deleting the MapInfo MapCatalog entry ...'
			
			SET @sqlcommand = 'DELETE FROM [MAPINFO].[MAPINFO_MAPCATALOG]' +
				' WHERE TABLENAME = ''' + @TempTable + ''''
			EXEC (@sqlcommand)
		END

		-- Calculate the geometric extent of the records (plus their precision)
		DECLARE @X1 int, @X2 int, @Y1 int, @Y2 int

		SET @X1 = 0
		SET @X2 = 0
		SET @Y1 = 0
		SET @Y2 = 0

		-- Check if the table is spatial and the necessary columns are in the table (including a geometry column)
		IF  @IsSpatial = 1
		AND EXISTS(SELECT * FROM sys.columns WHERE Name = @XColumn AND Object_ID = Object_ID(@TempTable))
		AND EXISTS(SELECT * FROM sys.columns WHERE Name = @YColumn AND Object_ID = Object_ID(@TempTable))
		AND EXISTS(SELECT * FROM sys.columns WHERE Name = @SizeColumn AND Object_ID = Object_ID(@TempTable))
		AND EXISTS(SELECT * FROM sys.columns WHERE Name = @SpatialColumn AND Object_ID = Object_ID(@TempTable))
		AND EXISTS(SELECT * FROM sys.columns WHERE user_type_id = 129 AND Object_ID = Object_ID(@TempTable))
		BEGIN

			IF @debug = 1
				PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Determining spatial extent ...'

			-- Retrieve the geometric extent values and store as variables
			SET @sqlcommand = 'SELECT @xMin = MIN(' + @XColumn + '), ' +
									 '@yMin = MIN(' + @YColumn + '), ' +
									 '@xMax = MAX(' + @XColumn + ') + MAX(' + @SizeColumn + '), ' +
									 '@yMax = MAX(' + @YColumn + ') + MAX(' + @SizeColumn + ') ' +
									 'FROM ' + @Schema + '.' + @TempTable

			SET @params =	'@xMin int OUTPUT, ' +
							'@yMin int OUTPUT, ' +
							'@xMax int OUTPUT, ' +
							'@yMax int OUTPUT'
		
			EXEC sp_executesql @sqlcommand, @params,
				@xMin = @X1 OUTPUT, @yMin = @Y1 OUTPUT, @xMax = @X2 OUTPUT, @yMax = @Y2 OUTPUT
		
			If @debug = 1
				PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Inserting the MapInfo MapCatalog entry ...'

			-- Check if the rendition column is in the table
			IF NOT EXISTS(SELECT * FROM sys.columns WHERE Name = N'MI_STYLE' AND Object_ID = Object_ID(@TempTable))
			BEGIN
				SET @sqlcommand = 'ALTER TABLE ' + @TempTable + ' ADD MI_STYLE varchar(254) NULL'
				EXEC (@sqlcommand)
			END
			
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
				,@TempTable
				,@Schema
				,@SpatialColumn
				,@X1
				,@Y1
				,@X2
				,@Y2
				,@CoordSystem
				,'Pen (1,2,0)  Brush (1,16777215,16777215)'
				,NULL
				,NULL
				,NULL
				,'MI_STYLE'
				,NULL
				,@RecCnt
				,NULL
				,NULL
				,NULL
				,NULL)
		END
		ELSE
		BEGIN

			IF @debug = 1
				PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Table is non-spatial or required columns are missing.'

		END

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
