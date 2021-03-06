USE [NBNData_TVERC]
GO
/****** Object:  StoredProcedure [dbo].[HLSelectSppSubset]    Script Date: 10/08/2017 16:34:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Create the stored procedure
ALTER PROCEDURE [dbo].[HLSelectSppSubset]
	@Schema varchar(50),
	@SpeciesTable varchar(50),
	@SpatialColumn varchar(50),
	@ColumnNames varchar(2000),
	@WhereClause varchar(2000),
	@GroupByClause varchar(2000),
	@OrderByClause varchar(2000),
	@UserId varchar(50),
	@Split bit
AS
BEGIN
	--- This version of the script relies on @Split and @SpatialColumn to give the information about whether the 
	--- input table is spatial or not. Hester Lyons, 09/08/2017.
	--- It expects a temporary table as input, which is why the details are not in Spatial_Tables.

	SET NOCOUNT ON

	If @Schema = ''
		SET @Schema = 'dbo'
	If @ColumnNames = ''
		SET @ColumnNames = '*'
	If @WhereClause IS NULL
		SET @WhereClause = 0
	If @GroupByClause IS NULL
		SET @GroupByClause = 0
	If @OrderByClause IS NULL
		SET @OrderByClause = 0
	IF @UserId IS NULL
		SET @UserId = 'temp'
	If @Split IS NULL
		SET @Split = 0

	DECLARE @FromClause varchar(2000)
	SET @FromClause = ''

	DECLARE @debug int
	Set @debug = 1

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Started.'

	DECLARE @sqlCommand nvarchar(4000)
	DECLARE @params nvarchar(4000)
	DECLARE @RecCnt Int
	DECLARE @TempTable varchar(50)

	-- Lookup table column names and spatial variables from Spatial_Tables
	--DECLARE @IsSpatial bit
	--DECLARE @XColumn varchar(32), @YColumn varchar(32), @SizeColumn varchar(32), @SpatialColumn varchar(32)
	--DECLARE @CoordSystem varchar(254)
	
	--If @debug = 1
	--	PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Retrieving table spatial details ...'

	--DECLARE @SpatialTable varchar(100)
	--SET @SpatialTable ='Spatial_Tables'

	---- Retrieve the table column names and spatial variables
	--SET @sqlcommand = 'SELECT @O1 = XColumn, ' +
	--						 '@O2 = YColumn, ' +
	--						 '@O3 = SizeColumn, ' +
	--						 '@O4 = IsSpatial, ' +
	--						 '@O5 = SpatialColumn, ' +
	--						 '@O6 = CoordSystem ' +
	--					'FROM ' + @Schema + '.' + @SpatialTable + ' ' +
	--					'WHERE TableName = ''' + @SpeciesTable + ''' AND OwnerName = ''' + @Schema + ''''
	----print @sqlcommand
	--SET @params =	'@O1 varchar(32) OUTPUT, ' +
	--				'@O2 varchar(32) OUTPUT, ' +
	--				'@O3 varchar(32) OUTPUT, ' +
	--				'@O4 bit OUTPUT, ' +
	--				'@O5 varchar(32) OUTPUT, ' +
	--				'@O6 varchar(254) OUTPUT'
		
	--EXEC sp_executesql @sqlcommand, @params,
	--	@O1 = @XColumn OUTPUT, @O2 = @YColumn OUTPUT, @O3 = @SizeColumn OUTPUT, @O4 = @IsSpatial OUTPUT, 
	--	@O5 = @SpatialColumn OUTPUT, @O6 = @CoordSystem OUTPUT
		
	If @Split = 1 -- @IsSpatial = 1
	BEGIN
		IF @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Table is spatial'

		If @WhereClause = ''
			SET @WhereClause = 'Spp.' + @SpatialColumn + ' IS NOT NULL'
		Else
			SET @WhereClause = @WhereClause + ' AND Spp.' + @SpatialColumn + ' IS NOT NULL'
	END

	If @GroupByClause <> ''
		SET @GroupByClause = ' GROUP BY ' + @GroupByClause

	If @OrderByClause <> ''
		SET @OrderByClause = ' ORDER BY ' + @OrderByClause

	If @WhereClause <> '' AND @WhereClause NOT LIKE 'FROM %'
	BEGIN
		SET @FromClause = ' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp'
		SET @WhereClause = ' WHERE (' + @WhereClause + ')'
	END
	ELSE
	BEGIN
		SET @WhereClause = REPLACE(@WhereClause, ' WHERE ', ' WHERE (') + ')'
	END

	If @Split = 1 -- AND @IsSpatial = 1 -- this has already been checked by the C# code.
	BEGIN

		SET @TempTable = @SpeciesTable + '_point' -- + @UserId -- UserID is already part of the table name.

		-- Drop the points temporary table if it already exists
		If EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @Schema AND TABLE_NAME = @TempTable)
		BEGIN
			If @debug = 1
				PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Dropping temporary point table ...'
			SET @sqlcommand = 'DROP TABLE ' + @Schema + '.' + @TempTable
			EXEC (@sqlcommand)
		END

		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Performing point selection ...'

		-- Select the species records into the points temporary table
		SET @sqlcommand = 
			'SELECT ' + @ColumnNames +
			' INTO ' + @Schema + '.' + @TempTable + ' ' +
			@FromClause +
			@WhereClause + ' AND ' + @SpatialColumn + '.STGeometryType() LIKE ''%Point''' +
			@GroupByClause +
			@OrderByClause
		
		print CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'SQL command is: ' +  @sqlcommand
		EXEC (@sqlcommand)

		Set @RecCnt = @@ROWCOUNT

		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + Cast(@RecCnt As varchar) + ' point records selected ...'


		SET @TempTable = @SpeciesTable + '_poly' -- + @UserId -- UserID is already part of the temporary table name.

		-- Drop the polygons temporary table if it already exists
		If EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @Schema AND TABLE_NAME = @TempTable)
		BEGIN
			If @debug = 1
				PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Dropping temporary polygon table ...'
			SET @sqlcommand = 'DROP TABLE ' + @Schema + '.' + @TempTable
			EXEC (@sqlcommand)
		END

		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Performing polygon selection ...'

		-- Select the species records into the polygons temporary table
		SET @sqlcommand = 
			'SELECT ' + @ColumnNames +
			' INTO ' + @Schema + '.' + @TempTable + ' ' +
			@FromClause +
			@WhereClause + ' AND ' + @SpatialColumn + '.STGeometryType() LIKE ''%Polygon''' +
			@GroupByClause +
			@OrderByClause
		EXEC (@sqlcommand)

		Set @RecCnt = @@ROWCOUNT

		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + Cast(@RecCnt As varchar) + ' polygon records selected ...'


	END
	ELSE
	BEGIN

		SET @TempTable = @SpeciesTable + '_flat' -- + @UserId -- UserID is already part of the table name.

		-- Drop the temporary table if it already exists
		If EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @Schema AND TABLE_NAME = @TempTable)
		BEGIN
			If @debug = 1
				PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Dropping temporary table ...'
			SET @sqlcommand = 'DROP TABLE ' + @Schema + '.' + @TempTable
			EXEC (@sqlcommand)
		END

		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Performing selection ...'

		-- Select the species records into the temporary table
		SET @sqlcommand = 
			'SELECT ' + @ColumnNames +
			' INTO ' + @Schema + '.' + @TempTable + ' ' +
			@FromClause +
			@WhereClause +
			@GroupByClause +
			@OrderByClause
		EXEC (@sqlcommand)

		Set @RecCnt = @@ROWCOUNT

		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + Cast(@RecCnt As varchar) + ' records selected ...'


	END

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Ended.'

END
