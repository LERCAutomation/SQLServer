USE NBNData
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*===========================================================================*\
  Description:	Returns the northings value for the centre bounding box
                of an northings value at the required precision.

  Parameters:
	@Northings		The current northings value.
	@Precision		The precision of the bounding box required.

  Created:	Mar 2013

  Last revision information:
    $Revision: 1 $
    $Date: 27/03/13 16:10 $
    $Author: Andyfoy $

\*===========================================================================*/

-- Drop the user function if it already exists
if exists (select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'AFReturnMidNorthings')
	DROP FUNCTION dbo.AFReturnMidNorthings
GO

-- Create the user function
CREATE FUNCTION dbo.AFReturnMidNorthings(@Northings Int, @Precision Int)
RETURNS VarChar(6)

AS
BEGIN
	
	Declare @ReturnValue Int
	SET @ReturnValue = 
	CASE
		WHEN @Northings <> 0 AND @Precision = 1			THEN ((@Northings/@Precision) * @Precision) + (@Precision/2)
		WHEN @Northings <> 0 AND @Precision = 10		THEN ((@Northings/@Precision) * @Precision) + (@Precision/2)
		WHEN @Northings <> 0 AND @Precision = 100		THEN ((@Northings/@Precision) * @Precision) + (@Precision/2)
		WHEN @Northings <> 0 AND @Precision = 1000		THEN ((@Northings/@Precision) * @Precision) + (@Precision/2)
		WHEN @Northings <> 0 AND @Precision = 2000		THEN ((@Northings/@Precision) * @Precision) + (@Precision/2)
		WHEN @Northings <> 0 AND @Precision = 10000		THEN ((@Northings/@Precision) * @Precision) + (@Precision/2)
		WHEN @Northings <> 0 AND @Precision = 100000	THEN ((@Northings/@Precision) * @Precision) + (@Precision/2)
		ELSE @Northings
	END
     
	RETURN @ReturnValue

END