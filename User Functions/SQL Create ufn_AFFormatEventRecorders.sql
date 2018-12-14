USE NBNData
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*===========================================================================*\
  Description:
	Function to return a semi-colon sperated string of all the sample recorders.

  Parameters:
	@SampleKey			Sample Key to retrieve recorders for.

  Created:	

  Last revision information:
    $Revision: 1 $
    $Date: 05/12/18 $
    $Author: Andy Foy $

\*===========================================================================*/

-- Drop the user function if it already exists
if exists (select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'AFFormatEventRecorders')
	DROP FUNCTION dbo.AFFormatEventRecorders
GO

CREATE FUNCTION [dbo].[AFFormatEventRecorders](@SampleKey char(16))
RETURNS varchar(8000)

AS
BEGIN

DECLARE @ReturnString varchar(8000)
DECLARE @ItemString varchar(70)
DECLARE @Title char(10)
DECLARE @Initials varchar(8)
DECLARE @Forename varchar(30)
DECLARE @Surname varchar(30)

DECLARE @Recorders varchar(8000)
SET @Recorders = ''

SELECT @Recorders = @Recorders +
	CASE
		WHEN INDIVIDUAL.FORENAME IS NOT NULL THEN INDIVIDUAL.FORENAME + ' ' + INDIVIDUAL.SURNAME
		WHEN INDIVIDUAL.INITIALS IS NOT NULL THEN INDIVIDUAL.INITIALS + ' ' + INDIVIDUAL.SURNAME
		WHEN INDIVIDUAL.TITLE IS NOT NULL THEN INDIVIDUAL.TITLE + ' ' + INDIVIDUAL.SURNAME
		ELSE INDIVIDUAL.SURNAME
	END + ';'
	--dbo.FormatIndividual(INDIVIDUAL.TITLE, INDIVIDUAL.INITIALS, INDIVIDUAL.FORENAME, INDIVIDUAL.SURNAME)+ ';'
FROM SAMPLE_RECORDER
LEFT JOIN SURVEY_EVENT_RECORDER ON SAMPLE_RECORDER.SE_RECORDER_KEY = SURVEY_EVENT_RECORDER.SE_RECORDER_KEY
LEFT JOIN INDIVIDUAL ON SURVEY_EVENT_RECORDER.NAME_KEY = INDIVIDUAL.NAME_KEY
WHERE SAMPLE_RECORDER.SAMPLE_KEY = @SampleKey
GROUP BY INDIVIDUAL.TITLE, INDIVIDUAL.INITIALS, INDIVIDUAL.FORENAME, INDIVIDUAL.SURNAME

	If LEN(@Recorders) > 0 
	BEGIN
		SET @ReturnString = LEFT(@Recorders, LEN(@Recorders)-1)
	END

RETURN @ReturnString

END
