/*===========================================================================*\
  AFSelectSppSubset is a SQL stored procedure to create an intermediate
  SQL Server table containing a subset of records based on a given set
  of SQL criteria.
  
  Copyright © 2015 - 2016 Andy Foy Consulting
  
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

/*===========================================================================*\
  Description:		Select species records based on the SQL where clause
					passed by the calling routine.

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
  Last revised:		Jan 2016

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

-- Drop the procedure if it already exists
if exists (select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'AFSelectSppSubset')
	DROP PROCEDURE dbo.AFSelectSppSubset
GO

-- Create the stored procedure
CREATE PROCEDURE [dbo].[AFSelectSppSubset]
	@Schema varchar(50),
	@SpeciesTable varchar(50),
	@ColumnNames varchar(1000),
	@WhereClause varchar(1000),
	@GroupByClause varchar(1000),
	@OrderByClause varchar(1000),
	@UserId varchar(50),
	@Split bit
AS
BEGIN

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

	DECLARE @debug int
	Set @debug = 0

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Started.'

	DECLARE @sqlCommand nvarchar(2000)
	DECLARE @params nvarchar(2000)
	DECLARE @RecCnt Int
	DECLARE @TempTable varchar(50)

	-- Lookup table column names and spatial variables from Spatial_Tables
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
							 '@O6 = CoordSystem ' +
						'FROM ' + @Schema + '.' + @SpatialTable + ' ' +
						'WHERE TableName = ''' + @SpeciesTable + ''' AND OwnerName = ''' + @Schema + ''''

	SET @params =	'@O1 varchar(32) OUTPUT, ' +
					'@O2 varchar(32) OUTPUT, ' +
					'@O3 varchar(32) OUTPUT, ' +
					'@O4 bit OUTPUT, ' +
					'@O5 varchar(32) OUTPUT, ' +
					'@O6 varchar(254) OUTPUT'
		
	EXEC sp_executesql @sqlcommand, @params,
		@O1 = @XColumn OUTPUT, @O2 = @YColumn OUTPUT, @O3 = @SizeColumn OUTPUT, @O4 = @IsSpatial OUTPUT, 
		@O5 = @SpatialColumn OUTPUT, @O6 = @CoordSystem OUTPUT
		
	If @IsSpatial = 1
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

	If @WhereClause <> ''
		SET @WhereClause = ' WHERE ' + @WhereClause

	If @Split = 1 AND @IsSpatial = 1
	BEGIN

		SET @TempTable = @SpeciesTable + '_point_' + @UserId

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
			' INTO ' + @Schema + '.' + @TempTable +
			' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
			@WhereClause + ' AND SP_GEOMETRY.STAsText() LIKE ''POINT%''' +
			@GroupByClause +
			@OrderByClause
		EXEC (@sqlcommand)

		Set @RecCnt = @@ROWCOUNT

		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + Cast(@RecCnt As varchar) + ' point records selected ...'

		-- Update the MapInfo MapCatalog entry
		SET @sqlcommand = 'EXECUTE dbo.AFUpdateMICatalog ''' + @Schema + ''', ''' + @TempTable + ''', ''' + @XColumn + ''', ''' + @YColumn +
			''', ''' + @SizeColumn + ''', ''' + @SpatialColumn + ''', ''' + @CoordSystem + ''', ''' + Cast(@RecCnt As varchar) + ''', ''' + Cast(@IsSpatial As varchar) + ''''
		EXEC (@sqlcommand)

		SET @TempTable = @SpeciesTable + '_poly_' + @UserId

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
			' INTO ' + @Schema + '.' + @TempTable +
			' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
			@WhereClause + ' AND SP_GEOMETRY.STAsText() LIKE ''POLY%''' +
			@GroupByClause +
			@OrderByClause
		EXEC (@sqlcommand)

		Set @RecCnt = @@ROWCOUNT

		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + Cast(@RecCnt As varchar) + ' polygon records selected ...'

		-- Update the MapInfo MapCatalog entry
		SET @sqlcommand = 'EXECUTE dbo.AFUpdateMICatalog ''' + @Schema + ''', ''' + @TempTable + ''', ''' + @XColumn + ''', ''' + @YColumn +
			''', ''' + @SizeColumn + ''', ''' + @SpatialColumn + ''', ''' + @CoordSystem + ''', ''' + Cast(@RecCnt As varchar) + ''', ''' + Cast(@IsSpatial As varchar) + ''''
		EXEC (@sqlcommand)

	END
	ELSE
	BEGIN

		SET @TempTable = @SpeciesTable + '_' + @UserId

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
			' INTO ' + @Schema + '.' + @TempTable +
			' FROM ' + @Schema + '.' + @SpeciesTable + ' As Spp' +
			@WhereClause +
			@GroupByClause +
			@OrderByClause
		EXEC (@sqlcommand)

		Set @RecCnt = @@ROWCOUNT

		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + Cast(@RecCnt As varchar) + ' records selected ...'

		-- Update the MapInfo MapCatalog entry
		SET @sqlcommand = 'EXECUTE dbo.AFUpdateMICatalog ''' + @Schema + ''', ''' + @TempTable + ''', ''' + @XColumn + ''', ''' + @YColumn +
			''', ''' + @SizeColumn + ''', ''' + @SpatialColumn + ''', ''' + @CoordSystem + ''', ''' + Cast(@RecCnt As varchar) + ''', ''' + Cast(@IsSpatial As varchar) + ''''
		EXEC (@sqlcommand)

	END

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Ended.'

END
GO
