USE [NBNData]
GO

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

/*===========================================================================*\
  Description:	
		Gets a concatenated string of the boroughs intersecting
		a given geometry feature.

  Parameters:	
		@Geometry	 				The geometry feature of interest.

  Created:	Oct 2015

  Last revision information:
    $Revision: 1 $
    $Date: 30/10/15 10:21 $
    $Author: AndyFoy $

\*===========================================================================*/
ALTER FUNCTION [dbo].[AFGetIntersectingBoroughs]
(
	@Geometry					Geometry
)
RETURNS	VARCHAR(100)

AS
BEGIN
	DECLARE @Seperator	VARCHAR(10)
	
	-- Gets the Seperator from the settings table.
	SELECT	@Seperator	=	Data
	FROM	Setting
	WHERE	Name		=	'DBListSep' 
	
	DECLARE	@ReturnValue	VARCHAR(100)

	DECLARE @OutputValues	TABLE (
		Item	VARCHAR(10)
	)
	
	INSERT INTO	@OutputValues
	SELECT  DISTINCT BoroughCode
	FROM	LBPolygonsMeridian
	WHERE	SP_GEOMETRY.STIntersects(@Geometry) = 1
	ORDER BY BoroughCode
	
	SELECT	@ReturnValue	=
				-- Blank when this is the first value, otherwise
				-- the previous string plus the seperator
				CASE
					WHEN @ReturnValue IS NULL THEN ''
					ELSE @ReturnValue + @Seperator
				END + Item
	FROM		@OutputValues
	GROUP BY	Item
	
	RETURN	@ReturnValue
END
