USE [NBNData_TVERC]
GO
/****** Object:  StoredProcedure [dbo].[HLCreateSpatialSubset]    Script Date: 02/08/2017 15:59:41 ******/
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
	@UserID VARCHAR(50)

AS
BEGIN
	DECLARE @debug int = 0

	DECLARE @TempTable varchar(50)
	SET @TempTable = 'SpatialSubset_' + @UserId
	DECLARE @sqlcommand varchar(250)

	-- Drop the temporary table if it already exists
	If exists (select TABLE_NAME from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = @Schema and TABLE_NAME = @TempTable)
	BEGIN
		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Dropping temporary table ...'
		SET @sqlcommand = 'DROP TABLE ' + @Schema + '.' + @TempTable
		EXEC (@sqlcommand)
	END

	-- Now do the spatial selection
	BEGIN
		SET @sqlcommand = 'SELECT ' + @Schema + '.' + @InputTable1 + '.* '
		SET @sqlcommand = @sqlcommand + 'into ' + @Schema + '.' + @TempTable + ' '
		SET @sqlcommand = @sqlcommand + 'from ' + @Schema + '.' + @InputTable1 + ' '
		SET @sqlcommand = @sqlcommand + 'join ' + @Schema + '.' + @InputTable2 + ' '
		SET @sqlcommand = @sqlcommand + 'on ' + @InputTable1 + '.' + @Input1GeometryField + '.STIntersects(' + 
		 @InputTable2 + '.' + @Input2GeometryField + ') = 1'
		PRINT @sqlcommand
		EXEC (@sqlcommand)
	END
END
