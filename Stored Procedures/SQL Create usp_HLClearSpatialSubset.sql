/*===========================================================================*\
  HLClearSpatialSubset is a SQL stored procedure to delete an intermediate
  SQL Server table once it is no longer required.
  
  Copyright © 2017 Hester Lyons Consulting, 2018, 2024 Andy Foy Consulting
  
  This file is used by the 'DataSelector' and 'DataExtractor' tools, versions
  of which are available for MapInfo and ArcGIS.
  
  HLClearSpatialSubset is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.
  
  HLClearSpatialSubset is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
  
  A copy of the GNU General Public License is available from
  <http://www.gnu.org/licenses/>.
\*===========================================================================*/

USE NBNExtract
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Drop the procedure if it already exists
if exists (select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'HLClearSpatialSubset')
	DROP PROCEDURE dbo.HLClearSpatialSubset
GO

-- Create the stored procedure
CREATE PROCEDURE [dbo].[HLClearSpatialSubset] @Schema varchar(50),
	@SpeciesTable varchar(50),
	@UserId varchar(50) = 'temp'
AS
BEGIN

/*===========================================================================*\
  Description:		Delete any existing species spatial tables.

  Parameters:
	@Schema			The schema for the partner and species table.
	@SpeciesTable	The name of the table contain the species records.
	@UserId			The userid of the user executing the selection.

  Created:			Aug 2017
  Last revised:		Oct 2024

 *****************  Version 3  *****************
 Author: Andy Foy		Date: 14/10/2024
 A. Add 'WITH RESULT SETS NONE' when executing SQL.

 *****************  Version 2  *****************
 Author: Andy Foy		Date: 13/12/2018
 A. Include schema in all references to table name.

 *****************  Version 1  *****************
 Author: Hester Lyons		Date: 10/08/2017
 A. Initial version of code.

\*===========================================================================*/

	SET NOCOUNT ON

	DECLARE @debug int
	Set @debug = 0

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Started.'

	DECLARE @sqlCommand nvarchar(2000)

	DECLARE @TempTable varchar(50)
	SET @TempTable = @SpeciesTable + '_' + @UserId

	-- Drop the temporary table if it already exists
	If exists (select TABLE_NAME from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = @Schema and TABLE_NAME = @TempTable)
	BEGIN
		If @debug = 1
			PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Dropping spatial subset table ...'

		SET @sqlcommand = 'DROP TABLE ' + @Schema + '.' + @TempTable
		EXEC (@sqlcommand)
		WITH RESULT SETS NONE
	END

	-- If the MapInfo MapCatalog exists then update it
	if exists (select TABLE_NAME from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA = 'MAPINFO' and TABLE_NAME = 'MAPINFO_MAPCATALOG')
	BEGIN

		-- Delete the MapInfo MapCatalog entry if it exists
		if exists (select TABLENAME from [MAPINFO].[MAPINFO_MAPCATALOG] where TABLENAME = @TempTable and OWNERNAME = @Schema)
		BEGIN
			If @debug = 1
				PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Deleting the MapInfo MapCatalog entry ...'

			SET @sqlcommand = 'DELETE FROM [MAPINFO].[MAPINFO_MAPCATALOG]' +
				' WHERE TABLENAME = ''' + @TempTable + ''' AND OWNERNAME = ''' + @Schema + ''''
			EXEC (@sqlcommand)
		WITH RESULT SETS NONE
		END

	END

	If @debug = 1
		PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Ended.'

END
