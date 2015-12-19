USE NBNData
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*===========================================================================*\
  Description:	Returns the eastings value for the lower left bounding box
                of an eastings value at the required precision.

  Parameters:
	@Eastings		The current eastings value.
	@Precision		The precision of the bounding box required.

  Created:	Nov 2012

  Last revision information:
    $Revision: 1 $
    $Date: 10/12/12 12:19 $
    $Author: Andyfoy $

\*===========================================================================*/

-- Drop the user function if it already exists
if exists (select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'AFReturnLowerEastings')
	DROP FUNCTION dbo.AFReturnLowerEastings
GO

-- Create the user function
CREATE FUNCTION dbo.AFReturnLowerEastings(@Eastings Int, @Precision Int)
RETURNS VarChar(6)

AS
BEGIN
	
	Declare @ReturnValue Int
	SET @ReturnValue = 
	CASE
		WHEN @Eastings <> 0 AND @Precision = 1		THEN (@Eastings/@Precision) * @Precision
		WHEN @Eastings <> 0 AND @Precision = 10		THEN (@Eastings/@Precision) * @Precision
		WHEN @Eastings <> 0 AND @Precision = 100	THEN (@Eastings/@Precision) * @Precision
		WHEN @Eastings <> 0 AND @Precision = 1000	THEN (@Eastings/@Precision) * @Precision
		WHEN @Eastings <> 0 AND @Precision = 2000	THEN (@Eastings/@Precision) * @Precision
		WHEN @Eastings <> 0 AND @Precision = 10000	THEN (@Eastings/@Precision) * @Precision
		WHEN @Eastings <> 0 AND @Precision = 100000	THEN (@Eastings/@Precision) * @Precision
		ELSE @Eastings
	END

	RETURN @ReturnValue

END