/*===========================================================================*\
  AFSelectSppSubset is a SQL stored procedure to create an intermediate
  SQL Server table containing a subset of records based on a given set
  of SQL criteria.
  
  Copyright © 2015 - 2016, 2018 Andy Foy Consulting
  
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
CREATE PROCEDURE dbo.AFSelectSppSubset
	@Schema varchar(50),
	@SpeciesTable varchar(50),
	@ColumnNames varchar(2000),
	@WhereClause varchar(2000),
	@GroupByClause varchar(2000),
	@OrderByClause varchar(2000),
	@UserId varchar(50),
	@Split bit
AS
BEGIN

/*===========================================================================*\
  Description:		Select species records based on the SQL clauses
					passed by the calling routine from GIS

  Parameters:
	@Schema			The schema for the partner and species table.
	@SpeciesTable	The name of the table contain the species records.
	@ColumnNames	The list of columns to select from the species table.
	@WhereClause	The SQL where clause to use during the selection.
	@GroupByClause	The SQL group by clause to use during the selection.
	@OrderByClause	The SQL order by clause to use during the selection.
	@UserId			The userid of the user executing the selection.
	@Split			If the records should be split into separate point
					and polygon tables (0 = no, 1 = yes).

  Created:			Jun 2015
  Last revised:		Apr 2024

 *****************  Version 13  ****************
 Author: Andy Foy		Date: 23/04/2024
 A. Add 'WITH RESULT SETS NONE' when executing SQL.

 *****************  Version 12  ****************
 Author: Andy Foy		Date: 13/12/2018
 A. Use schema parameter when calling stored procedures
    and user functions.

 *****************  Version 11  ****************
 Author: Andy Foy		Date: 13/07/2018
 A. Check the MapInfo MapCatalog exists before
 	updating it.

 *****************  Version 10  ****************
 Author: Andy Foy		Date: 19/08/2016
 A. Split results into points & polys after initial
 	selection is made.

 *****************  Version 9  *****************
 Author: Andy Foy		Date: 01/08/2016
 A. Fix SQL error when WHERE clause is empty.

 *****************  Version 8  *****************
 Author: Andy Foy		Date: 25/07/2016
 A. Added clearer comments.

 *****************  Version 7  *****************
 Author: Andy Foy		Date: 04/03/2016
 A. Add brackets to SQL where clause to ensure
    correct execution.
 B. Remove hard-coded reference to SP_GEOMETRY.
 C. Improve performance by examining type of
    geometry (STGeometryType) instead of examining
	geometry as text (STAsText).

 *****************  Version 6  *****************
 Author: Andy Foy		Date: 23/02/2016
 A. Allow each SQL clause to be up to 2000 chars.

 *****************  Version 5  *****************
 Author: Andy Foy		Date: 16/02/2016
 A. Allow WHERE clause to also contain FROM clause
    so that the query can contain JOIN statements.

 *****************  Version 4  *****************
 Author: Andy Foy		Date: 18/01/2016
 A. Added new split parameter to indicate if output
	table should be split into points and polygons.

 *****************  Version 3  *****************
 Author: Andy Foy		Date: 09/09/2015
 A. Include group by and order by parameters.
 B. Enable subsets to be non-spatial (i.e. have
	no geometry column.
 C. Remove MapCatalog entry if subset table is
	non-spatial.
 D. Lookup table column names and spatial variables
	from Spatial_Tables.

 *****************  Version 2  *****************
 Author: Andy Foy		Date: 08/06/2015
 A. Include userid as parameter to use in temporary SQL
	table name to enable concurrent use of tool.

 *****************  Version 1  *****************
 Author: Andy Foy		Date: 03/06/2015
 A. Initial version of code based on Data Extractor tool.

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
	IF @UserId IS NULL
		SET @UserId = 'temp'
	If @Split IS NULL
		SET @Split = 0

	DECLARE @FromClause varchar(2000)
	SET @FromClause = ''

	DECLARE @debug int
	Set @debug = 0

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Started.'

	DECLARE @sqlCommand nvarchar(4000)
	DECLARE @params nvarchar(4000)
	DECLARE @RecCnt Int
	DECLARE @TempTable varchar(50)
	DECLARE @SplitTable varchar(50)

	/*---------------------------------------------------------------------------*\
		Lookup table column names and spatial variables from Spatial_Tables
	\*---------------------------------------------------------------------------*/
	DECLARE @IsSpatial bit
	DECLARE @XColumn varchar(32), @YColumn varchar(32), @SizeColumn varchar(32), @SpatialColumn varchar(32)
	DECLARE @CoordSystem varchar(254)
	
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
							 '@O6 = CoordSystem' +
						' FROM ' + @Schema + '.' + @SpatialTable +
						' WHERE TableName = ''' + @SpeciesTable + ''' AND OwnerName = ''' + @Schema + ''''

	SET @params =	'@O1 varchar(32) OUTPUT, ' +
					'@O2 varchar(32) OUTPUT, ' +
					'@O3 varchar(32) OUTPUT, ' +
					'@O4 bit OUTPUT, ' +
					'@O5 varchar(32) OUTPUT, ' +
					'@O6 varchar(254) OUTPUT'
		
	EXEC sp_executesql @sqlcommand, @params,
		@O1 = @XColumn OUTPUT, @O2 = @YColumn OUTPUT, @O3 = @SizeColumn OUTPUT, @O4 = @IsSpatial OUTPUT, 
		@O5 = @SpatialColumn OUTPUT, @O6 = @CoordSystem OUTPUT
	WITH RESULT SETS NONE
		
	/*---------------------------------------------------------------------------*\
		Prefix the SQL clause fields (if required)
	\*---------------------------------------------------------------------------*/

	If @GroupByClause <> ''
		SET @GroupByClause = ' GROUP BY ' + @GroupByClause

	If @OrderByClause <> ''
		SET @OrderByClause = ' ORDER BY ' + @OrderByClause

	If @WhereClause NOT LIKE 'FROM %'
	BEGIN
		SET @FromClause = ' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp'
		If @WhereClause <> ''
			SET @WhereClause = ' WHERE (' + @WhereClause + ')'
	END

	/*---------------------------------------------------------------------------*\
		Perform the spatial selection, selecting points and polygons into
		the same table (if the data is spatial)
	\*---------------------------------------------------------------------------*/

	SET @TempTable = @SpeciesTable + '_' + @UserId

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
		Select the results into a temporary table
	\*---------------------------------------------------------------------------*/

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
	WITH RESULT SETS NONE

	/*---------------------------------------------------------------------------*\
		Report the number of records selected
	\*---------------------------------------------------------------------------*/

	Set @RecCnt = @@ROWCOUNT

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + Cast(@RecCnt As varchar) + ' records selected ...'

	/*---------------------------------------------------------------------------*\
		Report if the table is spatially enabled
	\*---------------------------------------------------------------------------*/

	-- Check if the results table (still) contains spatial data
	SELECT @SpatialColumn = c.name FROM sys.columns c INNER JOIN sys.tables t on t.object_id = c.object_id
		WHERE schema_name(t.schema_id) = @Schema AND t.name = @TempTable AND type_name(user_type_id) in ('geometry', 'geography')

	IF @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Spatial column is ' + @SpatialColumn

	IF @SpatialColumn IS NULL
		SET @IsSpatial = 0

	If @IsSpatial = 1
	BEGIN
		IF @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'The results are spatial'
	END

	/*---------------------------------------------------------------------------*\
		Update the MapInfo MapCatalog entry
	\*---------------------------------------------------------------------------*/

	-- If the MapInfo MapCatalog exists then update it
	If EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'MAPINFO' AND TABLE_NAME = 'MAPINFO_MAPCATALOG')
	BEGIN
		SET @sqlcommand = 'EXECUTE ' + @Schema + '.AFUpdateMICatalog ''' + @Schema + ''', ''' + @TempTable + ''', ''' + @XColumn + ''', ''' + @YColumn +
			''', ''' + @SizeColumn + ''', ''' + @SpatialColumn + ''', ''' + @CoordSystem + ''', ''' + Cast(@RecCnt As varchar) + ''', ''' + Cast(@IsSpatial As varchar) + ''''
		EXEC (@sqlcommand)
		WITH RESULT SETS NONE
	END

	/*---------------------------------------------------------------------------*\
		If the results contains spatial data, and are to be split, separate
		the points and polygons into different tables
	\*---------------------------------------------------------------------------*/

	If @Split = 1 AND @IsSpatial = 1
	BEGIN

		/*---------------------------------------------------------------------------*\
			Clear any existing temporary table
		\*---------------------------------------------------------------------------*/

		SET @SplitTable = @SpeciesTable + '_point_' + @UserId

		-- Drop the points temporary table if it already exists
		If EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @Schema AND TABLE_NAME = @SplitTable)
		BEGIN
			If @debug = 1
				PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Dropping temporary point table ...'
			SET @sqlcommand = 'DROP TABLE ' + @Schema + '.' + @SplitTable
			EXEC (@sqlcommand)
			WITH RESULT SETS NONE
		END

		/*---------------------------------------------------------------------------*\
			Select the point species records into a temporary table
		\*---------------------------------------------------------------------------*/

		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Performing point selection ...'

		-- Select the result records into the points temporary table
		SET @sqlcommand = 
			'SELECT *' +
			' INTO ' + @Schema + '.' + @SplitTable +
			' FROM ' + @TempTable +
			' WHERE ' + @SpatialColumn + '.STGeometryType() LIKE ''%Point'''
		EXEC (@sqlcommand)
		WITH RESULT SETS NONE

		/*---------------------------------------------------------------------------*\
			Report the number of point records selected
		\*---------------------------------------------------------------------------*/

		Set @RecCnt = @@ROWCOUNT

		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + Cast(@RecCnt As varchar) + ' point records selected ...'

		/*---------------------------------------------------------------------------*\
			Update the MapInfo MapCatalog entry
		\*---------------------------------------------------------------------------*/

		-- If the MapInfo MapCatalog exists then update it
		If EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'MAPINFO' AND TABLE_NAME = 'MAPINFO_MAPCATALOG')
		BEGIN
			SET @sqlcommand = 'EXECUTE ' + @Schema + '.AFUpdateMICatalog ''' + @Schema + ''', ''' + @SplitTable + ''', ''' + @XColumn + ''', ''' + @YColumn +
				''', ''' + @SizeColumn + ''', ''' + @SpatialColumn + ''', ''' + @CoordSystem + ''', ''' + Cast(@RecCnt As varchar) + ''', ''' + Cast(@IsSpatial As varchar) + ''''
			EXEC (@sqlcommand)
			WITH RESULT SETS NONE
		END

		/*---------------------------------------------------------------------------*\
			Clear any existing temporary table
		\*---------------------------------------------------------------------------*/

		SET @SplitTable = @SpeciesTable + '_poly_' + @UserId

		-- Drop the polygons temporary table if it already exists
		If EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @Schema AND TABLE_NAME = @SplitTable)
		BEGIN
			If @debug = 1
				PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Dropping temporary polygon table ...'
			SET @sqlcommand = 'DROP TABLE ' + @Schema + '.' + @SplitTable
			EXEC (@sqlcommand)
			WITH RESULT SETS NONE
		END

		/*---------------------------------------------------------------------------*\
			Select the polygon species records into a temporary table
		\*---------------------------------------------------------------------------*/

		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Performing polygon selection ...'

		-- Select the result records into the polygons temporary table
		SET @sqlcommand = 
			'SELECT *' +
			' INTO ' + @Schema + '.' + @SplitTable +
			' FROM ' + @TempTable +
			' WHERE ' + @SpatialColumn + '.STGeometryType() LIKE ''%Polygon'''
		EXEC (@sqlcommand)
		WITH RESULT SETS NONE

		/*---------------------------------------------------------------------------*\
			Report the number of polygon records selected
		\*---------------------------------------------------------------------------*/

		Set @RecCnt = @@ROWCOUNT

		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + Cast(@RecCnt As varchar) + ' polygon records selected ...'

		/*---------------------------------------------------------------------------*\
			Update the MapInfo MapCatalog entry
		\*---------------------------------------------------------------------------*/

		-- If the MapInfo MapCatalog exists then update it
		If EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'MAPINFO' AND TABLE_NAME = 'MAPINFO_MAPCATALOG')
		BEGIN
			SET @sqlcommand = 'EXECUTE ' + @Schema + '.AFUpdateMICatalog ''' + @Schema + ''', ''' + @SplitTable + ''', ''' + @XColumn + ''', ''' + @YColumn +
				''', ''' + @SizeColumn + ''', ''' + @SpatialColumn + ''', ''' + @CoordSystem + ''', ''' + Cast(@RecCnt As varchar) + ''', ''' + Cast(@IsSpatial As varchar) + ''''
			EXEC (@sqlcommand)
			WITH RESULT SETS NONE
		END

	END

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Ended.'

END
GO