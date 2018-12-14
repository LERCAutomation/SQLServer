USE NBNData
GO

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

/*===========================================================================*\
  Description:	
		Gets the last entry or changed date for a particular Sample, including
		it's Survey Event and Survey Event Recorder.

  Parameters:	
		@Sample_Key			 		The Sample_Key of interest.
		@DateType					Which date to return (1 = Entry, 2 = Changed).

  Created:	Apr 2016

  Last revision information:
    $Revision: 1 $
    $Date: 19/04/16 $
    $Author: AndyFoy $

\*===========================================================================*/

-- Drop the user function if it already exists
if exists (select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'AFSampleLastUpdated')
	DROP FUNCTION dbo.AFSampleLastUpdated
GO

-- Create the user function
CREATE FUNCTION [dbo].[AFSampleLastUpdated]
(
	@Sample_Key					CHAR(16),
	@DateType					INT
)
RETURNS	smalldatetime

AS
BEGIN
	
	DECLARE @S_Entry		smalldatetime
	DECLARE @S_Change		smalldatetime
	DECLARE @SE_Entry		smalldatetime
	DECLARE @SE_Change		smalldatetime
	DECLARE @SER_Entry		smalldatetime
	DECLARE @SER_Change		smalldatetime

	DECLARE @LastDate		smalldatetime

	-- Get date from Taxon_Occurrence
	SELECT @S_Entry		= MAX(S.ENTRY_DATE)
		,@S_Change		= MAX(S.CHANGED_DATE)
		,@SE_Entry		= MAX(SE.ENTRY_DATE)
		,@SE_Change		= MAX(SE.CHANGED_DATE)
		,@SER_Entry		= MAX(SER.ENTRY_DATE)
		,@SER_Change	= MAX(SER.CHANGED_DATE)

	FROM SAMPLE S
	INNER JOIN SURVEY_EVENT SE ON SE.SURVEY_EVENT_KEY = S.SURVEY_EVENT_KEY
	INNER JOIN SURVEY_EVENT_RECORDER SER ON SER.SURVEY_EVENT_KEY = SE.SURVEY_EVENT_KEY

	WHERE S.SAMPLE_KEY= @Sample_Key

	SET @LastDate = @S_Entry
	IF @SE_Entry	> @LastDate SET @LastDate = @SE_Entry
	IF @SER_Entry	> @LastDate SET @LastDate = @SER_Entry

	IF @DateType = 2
	BEGIN
		IF @S_Change	> @LastDate SET @LastDate = @S_Change
		IF @SE_Change	> @LastDate SET @LastDate = @SE_Change
		IF @SER_Change	> @LastDate SET @LastDate = @SER_Change
	END

	RETURN @LastDate

END

GO
