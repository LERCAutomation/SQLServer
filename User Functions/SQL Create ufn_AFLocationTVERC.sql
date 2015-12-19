USE NBNData
GO

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

/*===========================================================================*\
  Description:	
		Returns a Location Name, Event Location Name or Sample Location
		Name in a very specific way particular to TVERC's requirements.

  Parameters:
		@SampleKey					The key of the sample of interest.

  Created:	Dec 2015

  Last revision information:
    $Revision: 1 $
    $Date: 06/09/15 $
    $Author: AndyFoy $

\*===========================================================================*/

-- Drop the user function if it already exists
if exists (select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'AFLocationTVERC')
	DROP FUNCTION dbo.AFLocationTVERC
GO

-- Create the user function
CREATE FUNCTION [dbo].[AFLocationTVERC]
(
	@SampleKey char(16)
)
RETURNS varchar(100)

AS
BEGIN
	DECLARE @Location varchar(100)
	DECLARE @ReturnString varchar(100)

	-- Get the location from the LOCATION_NAME table
	SELECT @Location = LN.ITEM_NAME
	FROM SAMPLE S
	INNER JOIN SURVEY_EVENT SE ON SE.SURVEY_EVENT_KEY = S.SURVEY_EVENT_KEY
	INNER JOIN LOCATION_NAME LN ON LN.LOCATION_KEY = SE.LOCATION_KEY
	WHERE SAMPLE_KEY = @SampleKey
	AND LN.PREFERRED = 1

	-- Get the location from the SURVEY_EVENT table
	IF ISNULL(@Location, '') = ''
	OR @Location = 'Unknown'
	OR @Location = '(Unknown)'
	OR @Location = 'Berkshire'
	OR @Location = 'Bracknell'
	OR @Location = 'Buckinghamshire'
	OR @Location LIKE 'S[0-9][0-9][0-9]'
	OR @Location LIKE 'S[0-9][0-9][0-9][0-9]'
	BEGIN
		SELECT @Location = SE.LOCATION_NAME
		FROM SAMPLE S
		INNER JOIN SURVEY_EVENT SE ON SE.SURVEY_EVENT_KEY = S.SURVEY_EVENT_KEY
		WHERE SAMPLE_KEY = @SampleKey
	END

	-- Get the location from the SAMPLE table
	IF ISNULL(@Location, '') = ''
	OR @Location = 'Unknown'
	OR @Location = '(Unknown)'
	OR @Location = 'Berkshire'
	OR @Location = 'Bracknell'
	OR @Location = 'Buckinghamshire'
	OR @Location LIKE 'S[0-9][0-9][0-9]'
	OR @Location LIKE 'S[0-9][0-9][0-9][0-9]'
	BEGIN
		SELECT @Location = S.LOCATION_NAME
		FROM SAMPLE S
		WHERE SAMPLE_KEY = @SampleKey
	END

	-- Remove unwanted names
	IF ISNULL(@Location, '') = ''
	OR @Location = 'Unknown'
	OR @Location = '(Unknown)'
	OR @Location = 'Berkshire'
	OR @Location = 'Bracknell'
	OR @Location = 'Buckinghamshire'
	OR @Location LIKE 'S[0-9][0-9][0-9]'
	OR @Location LIKE 'S[0-9][0-9][0-9][0-9]'
		SET @Location = NULL

	-- Remove leading and trailing spaces from the location
	SELECT @Location = LTrim(RTrim(@Location))

	-- If the more info value is null then return that
	IF @Location IS NULL
		SET @ReturnString = NULL
	ELSE
	BEGIN

		-- Set upper case locations to title case
		IF @Location = UPPER(@Location) COLLATE Latin1_General_CS_AS
			SELECT @Location = dbo.AFReturnTitleCase(@Location)

		-- Remove text relating to compartments, tetrads and other terms
		SELECT @ReturnString = CASE
			WHEN @Location LIKE 'Pond _, %' THEN RIGHT(@Location, LEN(@Location) - 7)
			WHEN @Location LIKE 'Pond __, %' THEN RIGHT(@Location, LEN(@Location) - 8)
			WHEN @Location LIKE 'Pond ___, %' THEN RIGHT(@Location, LEN(@Location) - 9)

			WHEN @Location LIKE '% - Area _' THEN LEFT(@Location, LEN(@Location) - 8)
			WHEN @Location LIKE '% - Area __' THEN LEFT(@Location, LEN(@Location) - 9)

			WHEN @Location LIKE '% - Site _' THEN LEFT(@Location, LEN(@Location) - 8)

			WHEN @Location LIKE '% - Modified BBS Transect - __' THEN LEFT(@Location, LEN(@Location) - 28)
			WHEN @Location LIKE '% - Modified BBS Transect - Route [0-9] - __' THEN LEFT(@Location, LEN(@Location) - 38)

			WHEN @Location LIKE '% - Butterfly Simple Transect' THEN LEFT(@Location, LEN(@Location) - 27)
			WHEN @Location LIKE '% - Butterfly Transect - __' THEN LEFT(@Location, LEN(@Location) - 25)
			WHEN @Location LIKE '% - Butterfly Transect - Extension - __' THEN LEFT(@Location, LEN(@Location) - 37)

			WHEN @Location LIKE '% - Odonata Transect - __' THEN LEFT(@Location, LEN(@Location) - 23)

			WHEN @Location LIKE '% - Transect - __' THEN LEFT(@Location, LEN(@Location) - 15)
			WHEN @Location LIKE '% - Transect - _____' THEN LEFT(@Location, LEN(@Location) - 18)

			WHEN @Location LIKE '% - Simple Transect' THEN LEFT(@Location, LEN(@Location) - 17)
			WHEN @Location LIKE '% - Simple Transect Route _' THEN LEFT(@Location, LEN(@Location) - 25)

			WHEN @Location LIKE '% - Reptile Plot - __' THEN LEFT(@Location, LEN(@Location) - 19)

			WHEN @Location LIKE '% -Section _' THEN LEFT(@Location, LEN(@Location) - 10)
			WHEN @Location LIKE '% - Section _' THEN LEFT(@Location, LEN(@Location) - 11)

			WHEN @Location LIKE '% Transect Route _' THEN LEFT(@Location, LEN(@Location) - 16)

			WHEN @Location LIKE '% Refuge _' THEN LEFT(@Location, LEN(@Location) - 8)
			WHEN @Location LIKE '% Refuge __' THEN LEFT(@Location, LEN(@Location) - 9)

			WHEN @Location LIKE '% path _' THEN LEFT(@Location, LEN(@Location) - 6)
			WHEN @Location LIKE '% path __' THEN LEFT(@Location, LEN(@Location) - 7)
			WHEN @Location LIKE '% path ___' THEN LEFT(@Location, LEN(@Location) - 8)
			WHEN @Location LIKE '% path _____' THEN LEFT(@Location, LEN(@Location) - 10)
			WHEN @Location LIKE '% path _____-__' THEN LEFT(@Location, LEN(@Location) - 13)

			WHEN @Location LIKE '%Compartment _' THEN LEFT(@Location, LEN(@Location) - 13)
			WHEN @Location LIKE '%Compartment __' THEN LEFT(@Location, LEN(@Location) - 14)
			WHEN @Location LIKE '%Compartments _ and _' THEN LEFT(@Location, LEN(@Location) - 20)
			WHEN @Location LIKE '%Compartments __ and __' THEN LEFT(@Location, LEN(@Location) - 22)

			WHEN @Location LIKE '% compt [0-9]%' THEN LEFT(@Location, CHARINDEX(' compt ', @Location))

			WHEN @Location LIKE '% cpt [0-9]%' THEN LEFT(@Location, CHARINDEX(' cpt ', @Location))

			WHEN @Location LIKE '% comp _' THEN LEFT(@Location, LEN(@Location) - 6)
			WHEN @Location LIKE '% comp __' THEN LEFT(@Location, LEN(@Location) - 7)

			WHEN @Location LIKE '% - Pond - [0-9][0-9] - ' THEN LEFT(@Location, CHARINDEX(' - pond - ', @Location))

			WHEN @Location LIKE '% Part _' THEN LEFT(@Location, LEN(@Location) - 6)



			WHEN @Location LIKE '% Field _' THEN LEFT(@Location, LEN(@Location) - 2)
			WHEN @Location LIKE '% Field __' THEN LEFT(@Location, LEN(@Location) - 3)
			WHEN @Location LIKE '% Field ___' THEN LEFT(@Location, LEN(@Location) - 4)

			WHEN @Location LIKE '% Pond _' THEN LEFT(@Location, LEN(@Location) - 2)

			WHEN @Location LIKE '% - Hedgerow __' THEN LEFT(@Location, LEN(@Location) - 3)
			WHEN @Location LIKE '% - Hedgerow ___' THEN LEFT(@Location, LEN(@Location) - 4)

			WHEN @Location LIKE '% Dormouse Box _' THEN LEFT(@Location, LEN(@Location) - 2)
			WHEN @Location LIKE '% Dormouse Box __' THEN LEFT(@Location, LEN(@Location) - 3)
			WHEN @Location LIKE '% Dormouse Box ___' THEN LEFT(@Location, LEN(@Location) - 4)

			WHEN @Location LIKE '% - Dormouse Box - __' THEN LEFT(@Location, LEN(@Location) - 5)
			WHEN @Location LIKE '% - Dormouse Box - __ - __' THEN LEFT(@Location, LEN(@Location) - 10)
			WHEN @Location LIKE '% - Dormouse Box - __ - ___' THEN LEFT(@Location, LEN(@Location) - 11)

			WHEN @Location LIKE '% raft _' THEN LEFT(@Location, LEN(@Location) - 2)
			WHEN @Location LIKE '% raft __' THEN LEFT(@Location, LEN(@Location) - 3)

			WHEN @Location LIKE '% Reptile Plot _.__' THEN LEFT(@Location, LEN(@Location) - 5)
			WHEN @Location LIKE '% Reptile Plot __.__' THEN LEFT(@Location, LEN(@Location) - 6)

			WHEN @Location LIKE '% Bank _' THEN LEFT(@Location, LEN(@Location) - 2)
			WHEN @Location LIKE '% Bank __' THEN LEFT(@Location, LEN(@Location) - 3)
			WHEN @Location LIKE '% Bank ___' THEN LEFT(@Location, LEN(@Location) - 4)


			WHEN @Location LIKE '% - Bat box T%' THEN LEFT(@Location, CHARINDEX(' - Bat box T', @Location))
			WHEN @Location LIKE '% - Bat Boxes - Tree No [0-9] - Box %' THEN LEFT(@Location, CHARINDEX(' - Bat Boxes - Tree No', @Location))
			WHEN @Location LIKE '% - Bat Boxes - Tree No [0-9][0-9] - Box %' THEN LEFT(@Location, CHARINDEX(' - Bat Boxes - Tree No', @Location))

			WHEN @Location LIKE '% #[0-9]' THEN LEFT(@Location, LEN(@Location) - 2)
			WHEN @Location LIKE '% #[0-9][0-9]' THEN LEFT(@Location, LEN(@Location) - 3)

			WHEN @Location LIKE 'Briers site _' THEN ''
			WHEN @Location LIKE 'Briers site __' THEN ''

			WHEN @Location LIKE 'Fields %' THEN ''

			WHEN @Location LIKE 'Compartment %' THEN ''
			WHEN @Location LIKE 'Compartments %' THEN ''

			WHEN @Location LIKE '% - [0-9]' THEN LEFT(@Location, LEN(@Location) - 3)
			WHEN @Location LIKE '% - [0-9][0-9]' THEN LEFT(@Location, LEN(@Location) - 4)
			WHEN @Location LIKE '% - [0-9][0-9][A-Z]' THEN LEFT(@Location, LEN(@Location) - 5)

			--WHEN @Location LIKE '% [0-9]' THEN LEFT(@Location, LEN(@Location) - 1)

			ELSE @Location
		END

		-- Remove leading or trailing spaces
		SET @ReturnString = LTRIM(RTRIM(@ReturnString))

		-- Remove surrounding brackets
		IF @ReturnString LIKE '(%)'
			SET @ReturnString = SUBSTRING(@ReturnString, 2, LEN(@ReturnString) - 2)

		-- Remove leading slashes
		IF @ReturnString LIKE '/%'
			SET @ReturnString = LTRIM(SUBSTRING(@ReturnString, 2, 100))

		-- Remove leading colons
		IF @ReturnString LIKE ':%'
			SET @ReturnString = LTRIM(SUBSTRING(@ReturnString, 2, 100))

		-- Remove leading semi-colons
		IF @ReturnString LIKE ';%'
			SET @ReturnString = LTRIM(SUBSTRING(@ReturnString, 2, 100))

		-- Remove leading slashes
		IF @ReturnString LIKE '\%'
			SET @ReturnString = LTRIM(SUBSTRING(@ReturnString, 2, 100))

		-- Remove leading hyphens
		IF @ReturnString LIKE '-%'
			SET @ReturnString = LTRIM(SUBSTRING(@ReturnString, 2, 100))

		-- Remove leading commas
		IF @ReturnString LIKE ',%'
			SET @ReturnString = LTRIM(SUBSTRING(@ReturnString, 2, 100))

		-- Remove trailing colons
		IF @ReturnString LIKE '%:'
			SET @ReturnString = RTRIM(LEFT(@ReturnString, LEN(@ReturnString) - 1))

		-- Remove trailing semi-colons
		IF @ReturnString LIKE '%;'
			SET @ReturnString = RTRIM(LEFT(@ReturnString, LEN(@ReturnString) - 1))

		-- Remove trailing commas
		IF @ReturnString LIKE '%,'
			SET @ReturnString = RTRIM(LEFT(@ReturnString, LEN(@ReturnString) - 1))

		-- Remove trailing points
		IF @ReturnString LIKE '%.'
			SET @ReturnString = RTRIM(LEFT(@ReturnString, LEN(@ReturnString) - 1))

		-- Remove trailing slashes
		IF @ReturnString LIKE '%\'
			SET @ReturnString = RTRIM(LEFT(@ReturnString, LEN(@ReturnString) - 1))

		-- Remove leading or trailing spaces
		SET @ReturnString = LTRIM(RTRIM(@ReturnString))

		-- Clear text if nothing useful left
		IF @ReturnString IN ('NR', 'N/R', 'N.R.', 'Nature Reserve', 'Reserve', 'Berks', 'SSSI', 'LWS', 'part', 'UKBMS', 'SSSI', 'LWS', 'section', 'area', 'tetrad', 'unknown')
			SET @ReturnString = NULL

		-- Clear text if only numbers left
		IF ISNUMERIC(@ReturnString) = 1
			SET @ReturnString = NULL

		-- Capitalise first letter
		IF LEN(@ReturnString) > 1
			SET @ReturnString = UPPER(LEFT(@ReturnString, 1)) + SUBSTRING(@ReturnString, 2, 100)
		ELSE
			SET @ReturnString = UPPER(@ReturnString)

		IF @ReturnString = ''
			SET @ReturnString = NULL
		
	END

	RETURN @ReturnString
END

GO
