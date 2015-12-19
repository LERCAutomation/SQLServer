USE NBNData
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*===========================================================================*\
  Description:		Checks if one or more survey tags for a given survey
					are found in a string of survey tags.

  Parameters:
	@SurveyKey		The primary key of the survey to check.
	@SurveyTags	The string of survey tags to search.

  Created:	Dec 2015

  Last revision information:
    $Revision: 1 $
    $Date: 03/12/15 $
    $Author: Andyfoy $

\*===========================================================================*/

-- Drop the user function if it already exists
if exists (select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'AFSurveyTagFound')
	DROP FUNCTION dbo.AFSurveyTagFound
GO

-- Create the user function
CREATE FUNCTION dbo.AFSurveyTagFound(
	@SurveyKey	VARCHAR(16),
	@SurveyTags VARCHAR(1000)
)
RETURNS	BIT

AS
BEGIN

	DECLARE @TagFound BIT

	IF IsNull(@SurveyTags, '') = ''
		SET @TagFound = 0
	ELSE
	BEGIN
		IF EXISTS (
			SELECT 1
			FROM Survey_Tag ST
			INNER JOIN Concept C ON C.Concept_Key = ST.Concept_Key
			INNER JOIN Term T ON T.Term_Key = C.Term_Key
			WHERE ST.Survey_Key = @SurveyKey
			AND @SurveyTags LIKE '%' + T.Item_Name + '%'
			)
		BEGIN
			SET @TagFound = 1
		END
		ELSE
			SET @TagFound = 0
	END

	RETURN @TagFound

END
