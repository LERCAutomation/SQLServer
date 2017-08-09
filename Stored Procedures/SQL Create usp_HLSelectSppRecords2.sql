USE [NBNData_TVERC]
GO
/****** Object:  StoredProcedure [dbo].[HLSelectSppRecords2]    Script Date: 09/08/2017 12:22:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Create the stored procedure
ALTER PROCEDURE [dbo].[HLSelectSppRecords2]
	@Schema varchar(50),
	@PartnerTable varchar(50),
	@PartnerColumn varchar(50),
	@Partner varchar(50),
	@TagsColumn varchar(50),
	@PartnerSpatialColumn varchar(50),
	@SelectType int,
	@SpeciesTable varchar(50),
	@UserId varchar(50),
	@Split bit
AS
BEGIN

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

	DECLARE @TempTable varchar(50)
	SET @TempTable = @SpeciesTable + '_' + @UserId

	/*---------------------------------------------------------------------------*\
		Drop any existing temporary tables
	\*---------------------------------------------------------------------------*/

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

	/*---------------------------------------------------------------------------*\
		Lookup survey tags and spatial geometry variables from Partner table
	\*---------------------------------------------------------------------------*/

	DECLARE @PartnerGeom geometry
	DECLARE @PartnerTags varchar(254)

	DECLARE @TempTableHL varchar(50) --HL
	SET @TempTableHL = 'PartnerGeometry_' + @UserId --HL

	-- Drop the temporary HL table if it already exists
	If EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @Schema AND TABLE_NAME = @TempTableHL)
	BEGIN
		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Dropping temporary table ...'
		SET @sqlcommand = 'DROP TABLE ' + @Schema + '.' + @TempTableHL
		EXEC (@sqlcommand)
	END

	-- Retrieve the variables from the partner table into a new table 
	-- New command: HL>
	SET @sqlcommand = 'SELECT ' + @Schema + '.' + @PartnerTable + '.* '
		SET @sqlcommand = @sqlcommand + 'INTO ' + @Schema + '.' + @TempTableHL + ' '
		SET @sqlcommand = @sqlcommand + 'FROM ' + @Schema + '.' + @PartnerTable + ' '
		SET @sqlcommand = @sqlcommand + 'WHERE ' +@PartnerColumn + ' = ''' + @Partner + ''''

		SET @params = '@O1 geometry OUTPUT, ' + 
					  '@O2 varchar(254) OUTPUT'

		IF @debug = 1
			PRINT @sqlcommand
		EXEC(@sqlcommand)

		-- Create a spatial index on this temporary table.
		If exists (select TABLE_NAME from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = @Schema and TABLE_NAME = @TempTableHL)
		BEGIN
			SET @sqlcommand = 'ALTER TABLE ' + @Schema + '.' + @TempTableHL + ' ALTER COLUMN ' + @PartnerColumn + ' VARCHAR(150) NOT NULL'
			PRINT @sqlcommand
			EXEC(@sqlcommand)

			SET @sqlcommand = 'ALTER TABLE ' + @Schema + '.' + @TempTableHL + ' ADD CONSTRAINT [' + @TempTableHL + '_INX' + 
							  '] PRIMARY KEY CLUSTERED ' 
			SET @sqlcommand = @sqlcommand + '(' + @PartnerColumn + ' ASC)' 
			PRINT @sqlcommand
			EXEC(@sqlcommand)

			SET @sqlcommand = 'CREATE SPATIAL INDEX ' + @TempTableHL + '_SpatialIndex ' 
			SET @sqlcommand = @sqlcommand + 'ON ' + @TempTableHL + '(' + @PartnerSpatialColumn + ') '
			
			SET @sqlcommand = @sqlcommand + 'WITH ( BOUNDING_BOX = (xmin=-180, ymin=-90, xmax=180, ymax=90) )' -- whole world
			
			PRINT @sqlcommand
			EXEC(@sqlcommand)

		END


	-- Retrieve some output from this.
	SET @sqlcommand = 'SELECT @O1 = SP_GEOMETRY,' +
							 '@O2 = ' + @TagsColumn +
					  ' FROM ' + @Schema + '.' + @PartnerTable +
					  ' WHERE ' + @PartnerColumn + ' = ''' + @Partner + ''''

	SET @params =	'@O1 geometry OUTPUT, ' +
					'@O2 varchar(254) OUTPUT'
		
	EXEC sp_executesql @sqlcommand, @params,
		@O1 = @PartnerGeom OUTPUT, @O2 = @PartnerTags OUTPUT -- Output is used to test if geometry is empty.
	
	/*---------------------------------------------------------------------------*\
		Create a temporary survey tags table (if required)
	\*---------------------------------------------------------------------------*/

	If @SelectType <> 1
	BEGIN
		PRINT @PartnerTags + ' 1'
		If @PartnerTags IS NULL
			SET @PartnerTags = ''
	
		CREATE TABLE #TagsTable
		(
			SurveyKey char(16) NOT NULL,
			TagFound int NOT NULL
		)
		PRINT @PartnerTags + ' 2'

		INSERT INTO #TagsTable (SurveyKey, TagFound)
		SELECT SURVEY_KEY, dbo.AFSurveyTagFound(SURVEY_KEY, @PartnerTags) -- This fails.
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
		Report if the table is spatially enabled
	\*---------------------------------------------------------------------------*/

	If @IsSpatial = 1 AND @Split = 1
	BEGIN
		IF @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Table is spatial.'
		ELSE
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Table is not spatial.'
	END

	/*---------------------------------------------------------------------------*\
		Select the species record primary keys into a temporary table
	\*---------------------------------------------------------------------------*/

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Performing selection for partner = ' + @Partner + ' ...'

	-- Create a temporary index table
	SET @sqlcommand = 'CREATE TABLE ' + @Schema + '.' + @TempTable + '_PRINX (' +
		' MI_PRINX int NOT NULL,' +
		' CONSTRAINT PK_' + @TempTable + '_PRINX_PRINX PRIMARY KEY (MI_PRINX)' +
		' )'
	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Creating temporary table ' + @Schema + '.' + @TempTable + '_PRINX'
	EXEC (@sqlcommand)

	if @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'SelectType =  ' + CONVERT(VARCHAR(32), @SelectType, 109 ) 
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'IsSpatial = ' + CONVERT(VARCHAR(32), @IsSpatial,109) 
		IF @PartnerGeom IS NOT NULL
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'PartnerGeom is not null'
		ELSE
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'PartnerGeom is null'

	If @SelectType = 1 AND @IsSpatial = 1 AND @PartnerGeom IS NOT NULL
	BEGIN
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Performing spatial selection only ...'

		--SET @sqlcommand = 
		--	'INSERT INTO ' + @Schema + '.' + @TempTable + '_PRINX' +
		--	' SELECT Spp.MI_PRINX' + 
		--	' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
		--	' WHERE Spp.' + @SpatialColumn + '.STIntersects(@I1) = 1' +
		--	' ORDER BY Spp.MI_PRINX'

		--	SET @params = '@I1 geometry'

		--	EXEC sp_executesql @sqlcommand, @params,
		--		@I1 = @PartnerGeom

		--SET @sqlcommand = 
		--	'SELECT Spp.*' + 
		--	' INTO ' + @Schema + '.' + @TempTable +
		--	' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
		--	' INNER JOIN ' + @Schema + '.' + @TempTable + '_PRINX As Keys ON Keys.MI_PRINX = Spp.MI_PRINX'

		SET @sqlcommand = 'SELECT ' + @Schema + '.' + @SpeciesTable + '.* '
		SET @sqlcommand = @sqlcommand + 'into ' + @Schema + '.' + @TempTable + ' '
		SET @sqlcommand = @sqlcommand + 'from ' + @Schema + '.' + @SpeciesTable + ' '
		SET @sqlcommand = @sqlcommand + 'join ' + @Schema + '.' + @TempTableHL + ' '
		SET @sqlcommand = @sqlcommand + 'on ' + @SpeciesTable + '.' + @SpatialColumn + '.STIntersects(' + 
		 @TempTableHL + '.' + @PartnerSpatialColumn + ') = 1 '
		PRINT @sqlcommand

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

				--SET @sqlcommand = 
				--	'INSERT INTO ' + @Schema + '.' + @TempTable + '_PRINX' +
				--	' SELECT Spp.MI_PRINX' + 
				--	' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
				--	' INNER JOIN #TagsTable As Tags ON Tags.SurveyKey = Spp.' + @SurveyKeyColumn +
				--	' WHERE Tags.TagFound = 1' +
				--	' UNION' +
				--	' SELECT Spp.MI_PRINX' + 
				--	' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
				--	' WHERE Spp.' + @SpatialColumn + '.STIntersects(@I1) = 1'

				--SET @params = '@I1 geometry'

				--EXEC sp_executesql @sqlcommand, @params,
				--	@I1 = @PartnerGeom

				--SET @sqlcommand = 
				--	'SELECT Spp.*' + 
				--	' INTO ' + @Schema + '.' + @TempTable +
				--	' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
				--	' INNER JOIN ' + @Schema + '.' + @TempTable + '_PRINX As Keys ON Keys.MI_PRINX = Spp.MI_PRINX'

				SET @sqlcommand = 'SELECT ' + @Schema + '.' + @SpeciesTable + '.* '
				SET @sqlcommand = @sqlcommand + 'into ' + @Schema + '.' + @TempTable + ' '
				SET @sqlcommand = @sqlcommand + 'from ' + @Schema + '.' + @SpeciesTable + ' '
				SET @sqlcommand = @sqlcommand + 'join ' + @Schema + '.' + @TempTableHL + ' '
				SET @sqlcommand = @sqlcommand + 'on ' + @SpeciesTable + '.' + @SpatialColumn + '.STIntersects(' + 
									@TempTableHL + '.' + @PartnerSpatialColumn + ') = 1 ' 
				SET @sqlcommand = @sqlcommand + 'UNION  SELECT Spp.* FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp '
				SET @sqlcommand = @sqlcommand + 'INNER JOIN #TagsTable as Tags ON Tags.SurveyKey = Spp.' + @SurveyKeyColumn + ' '
				SET @sqlcommand = @sqlcommand + 'WHERE Tags.TagFound = 1'
				PRINT @sqlcommand


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

	DECLARE @RecCnt Int
	Set @RecCnt = @@ROWCOUNT

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + Cast(@RecCnt As varchar) + ' records selected ...'

	/*---------------------------------------------------------------------------*\
		Drop any temporary tables no longer required
	\*---------------------------------------------------------------------------*/

	-- Drop the temporary index table
	SET @sqlcommand = 'DROP TABLE ' + @Schema + '.' + @TempTable + '_PRINX'
	EXEC (@sqlcommand)

	-- Drop the temporary survey tags table (if it exists)
	IF OBJECT_ID('tempdb..#TagsTable') IS NOT NULL
		DROP TABLE #TagsTable

	/*---------------------------------------------------------------------------*\
		Update the MapInfo MapCatalog if it exists
	\*---------------------------------------------------------------------------*/

	-- Update the MapInfo MapCatalog entry
	--SET @sqlcommand = 'EXECUTE dbo.AFUpdateMICatalog ''' + @Schema + ''', ''' + @TempTable + ''', ''' + @XColumn + ''', ''' + @YColumn +
	--	''', ''' + @SizeColumn + ''', ''' + @SpatialColumn + ''', ''' + @CoordSystem + ''', ''' + Cast(@RecCnt As varchar) + ''', ''' + Cast(@IsSpatial As varchar) + ''''
	--EXEC (@sqlcommand)


	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Ended.'

END
