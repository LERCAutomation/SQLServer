USE NBNData
GO

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

/*===========================================================================*\
  Description:	
		Returns a semi-colon separated string of all abundance data for a
		given taxon occurrence.

		Needs additional UDF 'AFFormatMeasurementSxBRC' to do calculations

  Parameters:	
		@TOCCKey 					The Taxon_Occurrence_Key of interest.

  Created:	Jul 2016

  Last revision information:
    $Revision: 1 $
    $Date: 08/07/16 $
    $Author: AndyFoy $

\*===========================================================================*/

-- Drop the user function if it already exists
if exists (select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'AFFormatAbundanceDataSxBRC')
	DROP FUNCTION dbo.AFFormatAbundanceDataSxBRC
GO

-- Create the user function
CREATE FUNCTION [dbo].[AFFormatAbundanceDataSxBRC]
(
	@TOCCKey char(16)
)
RETURNS varchar(8000)

AS
BEGIN
	DECLARE @ReturnString varchar(8000)
	DECLARE @Abundance  varchar(8000)
	SET @Abundance = ''

	SELECT @Abundance = @Abundance + ISNULL(dbo.AFFormatMeasurementSxBRC(MEASUREMENT_UNIT.SHORT_NAME, MEASUREMENT_QUALIFIER.SHORT_NAME, TAXON_OCCURRENCE_DATA.DATA), '')

	FROM TAXON_OCCURRENCE_DATA
	INNER JOIN MEASUREMENT_UNIT ON TAXON_OCCURRENCE_DATA.MEASUREMENT_UNIT_KEY = MEASUREMENT_UNIT.MEASUREMENT_UNIT_KEY
	INNER JOIN MEASUREMENT_QUALIFIER ON TAXON_OCCURRENCE_DATA.MEASUREMENT_QUALIFIER_KEY = MEASUREMENT_QUALIFIER.MEASUREMENT_QUALIFIER_KEY
	INNER JOIN MEASUREMENT_TYPE ON MEASUREMENT_UNIT.MEASUREMENT_TYPE_KEY = MEASUREMENT_TYPE.MEASUREMENT_TYPE_KEY

	WHERE TAXON_OCCURRENCE_KEY = @TOCCKey and MEASUREMENT_TYPE.SHORT_NAME = 'Abundance'
 
	ORDER BY TAXON_OCCURRENCE_DATA.DATA

	If LEN(@Abundance) > 0 
	BEGIN
		SET @ReturnString = LEFT(@Abundance, LEN(@Abundance)-1)
	END

	--If @ReturnString LIKE '0; %'
	--	SET @ReturnString = SUBSTRING(@ReturnString, 4, 8000)

	--If @ReturnString LIKE '%; 0'
	--	SET @ReturnString = LEFT(@ReturnString, LEN(@ReturnString)-3)

	--If @ReturnString LIKE '%; 0; %'
	--	SET @ReturnString = REPLACE(@ReturnString, '; 0; ', '')

	--****************************************************************************************************
	RETURN @ReturnString
END

GO
