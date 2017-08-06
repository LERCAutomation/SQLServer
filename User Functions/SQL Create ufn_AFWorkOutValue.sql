USE NBNData
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*===========================================================================*\
  Description:	Function to return a numeric value for a data value
  				which may contain characters, nulls, commas and full-stops.

  Parameters:
	@InData			The input data string.

  Created:	Jul 2016

  Last revision information:
    $Revision: 1 $
    $Date: 08/07/15 $
    $Author: Andyfoy $ Based on version by Mike Weideli.

\*===========================================================================*/

-- Drop the user function if it already exists
if exists (select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'AFWorkOutValue')
	DROP FUNCTION dbo.AFWorkOutValue
GO

-- Create the user function
CREATE FUNCTION dbo.[AFWorkOutValue](@InData as varchar(20))
RETURNS Int

AS
BEGIN

DECLARE @RVALUE INT
SET @RVALUE = 0

IF (ISNUMERIC(@InData)) = 1
BEGIN

	IF PATINDEX('%[0-9]%', @InData) <> 1
	BEGIN
		SET @RVALUE = ''
	END
	ELSE
		SET @RVALUE = CAST(FLOOR(REPLACE(@InData, ',', '')) AS INT)
		--SET @RVALUE = CAST(FLOOR(REPLACE(REPLACE(@InData, '.', ''), ',', '')) AS INT)
	END

	Return @RVALUE

END
