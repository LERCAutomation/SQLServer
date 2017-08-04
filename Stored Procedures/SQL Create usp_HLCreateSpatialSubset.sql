USE [NBNData_TVERC]
GO
/****** Object:  StoredProcedure [dbo].[HLCreateSpatialSubset]    Script Date: 04/08/2017 07:05:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[HLCreateSpatialSubset] 
	@Schema VARCHAR(50),
	@InputTable1 VARCHAR(50),
	@Input1GeometryField VARCHAR(50),
	@InputTable2 VARCHAR(50),
	@Input2GeometryField VARCHAR(50),
	@Input2Clause VARCHAR(200),
	--@Input2IndexField VARCHAR(50),
	@BoundaryTableName VARCHAR(50),
	@OutputTableName VARCHAR(50)

AS
BEGIN
	DECLARE @debug int = 1

	DECLARE @TempTable1 varchar(50)
	SET @TempTable1 = @BoundaryTableName
	DECLARE @TempTable2 varchar(50)
	SET @TempTable2 = @OutputTableName
	DECLARE @sqlcommand varchar(500)

	-- Drop the temporary table 1 if it already exists
	If exists (select TABLE_NAME from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = @Schema and TABLE_NAME = @TempTable1)
	BEGIN
		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Dropping temporary table ...'
		SET @sqlcommand = 'DROP TABLE ' + @Schema + '.' + @TempTable1
		EXEC (@sqlcommand)
	END

	-- Drop the temporary table 2 if it already exists
	If exists (select TABLE_NAME from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = @Schema and TABLE_NAME = @TempTable2)
	BEGIN
		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Dropping temporary table ...'
		SET @sqlcommand = 'DROP TABLE ' + @Schema + '.' + @TempTable2
		EXEC (@sqlcommand)
	END

	-- Select the required boundary.
	BEGIN
		SET @sqlcommand = 'SELECT ' + @Schema + '.' + @InputTable2 + '.* '
		SET @sqlcommand = @sqlcommand + 'INTO ' + @Schema + '.' + @TempTable1 + ' '
		SET @sqlcommand = @sqlcommand + 'FROM ' + @Schema + '.' + @InputTable2 + ' '
		SET @sqlcommand = @sqlcommand + 'WHERE ' + @Input2Clause

		IF @debug = 1
			PRINT @sqlcommand
		EXEC(@sqlcommand)

		-- Create a spatial index.
		--If exists (select TABLE_NAME from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = @Schema and TABLE_NAME = @TempTable1)
		--BEGIN
			--SET @sqlcommand = 'ALTER TABLE ' + @Schema + '.' + @TempTable1 + ' ALTER COLUMN Partnername VARCHAR(150) NOT NULL'
			--PRINT @sqlcommand
			--EXEC(@sqlcommand)
			--SET @sqlcommand = 'ALTER TABLE ' + @Schema + '.' + @TempTable1 + ' ALTER COLUMN ShortName VARCHAR(4) NOT NULL'
			--PRINT @sqlcommand
			--EXEC(@sqlcommand)
			--SET @sqlcommand = 'ALTER TABLE ' + @Schema + '.' + @TempTable1 + ' ADD CONSTRAINT [' + @Input2IndexField +'] PRIMARY KEY CLUSTERED ' 
			--SET @sqlcommand = @sqlcommand + '(' + @Input2IndexField + ' ASC)' 
			--PRINT @sqlcommand
			--EXEC(@sqlcommand)

			--SET @sqlcommand = 'CREATE SPATIAL INDEX ' + @TempTable1 + '_SpatialIndex ' 
			--SET @sqlcommand = @sqlcommand + 'ON ' + @TempTable1 + '(' + @Input1GeometryField + ') '
			
			--SET @sqlcommand = @sqlcommand + 'WITH ( BOUNDING_BOX = (xmin=-180, ymin=-90, xmax=180, ymax=90) )'
			
			--PRINT @sqlcommand
			--EXEC(@sqlcommand)

		--END
	END


	-- Now do the spatial selection
	BEGIN
		SET @sqlcommand = 'SELECT ' + @Schema + '.' + @InputTable1 + '.* '
		SET @sqlcommand = @sqlcommand + 'into ' + @Schema + '.' + @TempTable2 + ' '
		SET @sqlcommand = @sqlcommand + 'from ' + @Schema + '.' + @InputTable1 + ' '
		SET @sqlcommand = @sqlcommand + 'join ' + @Schema + '.' + @TempTable1 + ' '
		SET @sqlcommand = @sqlcommand + 'on ' + @InputTable1 + '.' + @Input1GeometryField + '.STIntersects(' + 
		 @TempTable1 + '.' + @Input2GeometryField + ') = 1 '
		PRINT @sqlcommand
		EXEC (@sqlcommand)
	END
END
