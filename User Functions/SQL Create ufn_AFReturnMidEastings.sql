USE NBNData
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*===========================================================================*\
  Description:	Returns the eastings value for the centre of the bounding box
                of an eastings value at the required precision.

  Parameters:
	@Eastings		The current eastings value.
	@Precision		The precision of the bounding box required.

  Created:	Mar 2013

  Last revision information:
    $Revision: 1 $
    $Date: 27/03/13 16:10 $
    $Author: Andyfoy $

\*===========================================================================*/

-- Drop the user function if it already exists
if exists (select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'AFReturnMidEastings')
	DROP FUNCTION dbo.AFReturnMidEastings
GO

-- Create the user function
CREATE FUNCTION dbo.AFReturnMidEastings(@Eastings Int, @Precision Int)
RETURNS VarChar(6)

AS
BEGIN
	
	Declare @ReturnValue Int
	SET @ReturnValue = 
	CASE
		WHEN @Eastings <> 0 AND @Precision = 1		THEN ((@Eastings/@Precision) * @Precision) + (@Precision/2)
		WHEN @Eastings <> 0 AND @Precision = 10		THEN ((@Eastings/@Precision) * @Precision) + (@Precision/2)
		WHEN @Eastings <> 0 AND @Precision = 100	THEN ((@Eastings/@Precision) * @Precision) + (@Precision/2)
		WHEN @Eastings <> 0 AND @Precision = 1000	THEN ((@Eastings/@Precision) * @Precision) + (@Precision/2)
		WHEN @Eastings <> 0 AND @Precision = 2000	THEN ((@Eastings/@Precision) * @Precision) + (@Precision/2)
		WHEN @Eastings <> 0 AND @Precision = 10000	THEN ((@Eastings/@Precision) * @Precision) + (@Precision/2)
		WHEN @Eastings <> 0 AND @Precision = 100000	THEN ((@Eastings/@Precision) * @Precision) + (@Precision/2)
		ELSE @Eastings
	END

	RETURN @ReturnValue

END