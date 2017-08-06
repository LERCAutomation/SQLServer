/*===========================================================================*\
  AFUpdateMICatalog is a SQL stored procedure to update the
  MapInfo_MapCatalog table which is used by MapInfo when plotting spatial
  data from SQL Server.
  
  Copyright © 2015 - 2016 Andy Foy Consulting
  
  This file is used by the 'DataSelector' tool, versions of which are
  available for MapInfo and ArcGIS.
  
  AFUpdateMICatalog is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.
  
  AFUpdateMICatalog is distributed in the hope that it will be useful,
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
if exists (select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'AFUpdateMICatalog')
	DROP PROCEDURE dbo.AFUpdateMICatalog
GO

-- Create the stored procedure
CREATE PROCEDURE [dbo].[AFUpdateMICatalog]
	@Schema varchar(50),
	@Table varchar(50),
	@XColumn varchar(32),
	@YColumn varchar(32),
	@SizeColumn varchar(32),
	@SpatialColumn varchar(32),
	@CoordSystem varchar(254),
	@RecCnt Int,
	@IsSpatial bit
AS
BEGIN

/*===========================================================================*\
  Description:		Update the MapInfo MapCatalog entry for the relevant
					table.

  Parameters:
	@Schema			The schema for the record table.
	@Table			The name of the table contain the records.
	@XColumn		The name of the column relating to the X coordinates.
	@YColumn		The name of the column relating to the Y coordinates.
	@SizeColumn		The name of the column relating to the record size.
	@SpatialColumn	The name of the column containing the spatial geometry.
	@CoordSystem	The coordinate system used by the spatial geometry.
	@RecCnt			If number of records in the table.
	@IsSpatial		If the table contains spatial data (0 = no, 1 = yes).

  Created:			Jun 2015
  Last revised:		Jan 2016

 *****************  Version 1  *****************
 Author: Andy Foy		Date: 18/01/2016
 A. Initial version of code taken from AFSelectSppSubset stored procedure.

\*===========================================================================*/

	SET NOCOUNT ON
	
	DECLARE @debug int
	Set @debug = 0

	-- If the MapInfo MapCatalog exists then update it
	IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'MAPINFO' AND TABLE_NAME = 'MAPINFO_MAPCATALOG')
	BEGIN

		DECLARE @sqlCommand nvarchar(2000)
		DECLARE @params nvarchar(2000)

		-- Delete the MapInfo MapCatalog entry if it already exists
		IF EXISTS (SELECT TABLENAME FROM [MAPINFO].[MAPINFO_MAPCATALOG] WHERE TABLENAME = @Table)
		BEGIN
			IF @debug = 1
				PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Deleting the MapInfo MapCatalog entry ...'
			
			SET @sqlcommand = 'DELETE FROM [MAPINFO].[MAPINFO_MAPCATALOG]' +
				' WHERE TABLENAME = ''' + @Table + ''''
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
		AND EXISTS(SELECT * FROM sys.columns WHERE Name = @XColumn AND Object_ID = Object_ID(@Table))
		AND EXISTS(SELECT * FROM sys.columns WHERE Name = @YColumn AND Object_ID = Object_ID(@Table))
		AND EXISTS(SELECT * FROM sys.columns WHERE Name = @SizeColumn AND Object_ID = Object_ID(@Table))
		AND EXISTS(SELECT * FROM sys.columns WHERE Name = @SpatialColumn AND Object_ID = Object_ID(@Table))
		AND EXISTS(SELECT * FROM sys.columns WHERE user_type_id = 129 AND Object_ID = Object_ID(@Table))
		BEGIN

			IF @debug = 1
				PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Determining spatial extent ...'

			-- Retrieve the geometric extent values and store as variables
			SET @sqlcommand = 'SELECT @xMin = MIN(' + @XColumn + '), ' +
									 '@yMin = MIN(' + @YColumn + '), ' +
									 '@xMax = MAX(' + @XColumn + ') + MAX(' + @SizeColumn + '), ' +
									 '@yMax = MAX(' + @YColumn + ') + MAX(' + @SizeColumn + ') ' +
									 'FROM ' + @Schema + '.' + @Table

			SET @params =	'@xMin int OUTPUT, ' +
							'@yMin int OUTPUT, ' +
							'@xMax int OUTPUT, ' +
							'@yMax int OUTPUT'
		
			EXEC sp_executesql @sqlcommand, @params,
				@xMin = @X1 OUTPUT, @yMin = @Y1 OUTPUT, @xMax = @X2 OUTPUT, @yMax = @Y2 OUTPUT
		
			If @debug = 1
				PRINT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ) + ' : ' + 'Inserting the MapInfo MapCatalog entry ...'

			-- Check if the rendition column is in the table
			IF NOT EXISTS(SELECT * FROM sys.columns WHERE Name = N'MI_STYLE' AND Object_ID = Object_ID(@Table))
			BEGIN
				SET @sqlcommand = 'ALTER TABLE ' + @Table + ' ADD MI_STYLE varchar(254) NULL'
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
				,@Table
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

END