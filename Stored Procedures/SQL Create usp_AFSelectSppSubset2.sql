/*===========================================================================*\
  AFSelectSppSubset2 is a SQL stored procedure to create an intermediate
  SQL Server table containing a subset of records based on a given set
  of SQL criteria.
  
  Copyright © 2024 Andy Foy Consulting
  
  This file is used by the 'DataSelector' tool, versions of which are
  available for MapInfo and ArcGIS.
  
  AFSelectSppSubset is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.
  
  AFSelectSppSubset is distributed in the hope that it will be useful,
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
If EXISTS (SELECT ROUTINE_NAME FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_SCHEMA = 'dbo' AND ROUTINE_NAME = 'AFSelectSppSubset')
	DROP PROCEDURE dbo.AFSelectSppSubset
GO

-- Create the stored procedure
CREATE PROCEDURE dbo.AFSelectSppSubset2
	@Schema varchar(50),
	@InputTable varchar(50),
	@ColumnNames varchar(2000),
	@WhereClause varchar(2000),
	@GroupByClause varchar(2000),
	@OrderByClause varchar(2000),
	@Split bit
AS
BEGIN

/*===========================================================================*\
  Description:		Select species records based on the SQL clauses
					passed by the calling routine from GIS

  Parameters:
	@Schema			The schema for the partner and species table.
	@InputTable	The name of the table contain the species records.
	@ColumnNames	The list of columns to select from the species table.
	@WhereClause	The SQL where clause to use during the selection.
	@GroupByClause	The SQL group by clause to use during the selection.
	@OrderByClause	The SQL order by clause to use during the selection.
	@UserId			The userid of the user executing the selection.
	@Split			If the records should be split into separate point
					and polygon tables (0 = no, 1 = yes).

  Created:			Oct 2024
  Last revised:		Oct 2024

 *****************  Version 1  *****************
 Author: Andy Foy		Date: 04/10/2024
 A. Initial version of code based on AFSelectSubset.

\*===========================================================================*/

	SET NOCOUNT ON

	/*---------------------------------------------------------------------------*\
		Set any default parameter values and declare any variables
	\*---------------------------------------------------------------------------*/

	If @Schema = ''
		SET @Schema = 'dbo'
	If @ColumnNames IS NULL OR @ColumnNames = ''
		SET @ColumnNames = '*'
	If @WhereClause IS NULL
		SET @WhereClause = ''
	If @GroupByClause IS NULL
		SET @GroupByClause = ''
	If @OrderByClause IS NULL
		SET @OrderByClause = ''
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
	DECLARE @SpatialColumn varchar(50)
	DECLARE @IsSpatial bit

	If @Split = 1
	BEGIN
		IF @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Table is to be split'
	END

	/*---------------------------------------------------------------------------*\
		Prefix the SQL clause fields (if required)
	\*---------------------------------------------------------------------------*/

	If @GroupByClause <> ''
		SET @GroupByClause = ' GROUP BY ' + @GroupByClause

	If @OrderByClause <> ''
		SET @OrderByClause = ' ORDER BY ' + @OrderByClause

	If @WhereClause NOT LIKE 'FROM %'
	BEGIN
		SET @FromClause = ' FROM ' + @Schema + '.' + @InputTable + ' As Spp'
		If @WhereClause <> ''
			SET @WhereClause = ' WHERE (' + @WhereClause + ')'
	END

	IF @debug = 1
    BEGIN
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Column names are: ' + @ColumnNames
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'From clause is: ' + @FromClause
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Where clause is: ' + @WhereClause
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'GroupBy clause is: ' + @GroupByClause
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'OrderBy clause is: ' + @OrderByClause
    END

	/*---------------------------------------------------------------------------*\
		Report if the input table is spatially enabled
	\*---------------------------------------------------------------------------*/

	---- Check if the input table contains spatial data
	--If EXISTS(SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @Schema AND TABLE_NAME = @InputTable AND COLUMN_NAME = @SpatialColumn)
	--	SET @IsSpatial = 1

	-- Check if the input table contains spatial data
	SELECT @SpatialColumn = c.name FROM sys.columns c INNER JOIN sys.tables t on t.object_id = c.object_id
		WHERE schema_name(t.schema_id) = @Schema AND t.name = @InputTable AND type_name(user_type_id) in ('geometry', 'geography')

	IF @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Spatial column is ' + @SpatialColumn

	IF @SpatialColumn IS NOT NULL
		SET @IsSpatial = 1

	If @IsSpatial = 1
	BEGIN
		IF @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'The input table is spatial'
	END

	/*---------------------------------------------------------------------------*\
		If the input contains spatial data, and is to be split, separate
		the points and polygons into different tables
	\*---------------------------------------------------------------------------*/

	If @Split = 1 AND @IsSpatial = 1
	BEGIN

		/*---------------------------------------------------------------------------*\
			Clear any existing temporary table
		\*---------------------------------------------------------------------------*/

		SET @TempTable = @InputTable + '_point'

		-- Drop the points temporary table if it already exists
		If EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @Schema AND TABLE_NAME = @TempTable)
		BEGIN
			If @debug = 1
				PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Dropping temporary point table ...'
			SET @sqlcommand = 'DROP TABLE ' + @Schema + '.' + @TempTable
			EXEC (@sqlcommand)
			WITH RESULT SETS NONE
		END

		/*---------------------------------------------------------------------------*\
			Select the point records into a temporary table
		\*---------------------------------------------------------------------------*/

		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Performing point selection ...'

		-- Select the input records into the points temporary table
		SET @sqlcommand = 
			'SELECT ' + @ColumnNames +
			' INTO ' + @Schema + '.' + @TempTable + ' ' +
			@FromClause +
			@WhereClause + ' AND ' + @SpatialColumn + '.STGeometryType() LIKE ''%Point''' +
			@GroupByClause +
			@OrderByClause

		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'SQL command is: ' +  @sqlcommand
		EXEC (@sqlcommand)
		WITH RESULT SETS NONE

		/*---------------------------------------------------------------------------*\
			Report the number of point records selected
		\*---------------------------------------------------------------------------*/

		Set @RecCnt = @@ROWCOUNT

		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + Cast(@RecCnt As varchar) + ' point records selected ...'

		/*---------------------------------------------------------------------------*\
			Clear any existing temporary table
		\*---------------------------------------------------------------------------*/

		SET @TempTable = @InputTable + '_poly'

		-- Drop the polygons temporary table if it already exists
		If EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @Schema AND TABLE_NAME = @TempTable)
		BEGIN
			If @debug = 1
				PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Dropping temporary polygon table ...'
			SET @sqlcommand = 'DROP TABLE ' + @Schema + '.' + @TempTable
			EXEC (@sqlcommand)
			WITH RESULT SETS NONE
		END

		/*---------------------------------------------------------------------------*\
			Select the polygon records into a temporary table
		\*---------------------------------------------------------------------------*/

		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Performing polygon selection ...'

		-- Select the input records into the polygons temporary table
		SET @sqlcommand = 
			'SELECT ' + @ColumnNames +
			' INTO ' + @Schema + '.' + @TempTable + ' ' +
			@FromClause +
			@WhereClause + ' AND ' + @SpatialColumn + '.STGeometryType() LIKE ''%Polygon''' +
			@GroupByClause +
			@OrderByClause

		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'SQL command is: ' +  @sqlcommand
		EXEC (@sqlcommand)
		WITH RESULT SETS NONE

		/*---------------------------------------------------------------------------*\
			Report the number of polygon records selected
		\*---------------------------------------------------------------------------*/

		Set @RecCnt = @@ROWCOUNT

		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + Cast(@RecCnt As varchar) + ' polygon records selected ...'

	END
	ELSE
	BEGIN

		/*---------------------------------------------------------------------------*\
			Clear any existing temporary table
		\*---------------------------------------------------------------------------*/

		SET @TempTable = @InputTable + '_flat'

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
			Select the records into a temporary table
		\*---------------------------------------------------------------------------*/

		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Performing selection ...'

		-- Select the input records into the temporary table
		SET @sqlcommand = 
			'SELECT ' + @ColumnNames +
			' INTO ' + @Schema + '.' + @TempTable + ' ' +
			@FromClause +
			@WhereClause +
			@GroupByClause +
			@OrderByClause

		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'SQL command is: ' +  @sqlcommand
		EXEC (@sqlcommand)
		WITH RESULT SETS NONE

		/*---------------------------------------------------------------------------*\
			Report the number of records selected
		\*---------------------------------------------------------------------------*/

		Set @RecCnt = @@ROWCOUNT

		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + Cast(@RecCnt As varchar) + ' records selected ...'

	END

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Ended.'

END
GO