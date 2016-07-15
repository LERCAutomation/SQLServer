USE NBNData
GO

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

/*===========================================================================*\
  Description:	
		Gets the last entry or changed date for a particular Taxon Occurrence,
		including the Taxon Determination, Sample, Survey Event and
		Survey Event Recorder.

  Parameters:	
		@Taxon_Occurrence_Key 		The Taxon_Occurrence_Key of interest.
		@DateType					Which date to return (1 = Entry, 2 = Changed).

  Created:	Apr 2016

  Last revision information:
    $Revision: 1 $
    $Date: 19/04/16 $
    $Author: AndyFoy $

\*===========================================================================*/

-- Drop the user function if it already exists
if exists (select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'AFTOCCLastUpdated')
	DROP FUNCTION dbo.AFTOCCLastUpdated
GO

-- Create the user function
CREATE FUNCTION [dbo].[AFTOCCLastUpdated]
(
	@Taxon_Occurrence_Key		CHAR(16),
	@DateType					INT
)
RETURNS	smalldatetime

AS
BEGIN
	
	DECLARE @TOCC_Entry		smalldatetime
	DECLARE @TOCC_Change	smalldatetime
	DECLARE @TDET_Entry		smalldatetime
	DECLARE @TDET_Change	smalldatetime
	DECLARE @S_Entry		smalldatetime
	DECLARE @S_Change		smalldatetime
	DECLARE @SE_Entry		smalldatetime
	DECLARE @SE_Change		smalldatetime
	DECLARE @SER_Entry		smalldatetime
	DECLARE @SER_Change		smalldatetime

	DECLARE @LastDate		smalldatetime

	-- Get date from Taxon_Occurrence
	SELECT @TOCC_Entry = TOCC.ENTRY_DATE
		,@TOCC_Change	= TOCC.CHANGED_DATE
		,@TDET_Entry	= TDET.ENTRY_DATE
		,@TDET_Change	= TDET.CHANGED_DATE
		,@S_Entry		= S.ENTRY_DATE
		,@S_Change		= S.CHANGED_DATE
		,@SE_Entry		= SE.ENTRY_DATE
		,@SE_Change		= SE.CHANGED_DATE
		,@SER_Entry		= SER.ENTRY_DATE
		,@SER_Change	= SER.CHANGED_DATE

	FROM TAXON_OCCURRENCE TOCC
	INNER JOIN TAXON_DETERMINATION TDET ON TDET.TAXON_OCCURRENCE_KEY = TOCC.TAXON_OCCURRENCE_KEY AND TDET.PREFERRED = 1
	INNER JOIN SAMPLE S ON S.SAMPLE_KEY = TOCC.SAMPLE_KEY
	INNER JOIN SURVEY_EVENT SE ON SE.SURVEY_EVENT_KEY = S.SURVEY_EVENT_KEY
	INNER JOIN SURVEY_EVENT_RECORDER SER ON SER.SURVEY_EVENT_KEY = SE.SURVEY_EVENT_KEY

	WHERE TOCC.Taxon_Occurrence_Key = @Taxon_Occurrence_Key

	SET @LastDate = @TOCC_Entry
	IF @TDET_Entry	> @LastDate SET @LastDate = @TDET_Entry
	IF @S_Entry		> @LastDate SET @LastDate = @S_Entry
	IF @SE_Entry	> @LastDate SET @LastDate = @SE_Entry
	IF @SER_Entry	> @LastDate SET @LastDate = @SER_Entry

	IF @DateType = 2
	BEGIN
		IF @TOCC_Change	> @LastDate SET @LastDate = @TOCC_Change
		IF @TDET_Change	> @LastDate SET @LastDate = @TDET_Change
		IF @S_Change	> @LastDate SET @LastDate = @S_Change
		IF @SE_Change	> @LastDate SET @LastDate = @SE_Change
		IF @SER_Change	> @LastDate SET @LastDate = @SER_Change
	END

	RETURN @LastDate

END

GO
