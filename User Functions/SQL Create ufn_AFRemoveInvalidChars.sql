USE NBNData
GO

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

/*===========================================================================*\
  Description:
	Removes or converts any non-ascii characters, including TAB,
	Carriage Return and Line Feed to spaces or an ascii alternative

  Parameters:
	@string		The text to process.

  Created:	

  Last revision information:
    $Revision: 2 $
    $Date: 02/08/17 $
    $Author: Andy Foy $

\*===========================================================================*/

-- Drop the user function if it already exists
if exists (select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'AFRemoveInvalidChars')
	DROP FUNCTION dbo.AFRemoveInvalidChars
GO

-- Create the user function
CREATE FUNCTION [dbo].[AFRemoveInvalidChars](
	@string VARCHAR(500)
)
RETURNS VARCHAR(500)

AS
BEGIN	
	DECLARE	@trimmedString VARCHAR(500)

	-- Remove leading and trailing spaces.
	SET	@trimmedString = LTRIM(RTRIM(@string))

	-- Replace all TAB, CR and LF characters with a single space.
	SET @trimmedString = REPLACE(@trimmedString, CHAR(9), ' ')
	SET @trimmedString = REPLACE(@trimmedString, CHAR(10), ' ')
	SET @trimmedString = REPLACE(@trimmedString, CHAR(13), ' ')

	-- Replace all non-apostrophe characters with alternative.
	SET @trimmedString = REPLACE(@trimmedString, CHAR(145), CHAR(39))
	SET @trimmedString = REPLACE(@trimmedString, CHAR(146), CHAR(39))
	SET @trimmedString = REPLACE(@trimmedString, CHAR(166), CHAR(39))
	SET @trimmedString = REPLACE(@trimmedString, CHAR(212) + CHAR(199) + CHAR(214), CHAR(39))
	SET @trimmedString = REPLACE(@trimmedString, CHAR(212) + CHAR(199) + CHAR(216), CHAR(39))
	SET @trimmedString = REPLACE(@trimmedString, CHAR(227), CHAR(39))

	-- Replace all non-space characters with alternative.
	SET @trimmedString = REPLACE(@trimmedString, CHAR(160), CHAR(32))

	-- Replace all non-hyphen characters with alternative.
	SET @trimmedString = REPLACE(@trimmedString, CHAR(150), CHAR(45))
	SET @trimmedString = REPLACE(@trimmedString, CHAR(151), CHAR(45))

	-- Replace all accented characters with alternative.
	SET @trimmedString = REPLACE(@trimmedString, CHAR(211), CHAR(79))
	SET @trimmedString = REPLACE(@trimmedString, CHAR(233), CHAR(101))

	-- Replace duplicate spaces with a single space.
	SET @trimmedString = REPLACE(@trimmedString, '  ', ' ')

	-- Remove all double-quotes.
	SET @trimmedString = REPLACE(@trimmedString, '"', '')

	-- Remove all non-sensical characters.
	SET @trimmedString = REPLACE(@trimmedString, CHAR(198), '')
--	SET @trimmedString = REPLACE(@trimmedString, CHAR(199), '')
--	SET @trimmedString = REPLACE(@trimmedString, CHAR(214), '')
--	SET @trimmedString = REPLACE(@trimmedString, CHAR(216), '')

	RETURN @trimmedString
END

GO