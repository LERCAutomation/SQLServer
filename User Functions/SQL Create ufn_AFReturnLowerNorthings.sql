USE NBNData
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*===========================================================================*\
  Description:	Returns the northings value for the lower left bounding box
                of an northings value at the required precision.

  Parameters:
	@Northings		The current northings value.
	@Precision		The precision of the bounding box required.
	@PolyMin		The minimum polygon size.

  Created:	Nov 2012

  Last revision information:
    $Revision: 2 $
    $Date: 12/07/18 12:35 $
    $Author: Andyfoy $

\*===========================================================================*/

-- Drop the user function if it already exists
if exists (select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'AFReturnLowerNorthings')
	DROP FUNCTION dbo.AFReturnLowerNorthings
GO

-- Create the user function
CREATE FUNCTION dbo.AFReturnLowerNorthings(@Northings Int, @Precision Int, @PolyMin Int)
RETURNS VarChar(6)

AS
BEGIN
	
	IF @Precision < @PolyMin
		SET @Precision = @PolyMin

	Declare @ReturnValue Int
	SET @ReturnValue = 
	CASE
		WHEN @Northings <> 0 AND @Precision = 1			THEN (@Northings/@Precision) * @Precision
		WHEN @Northings <> 0 AND @Precision = 10		THEN (@Northings/@Precision) * @Precision
		WHEN @Northings <> 0 AND @Precision = 100		THEN (@Northings/@Precision) * @Precision
		WHEN @Northings <> 0 AND @Precision = 1000		THEN (@Northings/@Precision) * @Precision
		WHEN @Northings <> 0 AND @Precision = 2000		THEN (@Northings/@Precision) * @Precision
		WHEN @Northings <> 0 AND @Precision = 10000		THEN (@Northings/@Precision) * @Precision
		WHEN @Northings <> 0 AND @Precision = 100000	THEN (@Northings/@Precision) * @Precision
		ELSE @Northings
	END
     
	RETURN @ReturnValue

END