USE NBNData
GO

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

/*===========================================================================*\
  Description:	
		Returns the precision of a given spatial reference.

		Only supports 'OSGB' spatial reference system.

  Parameters:	
		@SpatialRef			 		The spatial reference of interest.
		@SRSystem					The spatial reference system of the
									spatial reference.
		@Format						The format of the precision:
										0 = integer (metres), e.g. '100'
										1 = text with units, e.g. '100 m'

  Created:	Aug 2015

  Last revision information:
    $Revision: 1 $
    $Date: 30/08/15 $
    $Author: AndyFoy $

\*===========================================================================*/

-- Drop the user function if it already exists
if exists (select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'AFGridRefPrecision')
	DROP FUNCTION dbo.AFGridRefPrecision
GO

-- Create the user function
CREATE FUNCTION [dbo].[AFGridRefPrecision]
(
	@SpatialRef varchar(30),
	@SRSystem varchar(10),
	@Format bit
)
RETURNS varchar(10)

AS
BEGIN
	DECLARE @lenSR int
	DECLARE @ReturnData varchar(10)

	SET @SpatialRef = REPLACE(@SpatialRef, ' ', '')
	SET @ReturnData = ''

	IF @SRSystem = 'OSGB'
	BEGIN
		SET @lenSR = LEN(@SpatialRef)

		IF @Format = 0
		BEGIN
			SET @ReturnData = CASE @lenSR
				WHEN 12	THEN '1'
				WHEN 10	THEN '10'
				WHEN 8	THEN '100'
				WHEN 6	THEN '1000'
				WHEN 5	THEN '2000'
				WHEN 4	THEN '10000'
				WHEN 2	THEN '100000'
				ELSE ''
			END
		END
		ELSE
		BEGIN
			SET @ReturnData = CASE @lenSR
				WHEN 12	THEN '1 m'
				WHEN 10	THEN '10 m'
				WHEN 8	THEN '100 m'
				WHEN 6	THEN '1 km'
				WHEN 5	THEN '2 km'
				WHEN 4	THEN '10 km'
				WHEN 2	THEN '100 km'
				ELSE ''
			END
		END
END

	RETURN @ReturnData
END

GO
