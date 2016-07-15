USE NBNData
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*===========================================================================*\
  Description:	Function to return a taxon abundance as a number.

  Parameters:
	@TOCCKey 				The Taxon_Occurrence_Key of interest.

  Created:	Jul 2016

  Last revision information:
    $Revision: 1 $
    $Date: 08/07/15 $
    $Author: Andyfoy $ Based on version by Mike Weideli.

\*===========================================================================*/

-- Drop the user function if it already exists
if exists (select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'AFAbundanceValue')
	DROP FUNCTION dbo.AFAbundanceValue
GO

-- Create the user function
CREATE FUNCTION dbo.[AFAbundanceValue](@TOCCKey char(16))
RETURNS varchar(10)

AS
BEGIN

DECLARE @RETURNSTRING varchar(100)
DECLARE @AbundanceTotal float
SET @AbundanceTotal = 0 

SELECT @AbundanceTotal = @AbundanceTotal + dbo.AFWorkOutValue(TAXON_OCCURRENCE_DATA.DATA)

FROM 
  TAXON_OCCURRENCE_DATA
INNER JOIN
  MEASUREMENT_UNIT ON 
  TAXON_OCCURRENCE_DATA.MEASUREMENT_UNIT_KEY = MEASUREMENT_UNIT.MEASUREMENT_UNIT_KEY
INNER JOIN
  MEASUREMENT_QUALIFIER ON 
  TAXON_OCCURRENCE_DATA.MEASUREMENT_QUALIFIER_KEY = MEASUREMENT_QUALIFIER.MEASUREMENT_QUALIFIER_KEY
INNER JOIN
  MEASUREMENT_TYPE ON
  MEASUREMENT_UNIT.MEASUREMENT_TYPE_KEY = MEASUREMENT_TYPE.MEASUREMENT_TYPE_KEY
WHERE
  TAXON_OCCURRENCE_KEY = @TOCCKey
  and MEASUREMENT_TYPE.SHORT_NAME = 'Abundance'

SET @RETURNSTRING = str(cast(@AbundanceTotal as float))

Return @RETURNSTRING

END
