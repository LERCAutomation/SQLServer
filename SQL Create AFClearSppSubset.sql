/*===========================================================================*\
  AFClearSppSubset is a SQL stored procedure to delete an intermediate
  SQL Server table once it is no longer required.
  
  Copyright © 2015 Andy Foy Consulting
  
  This file is used by the 'DataSelector' and 'DataExtractor' tools, versions
  of which are available for MapInfo and ArcGIS.
  
  AFClearSppSubset is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.
  
  AFClearSppSubset is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
  
  A copy of the GNU General Public License is available from
  <http://www.gnu.org/licenses/>.
\*===========================================================================*/

USE [NBNData]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*===========================================================================*\
  Description:		Delete an existing species subset table.

  Parameters:
	@Schema			The schema for the partner and species table.
	@SpeciesTable	The name of the table contain the species records.
	@UserId			The userid of the user executing the selection.

  Created:			Sep 2015
  Last revised:		Sep 2015

 *****************  Version 1  *****************
 Author: Andy Foy		Date: 03/06/2015
 A. Initial version of code.

\*===========================================================================*/

-- Drop the procedure if it already exists
if exists (select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'AFClearSppSubset')
	DROP PROCEDURE dbo.AFClearSppSubset
GO

-- Create the stored procedure
CREATE PROCEDURE [dbo].[AFClearSppSubset] @Schema varchar(50),
	@SpeciesTable varchar(50),
	@UserId varchar(50) = 'temp'
AS
BEGIN

	SET NOCOUNT ON

	DECLARE @debug int
	Set @debug = 0

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Started.'

	DECLARE @sqlCommand nvarchar(2000)

	DECLARE @TempTable varchar(50)
	SET @TempTable = @SpeciesTable + '_' + @UserId

	-- Drop the index on the sequential primary key of the temporary table if it already exists
	If exists (select column_name from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where TABLE_SCHEMA = @Schema and TABLE_NAME = @TempTable and COLUMN_NAME = 'MI_PRINX' and CONSTRAINT_NAME = 'PK_' + @TempTable + '_MI_PRINX')
	BEGIN
		SET @sqlcommand = 'ALTER TABLE ' + @Schema + '.' + @TempTable +
			' DROP CONSTRAINT PK_' + @SpeciesTable + '_MI_PRINX'
		EXEC (@sqlcommand)
	END
	
	-- Drop the temporary table if it already exists
	If exists (select TABLE_NAME from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = @Schema and TABLE_NAME = @TempTable)
	BEGIN
		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Dropping temporary table ...'
		SET @sqlcommand = 'DROP TABLE ' + @Schema + '.' + @TempTable
		EXEC (@sqlcommand)
	END

	-- If the MapInfo MapCatalog exists then update it
	if exists (select TABLE_NAME from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'MAPINFO' and TABLE_NAME = 'MAPINFO_MAPCATALOG')
	BEGIN

		-- Delete the MapInfo MapCatalog entry if it exists
		if exists (select TABLENAME from [MAPINFO].[MAPINFO_MAPCATALOG] where TABLENAME = @TempTable)
		BEGIN
			If @debug = 1
				PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Deleting the MapInfo MapCatalog entry ...'
			SET @sqlcommand = 'DELETE FROM [MAPINFO].[MAPINFO_MAPCATALOG]' +
				' WHERE TABLENAME = ''' + @TempTable + ''''
			EXEC (@sqlcommand)
		END

	END

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Ended.'

END
