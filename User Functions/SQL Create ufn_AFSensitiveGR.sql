USE NBNData
GO

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

/*===========================================================================*\
  Description:	
		Returns a grid ref of the required precision.

		Needs additional UDF 'LCReturnTetrad' to do calculations
		Only works for OSGB and OSNI
		Must be no spaces in spatial ref

  Parameters:	
		@SpatialRef			 		The spatial reference of interest.
		@Sensitivity				The precision required.

  Created:	Aug 2015

  Last revision information:
    $Revision: 1 $
    $Date: 30/08/15 $
    $Author: AndyFoy $

\*===========================================================================*/

-- Drop the user function if it already exists
if exists (select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'AFSensitiveGR')
	DROP FUNCTION dbo.AFSensitiveGR
GO

-- Create the user function
CREATE FUNCTION [dbo].[AFSensitiveGR]
(
	@SpatialRef varchar(20),
	@Sensitivity varchar(6)
)
RETURNS varchar(20)

AS
BEGIN
	DECLARE @SensitiveSpatialRef varchar(20)
	DECLARE @Len int

	SET @SensitiveSpatialRef = ''
	SET @Len = LEN(@SpatialRef)

	SELECT @SensitiveSpatialRef = CASE
		WHEN @Sensitivity = '10 km' AND @Len > 4 THEN
			LEFT(@SpatialRef, 3) + SUBSTRING(@SpatialRef, ((@len - 2)/2) + 3, 1)
		WHEN @Sensitivity = '2 km' AND @Len > 4 THEN
			dbo.LCReturnTetrad(@SpatialRef, 'OSGB')
		WHEN @Sensitivity = '1 km' AND @Len > 6 THEN
			LEFT(@SpatialRef, 4) + SUBSTRING(@SpatialRef, ((@len - 2)/2) + 3, 2)
		WHEN @Sensitivity = '100 m' AND @Len > 8 THEN
			LEFT(@SpatialRef, 5) + SUBSTRING(@SpatialRef, ((@len - 2)/2) + 3, 3)
		ELSE
			@SpatialRef
	END

	RETURN @SensitiveSpatialRef
END

GO
