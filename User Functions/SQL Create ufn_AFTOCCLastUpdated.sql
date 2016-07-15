USE NBNData
GO

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

/*===========================================================================*\
  Description:	
		Gets the last entry or changed date for a particular Taxon Occurrence
		and Taxon Determination.

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

	DECLARE @LastDate		smalldatetime

	-- Get date from Taxon_Occurrence
	SELECT @TOCC_Entry = TOCC.ENTRY_DATE
		,@TOCC_Change	= TOCC.CHANGED_DATE
		,@TDET_Entry	= TDET.ENTRY_DATE
		,@TDET_Change	= TDET.CHANGED_DATE

	FROM TAXON_OCCURRENCE TOCC
	INNER JOIN TAXON_DETERMINATION TDET ON TDET.TAXON_OCCURRENCE_KEY = TOCC.TAXON_OCCURRENCE_KEY AND TDET.PREFERRED = 1

	WHERE TOCC.Taxon_Occurrence_Key = @Taxon_Occurrence_Key

	SET @LastDate = @TOCC_Entry
	IF @TDET_Entry	> @LastDate SET @LastDate = @TDET_Entry

	IF @DateType = 2
	BEGIN
		IF @TOCC_Change	> @LastDate SET @LastDate = @TOCC_Change
		IF @TDET_Change	> @LastDate SET @LastDate = @TDET_Change
	END

	RETURN @LastDate

END

GO
