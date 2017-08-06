USE NBNData
GO

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

/*===========================================================================*\
  Description:	
		Return a the measurement formatted as a string in a specific
		way particular to SxBRC's requirements.

  Parameters:
		@MUnit						Short name for Unit.
		@MQualifier					Short name for Qualifier.
		@MData 						Actual Data value.

  Created:	Jul 2016

  Last revision information:
    $Revision: 1 $
    $Date: 08/07/16 $
    $Author: AndyFoy $

\*===========================================================================*/

-- Drop the user function if it already exists
if exists (select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'AFFormatMeasurementSxBRC')
	DROP FUNCTION dbo.AFFormatMeasurementSxBRC
GO

-- Create the user function
CREATE FUNCTION [dbo].[AFFormatMeasurementSxBRC]
(
	@MUnit varchar(40),
	@MQual varchar(40),
	@MData varchar(20)
)
RETURNS varchar(110)

AS
BEGIN
	DECLARE @Qual varchar(40)
	DECLARE @Unit varchar(40)
	DECLARE @Data varchar(20)
	DECLARE @RETURNDATA varchar (110)

	SET @RETURNDATA = ''

	-- Reformat or remove some data components
	SELECT @Data = CASE @MData
		WHEN NULL THEN ''
		ELSE @MData
	END

	-- Remove trailing full stops from the data component
	IF RIGHT(@Data, 1) = '.'
		SET @Data = LEFT(@Data, LEN(@Data) - 1)

	-- Reformat or remove some unit components
	SELECT @Unit = CASE @MUnit
		WHEN 'None' THEN ''
		WHEN 'Count' THEN ''
		WHEN 'Range' THEN ''
		ELSE @MUnit
	END

	-- Reformat or remove some qualifier components
	SELECT @Qual = CASE @MQual
		WHEN NULL THEN ''
		ELSE @MQual
	END

	-- If the data and qualifiers are both the same
	-- (e.g. 'Adult' and 'Adult') then clear the qualifier
	IF UPPER(@Data) = UPPER(@Qual)
		SET @Qual = ''

	-- Remove leading and trailing spaces from the components
	SET @Data = LTrim(RTrim(@Data))
	SET @Unit = LTrim(RTrim(@Unit))
	SET @Qual = LTrim(RTrim(@Qual))

	-- If the qualifier is not blank then prefix it with a space
	-- to separate it from the unit component
	IF @Qual <> ''
		SET @Qual = ' ' + @Qual

	-- Set the return value based on the data, unit and
	-- qualifier components
	IF @DATA <> ''
	BEGIN
		
		IF @Unit <> ''
			SET @RETURNDATA = @Data + ' ' + @Unit + @Qual + '; '
		ELSE
			SET @RETURNDATA = @Data + @Qual + '; '
	END
	ELSE
	BEGIN
		IF @Qual <> ''
			SET @RETURNDATA = RIGHT(@Qual, LEN(@Qual) - 1) + '; '
	END

	-- Clear the return value if it doesn't
	-- contain anything of value
	DECLARE @RC varchar (110)
	SELECT @RC = CASE @RETURNDATA
		WHEN '' THEN NULL
		ELSE @RETURNDATA
	END

	RETURN @RC
END

GO
