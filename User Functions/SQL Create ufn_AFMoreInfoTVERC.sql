USE NBNData
GO

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

/*===========================================================================*\
  Description:	
		Returns any Event Location Name or Sample Location Name details
		as more location information in a very specific way particular
		to TVERC's requirements.

  Parameters:
		@SampleKey					The key of the sample of interest.
		@LocationName				The name of the location linked to the
									sample.

  Created:	Sep 2015

  Last revision information:
    $Revision: 1 $
    $Date: 06/09/15 $
    $Author: AndyFoy $

\*===========================================================================*/

-- Drop the user function if it already exists
if exists (select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'AFMoreInfoTVERC')
	DROP FUNCTION dbo.AFMoreInfoTVERC
GO

-- Create the user function
CREATE FUNCTION [dbo].[AFMoreInfoTVERC]
(
	@SampleKey char(16),
	@LocationName varchar(100)
)
RETURNS varchar(100)

AS
BEGIN
	DECLARE @MoreInfo varchar(100)
	DECLARE @ReturnString varchar(100)

	-- Remove leading and trailing spaces from the sample location name
	SELECT @MoreInfo = LTrim(RTrim(LOCATION_NAME)) FROM SAMPLE WHERE SAMPLE_KEY = @SampleKey

	-- If the more info value is null then return that
	IF @MoreInfo IS NULL
		SET @ReturnString = NULL
	ELSE
	BEGIN
		-- Set upper case more info values to title case
		IF @MoreInfo = UPPER(@MoreInfo) COLLATE Latin1_General_CS_AS
			SELECT @MoreInfo = dbo.AFReturnTitleCase(@MoreInfo)

		-- Remove leading text matching the location name
		SELECT @ReturnString = CASE
			WHEN CHARINDEX(@MoreInfo, @LocationName) > 0 THEN ''

			WHEN @MoreInfo LIKE 'UKBMS ' + @LocationName + ' %' THEN LTRIM(REPLACE(@MoreInfo, 'UKBMS ' + @LocationName + ' ', ''))

			WHEN @MoreInfo LIKE @LocationName + ', %' THEN LTRIM(REPLACE(@MoreInfo, @LocationName + ', ', ''))
			WHEN @MoreInfo LIKE @LocationName + ' %' THEN LTRIM(REPLACE(@MoreInfo, @LocationName + ' ', ''))

			WHEN @MoreInfo LIKE 'Traps%, RSPB %' THEN LTRIM(SUBSTRING(@MoreInfo, CHARINDEX(', RSPB ', @MoreInfo) + 7, 100))

			ELSE @MoreInfo
		END

		-- Restore text if the first word remaining is ampersand, 'and' or 's'
		IF LEFT(@ReturnString, 2) = '& ' OR LEFT(@ReturnString, 4) = 'and ' OR LEFT(@ReturnString, 2) = 's '
			SET @ReturnString = @MoreInfo

		-- Remove leading or trailing spaces
		SET @MoreInfo = LTRIM(RTRIM(@ReturnString))

		-- Remove any text containing a river location name
		-- (allowing for any abbreviations of the word river)
		IF @LocationName LIKE 'River %'
		AND (@MoreInfo LIKE @LocationName + ' %'
		OR   @MoreInfo LIKE @LocationName + ', %'
		OR   @MoreInfo LIKE REPLACE(@LocationName, 'River ', 'R ') + '%'
		OR   @MoreInfo LIKE REPLACE(@LocationName, 'River ', 'R.') + '%'
		OR   @MoreInfo LIKE '% ' + @LocationName
		OR   @MoreInfo LIKE '% ' + REPLACE(@LocationName, 'River ', 'R ')
		OR   @MoreInfo LIKE '% ' + REPLACE(@LocationName, 'River ', 'R.')
		OR   @MoreInfo LIKE '% ' + REPLACE(@LocationName, 'River ', 'R. ')
		OR   @MoreInfo LIKE '%, ' + @LocationName + '%'
		OR   @MoreInfo LIKE '%, ' + REPLACE(@LocationName, 'River ', 'R ') + '%'
		OR   @MoreInfo LIKE '%, ' + REPLACE(@LocationName, 'River ', 'R.') + '%'
		OR   @MoreInfo LIKE '%, ' + REPLACE(@LocationName, 'River ', 'R. ') + '%')
		BEGIN
			SET @MoreInfo = REPLACE(@MoreInfo, @LocationName, '')
			SET @MoreInfo = REPLACE(@MoreInfo, REPLACE(@LocationName, 'River ', 'R '), '')
			SET @MoreInfo = REPLACE(@MoreInfo, REPLACE(@LocationName, 'River ', 'R.'), '')
			SET @MoreInfo = REPLACE(@MoreInfo, REPLACE(@LocationName, 'River ', 'R. '), '')
		END

		-- Remove trailing text matching the location name
		SELECT @ReturnString = CASE
			WHEN @MoreInfo LIKE '%, ' + @LocationName THEN REPLACE(@MoreInfo, ', ' + @LocationName, '')
			WHEN @MoreInfo LIKE '% ' + @LocationName THEN REPLACE(@MoreInfo, ' ' + @LocationName, '')

			ELSE @MoreInfo
		END

		-- Remove leading or trailing spaces
		SET @MoreInfo = LTRIM(RTRIM(@ReturnString))

		-- Remove surrounding brackets
		IF @MoreInfo LIKE '(%)'
			SET @MoreInfo = SUBSTRING(@MoreInfo, 2, LEN(@MoreInfo) - 2)

		-- Remove leading slashes
		IF @MoreInfo LIKE '/%'
			SET @MoreInfo = LTRIM(SUBSTRING(@MoreInfo, 2, 100))

		-- Remove leading colons
		IF @MoreInfo LIKE ':%'
			SET @MoreInfo = LTRIM(SUBSTRING(@MoreInfo, 2, 100))

		-- Remove leading semi-colons
		IF @MoreInfo LIKE ';%'
			SET @MoreInfo = LTRIM(SUBSTRING(@MoreInfo, 2, 100))

		-- Remove leading hashes
		IF @MoreInfo LIKE '#%'
			SET @MoreInfo = LTRIM(SUBSTRING(@MoreInfo, 2, 100))

		-- Remove leading slashes
		IF @MoreInfo LIKE '\%'
			SET @MoreInfo = LTRIM(SUBSTRING(@MoreInfo, 2, 100))

		-- Remove leading hyphens
		IF @MoreInfo LIKE '-%'
			SET @MoreInfo = LTRIM(SUBSTRING(@MoreInfo, 2, 100))

		-- Remove leading commas
		IF @MoreInfo LIKE ',%'
			SET @MoreInfo = LTRIM(SUBSTRING(@MoreInfo, 2, 100))

		-- Remove text relating to sections, areas, transects, etc.
		SELECT @ReturnString = CASE
			WHEN @MoreInfo LIKE '% ____  section' THEN LEFT(@MoreInfo, CHARINDEX('  section', @MoreInfo) - 6)
			WHEN @MoreInfo LIKE '% ____ section' THEN LEFT(@MoreInfo, CHARINDEX(' section', @MoreInfo) - 5)
			WHEN @MoreInfo LIKE '% ____  area' THEN LEFT(@MoreInfo, CHARINDEX('  area', @MoreInfo) - 6)
			WHEN @MoreInfo LIKE '% ____ area' THEN LEFT(@MoreInfo, CHARINDEX(' area', @MoreInfo) - 5)
			WHEN @MoreInfo LIKE '% - Butterfly Transect - __' THEN LEFT(@MoreInfo, CHARINDEX(' - Butterfly Transect', @MoreInfo))
			WHEN @MoreInfo LIKE '% - Odonata Transect - __' THEN LEFT(@MoreInfo, CHARINDEX(' - Odonata Transect', @MoreInfo))
			WHEN @MoreInfo LIKE '% - Transect - __' THEN LEFT(@MoreInfo, CHARINDEX(' - Transect', @MoreInfo))
			WHEN @MoreInfo LIKE '% Modified BBS Transect - Route %' THEN LEFT(@MoreInfo, CHARINDEX(' Modified BBS Transect', @MoreInfo))
			WHEN @MoreInfo LIKE '% Transect - Route %' THEN LEFT(@MoreInfo, CHARINDEX(' Transect - Route', @MoreInfo))
			WHEN @MoreInfo LIKE '% Refuge _' THEN LEFT(@MoreInfo, CHARINDEX(' Refuge ', @MoreInfo))
			WHEN @MoreInfo LIKE '% Refuge __' THEN LEFT(@MoreInfo, CHARINDEX(' Refuge ', @MoreInfo))
			WHEN @MoreInfo LIKE '% Bird box _' THEN LEFT(@MoreInfo, CHARINDEX(' Bird box ', @MoreInfo))
			WHEN @MoreInfo LIKE '% Bird box __' THEN LEFT(@MoreInfo, CHARINDEX(' Bird box ', @MoreInfo))
			WHEN @MoreInfo LIKE '% Dormouse box _' THEN LEFT(@MoreInfo, CHARINDEX(' Dormouse box ', @MoreInfo))
			WHEN @MoreInfo LIKE '% Dormouse box __' THEN LEFT(@MoreInfo, CHARINDEX(' Dormouse box ', @MoreInfo))

			WHEN @MoreInfo LIKE '%_, comp _, %' THEN LEFT(@MoreInfo, CHARINDEX(', comp ', @MoreInfo)) + SUBSTRING(@MoreInfo, CHARINDEX(', comp ', @MoreInfo) + 9, 100)
			WHEN @MoreInfo LIKE '%_, comp __, %' THEN LEFT(@MoreInfo, CHARINDEX(', comp ', @MoreInfo)) + SUBSTRING(@MoreInfo, CHARINDEX(', comp ', @MoreInfo) + 10, 100)

			WHEN @MoreInfo LIKE '%_, comp _' THEN LEFT(@MoreInfo, LEN(@MoreInfo) - 8)
			WHEN @MoreInfo LIKE '%_, comp __' THEN LEFT(@MoreInfo, LEN(@MoreInfo) - 9)
			WHEN @MoreInfo LIKE '%_, comp ___' THEN LEFT(@MoreInfo, LEN(@MoreInfo) - 10)

			WHEN @MoreInfo LIKE '%_, compartment [0-9]' THEN LEFT(@MoreInfo, LEN(@MoreInfo) - 15)
			WHEN @MoreInfo LIKE '%_, compartment [0-9][0-9]' THEN LEFT(@MoreInfo, LEN(@MoreInfo) - 16)
			WHEN @MoreInfo LIKE '%_- compartment [0-9]' THEN LEFT(@MoreInfo, LEN(@MoreInfo) - 15)
			WHEN @MoreInfo LIKE '%_- compartment [0-9][0-9]' THEN LEFT(@MoreInfo, LEN(@MoreInfo) - 16)

			ELSE @MoreInfo
		END

		-- Remove leading or trailing spaces
		SET @MoreInfo = LTRIM(RTRIM(@ReturnString))

		-- Remove text relating to compartments, tetrads and other terms
		SELECT @ReturnString = CASE
			WHEN @MoreInfo LIKE '(Compartment %)%' THEN ''
			WHEN @MoreInfo LIKE 'Compartment %' THEN ''
			WHEN @MoreInfo LIKE 'Compt %' THEN ''
			WHEN @MoreInfo LIKE 'Comps. %' THEN ''
			WHEN @MoreInfo LIKE 'Comps %' THEN ''
			WHEN @MoreInfo LIKE 'Comp. %' THEN ''
			WHEN @MoreInfo LIKE 'Comp %' THEN ''
			WHEN @MoreInfo LIKE 'Cpt %' THEN ''

			WHEN @MoreInfo LIKE '%: Compt %' THEN LEFT(@MoreInfo, CHARINDEX(': Compt ', @MoreInfo) - 1)
			WHEN @MoreInfo LIKE '%: Compts %' THEN LEFT(@MoreInfo, CHARINDEX(': Compts ', @MoreInfo) - 1)
			WHEN @MoreInfo LIKE '% Compt %' THEN LEFT(@MoreInfo, CHARINDEX(' Compt ', @MoreInfo))
			WHEN @MoreInfo LIKE '% Cpt %' THEN LEFT(@MoreInfo, CHARINDEX(' Cpt ', @MoreInfo))

			WHEN @MoreInfo LIKE 'Bat Boxes - Tree No%' THEN ''
			WHEN @MoreInfo LIKE 'Modified BBS Transect%' THEN ''
			WHEN @MoreInfo LIKE 'Butterfly Transect%' THEN ''
			WHEN @MoreInfo LIKE 'Transect%' THEN ''
			WHEN @MoreInfo LIKE 'Reptile mat - %' THEN ''

			WHEN @MoreInfo LIKE 'Dormouse Box _' THEN SUBSTRING(@MoreInfo, 15, 100)
			WHEN @MoreInfo LIKE 'Dormouse Box __' THEN SUBSTRING(@MoreInfo, 16, 100)
			WHEN @MoreInfo LIKE 'Dormouse Box ___' THEN SUBSTRING(@MoreInfo, 17, 100)
			WHEN @MoreInfo LIKE 'Dormouse _' THEN SUBSTRING(@MoreInfo, 11, 100)
			WHEN @MoreInfo LIKE 'Dormouse __' THEN SUBSTRING(@MoreInfo, 12, 100)
			WHEN @MoreInfo LIKE 'Dormouse ___' THEN SUBSTRING(@MoreInfo, 13, 100)

			WHEN @MoreInfo LIKE '%Tetrad ____' THEN LEFT(@MoreInfo, CHARINDEX('tetrad ', @MoreInfo) - 1)
			WHEN @MoreInfo LIKE '%Tetrad ______' THEN LEFT(@MoreInfo, CHARINDEX('tetrad ', @MoreInfo) - 1)
			WHEN @MoreInfo LIKE '%Tetrad __ ____' THEN LEFT(@MoreInfo, CHARINDEX('tetrad ', @MoreInfo) - 1)
			WHEN @MoreInfo LIKE '%Tetrad____' THEN LEFT(@MoreInfo, CHARINDEX('tetrad', @MoreInfo) - 1)
			WHEN @MoreInfo LIKE '%Tetrad__ ____' THEN LEFT(@MoreInfo, CHARINDEX('tetrad', @MoreInfo) - 1)
			WHEN @MoreInfo LIKE '% Tetrad' THEN LEFT(@MoreInfo, CHARINDEX(' tetrad', @MoreInfo))

			WHEN @MoreInfo LIKE '%/CT' THEN LEFT(@MoreInfo, CHARINDEX('CT', @MoreInfo) - 1)
			WHEN @MoreInfo LIKE '% CT' THEN LEFT(@MoreInfo, CHARINDEX(' CT', @MoreInfo))

			WHEN @MoreInfo LIKE 'Tetrad %' THEN SUBSTRING(@MoreInfo, 8, 100)

			WHEN @MoreInfo LIKE 'UKBMS %' THEN SUBSTRING(@MoreInfo, 6, 100)

			WHEN @MoreInfo LIKE '[6-7][INS][0-9]%' THEN ''
			WHEN @MoreInfo LIKE 'Area _' THEN ''
			WHEN @MoreInfo LIKE 'Area _' THEN ''
			WHEN @MoreInfo LIKE 'Area #[0-9]% cmpt %' THEN ''
			WHEN @MoreInfo LIKE 'Area #[0-9]% compt %' THEN ''
			WHEN @MoreInfo LIKE 'Patch _' THEN ''
			WHEN @MoreInfo LIKE 'Patch __' THEN ''
			WHEN @MoreInfo LIKE 'TN_' THEN ''
			WHEN @MoreInfo LIKE 'TN__' THEN ''
			WHEN @MoreInfo LIKE 'Trap _' THEN ''
			WHEN @MoreInfo LIKE 'Refuge _' THEN ''
			WHEN @MoreInfo LIKE 'Refuge __' THEN ''
			WHEN @MoreInfo LIKE 'Sect _' THEN ''
			WHEN @MoreInfo LIKE 'Sect __' THEN ''
			WHEN @MoreInfo LIKE 'Section _' THEN ''
			WHEN @MoreInfo LIKE 'Section __' THEN ''
			WHEN @MoreInfo LIKE 'Location _' THEN ''
			WHEN @MoreInfo LIKE 'Location __' THEN ''
			WHEN @MoreInfo LIKE 'Sample site _' THEN ''
			WHEN @MoreInfo LIKE 'Plot code _' THEN ''
			WHEN @MoreInfo LIKE 'Plot code __' THEN ''
			WHEN @MoreInfo LIKE 'Plot code_' THEN ''
			WHEN @MoreInfo LIKE 'Plot code__' THEN ''
			WHEN @MoreInfo LIKE 'Plot _ %' THEN ''
			WHEN @MoreInfo LIKE 'Plots _ %' THEN ''
			WHEN @MoreInfo LIKE 'Control Plant number _' THEN ''
			WHEN @MoreInfo LIKE 'Control Plant number __' THEN ''
			WHEN @MoreInfo LIKE 'Treatment _ (%) Plant number %' THEN ''
			WHEN @MoreInfo LIKE 'Tin number _ %' THEN ''

			WHEN @MoreInfo LIKE 'Pond _' THEN 'Pond'
			WHEN @MoreInfo LIKE 'Pond __' THEN 'Pond'
			WHEN @MoreInfo LIKE 'Field _' THEN 'Field'
			WHEN @MoreInfo LIKE 'Field __' THEN 'Field'
			WHEN @MoreInfo LIKE 'Field ___' THEN 'Field'
			WHEN @MoreInfo LIKE 'Hedge _' THEN 'Hedge'
			WHEN @MoreInfo LIKE 'Hedgerow _' THEN 'Hedgerow'
			WHEN @MoreInfo LIKE 'Meadow _' THEN 'Meadow'
			WHEN @MoreInfo LIKE 'Ditch _' THEN 'Ditch'
			WHEN @MoreInfo LIKE 'Reptile Tin _' THEN 'Reptile Tin'
			WHEN @MoreInfo LIKE 'Reptile Tin __' THEN 'Reptile Tin'
			WHEN @MoreInfo LIKE 'Nesting box no. __%' THEN 'Nesting box'

			ELSE @MoreInfo
		END

		-- Remove leading or trailing spaces
		SET @MoreInfo = LTRIM(RTRIM(@ReturnString))

		-- Remove text relating to sections, areas, boxes and BBOWT
		SELECT @ReturnString = CASE
			WHEN @MoreInfo LIKE 'Box ___' THEN ''
			WHEN @MoreInfo LIKE 'Birdbox _ %' THEN SUBSTRING(@MoreInfo, 10, 100)
			WHEN @MoreInfo LIKE 'Birdbox __ %' THEN SUBSTRING(@MoreInfo, 11, 100)
			WHEN @MoreInfo LIKE 'Birdbox ___ %' THEN SUBSTRING(@MoreInfo, 12, 100)

			WHEN @MoreInfo LIKE '%Nature Reserve section %.%' THEN LEFT(@MoreInfo, CHARINDEX('Nature Reserve section ', @MoreInfo) - 1)
			WHEN @MoreInfo LIKE '%Extension section %.%' THEN LEFT(@MoreInfo, CHARINDEX('Extension section ', @MoreInfo) - 1)
			WHEN @MoreInfo LIKE '%1 (central) section %.%' THEN LEFT(@MoreInfo, CHARINDEX('1 (central) section ', @MoreInfo) - 1)
			WHEN @MoreInfo LIKE '%section %.%' THEN LEFT(@MoreInfo, CHARINDEX('section ', @MoreInfo) - 1)

			WHEN @MoreInfo LIKE 'Reserve (BBOWT)%' THEN SUBSTRING(@MoreInfo, 15, 100)
			WHEN @MoreInfo LIKE 'BBOWT reserve %' THEN SUBSTRING(@MoreInfo, 14, 100)
			WHEN @MoreInfo LIKE 'BBOWT - %' THEN SUBSTRING(@MoreInfo, 8, 100)
			WHEN @MoreInfo LIKE 'BBOWT, %' THEN SUBSTRING(@MoreInfo, 7, 100)
			WHEN @MoreInfo LIKE 'BBOWT %' THEN SUBSTRING(@MoreInfo, 6, 100)
			WHEN @MoreInfo LIKE '(BBOWT) %' THEN SUBSTRING(@MoreInfo, 8, 100)

			ELSE @MoreInfo
		END

		-- Remove leading or trailing spaces
		SET @MoreInfo = LTRIM(RTRIM(@ReturnString))

		-- Remove trailing numbers
		SELECT @ReturnString = CASE
			WHEN @MoreInfo LIKE '% - [0-9][0-9]' THEN LEFT(@MoreInfo, LEN(@MoreInfo) - 4)
			
			WHEN @MoreInfo LIKE '% #[0-9]' THEN LEFT(@MoreInfo, LEN(@MoreInfo) - 2)
			WHEN @MoreInfo LIKE '% #[0-9][0-9]' THEN LEFT(@MoreInfo, LEN(@MoreInfo) - 3)

			ELSE @MoreInfo
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

		-- Remove leading hashes
		IF @ReturnString LIKE '#%'
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

		-- Remove trailing points
		IF @ReturnString LIKE '%.'
			SET @ReturnString = RTRIM(LEFT(@ReturnString, LEN(@ReturnString) - 1))

		-- Remove trailing commas
		IF @ReturnString LIKE '%,'
			SET @ReturnString = RTRIM(LEFT(@ReturnString, LEN(@ReturnString) - 1))

		-- Remove trailing slashes
		IF @ReturnString LIKE '%\'
		OR @ReturnString LIKE '%/'
			SET @ReturnString = RTRIM(LEFT(@ReturnString, LEN(@ReturnString) - 1))

		-- Remove trailing hyphens
		IF @ReturnString LIKE '%-'
			SET @ReturnString = RTRIM(LEFT(@ReturnString, LEN(@ReturnString) - 1))

		-- Remove leading or trailing spaces
		SET @ReturnString = LTRIM(RTRIM(@ReturnString))

		-- Clear text if nothing useful left
		IF @ReturnString IN ('NR', 'N/R', 'N.R.', 'Nature Reserve', 'Reserve', 'Berks', 'Bracknell', 'SSSI', 'LWS', 'part', 'UKBMS', 'SSSI', 'LWS', 'section', 'area', 'tetrad', 'unknown', 'ct')
			SET @ReturnString = NULL

		-- Clear text if only numbers left
		IF ISNUMERIC(@ReturnString) = 1
			SET @ReturnString = NULL

		-- Clear text if only one character left
		IF LEN(@ReturnString) = 1
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
