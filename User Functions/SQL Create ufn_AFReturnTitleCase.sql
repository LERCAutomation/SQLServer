USE NBNData
GO

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

/*===========================================================================*\
  Description:	
		Returns a given string in Title case, i.e. first letter of each
		word only in capitals (unless the word contains numerics).

  Parameters:	
		@SpatialRef			 		The spatial reference of interest.

  Created:	Aug 2015

  Last revision information:
    $Revision: 1 $
    $Date: 30/08/15 $
    $Author: AndyFoy $

\*===========================================================================*/

-- Drop the user function if it already exists
if exists (select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'AFReturnTitleCase')
	DROP FUNCTION dbo.AFReturnTitleCase
GO

-- Create the user function
CREATE FUNCTION AFReturnTitleCase
(
	@string VARCHAR(255)
)
RETURNS VARCHAR(255)

AS
BEGIN
	DECLARE @index INT					-- index
	DECLARE @lastindex INT				-- index of last word start
	DECLARE @length INT					-- input length
	DECLARE @char NCHAR(1)				-- current char
	DECLARE @first BIT					-- first letter flag (1/0)
	DECLARE @numerics BIT				-- word contains numbers flag (1/0)
	DECLARE @whitespaces VARCHAR(20)	-- characters considered as white space
	DECLARE @numbers VARCHAR(20)		-- characters considered as numbers
	DECLARE @output VARCHAR(255)		-- output string

	SET @index = 1
	SET @lastindex = 1
	SET @length = LEN(@string)
	SET @first = 1
	SET @numerics = 0
	SET @whitespaces = '[' + '(' + '/' + '\' + '.' + CHAR(13) + CHAR(10) + CHAR(9) + CHAR(160) + ' ' + ')' + ']'
	SET @numbers = '[0123456789]'
	SET @output = ''

	WHILE @index <= @length
	BEGIN
		-- Get the current character
		SET @char = SUBSTRING(@string, @index, 1)

		-- If this is the first character in a word
		-- then make it upper case
		IF @first = 1 
		BEGIN
			SET @output = @output + UPPER(@char)
			SET @lastindex = @index
			SET @first = 0
		END
		ELSE
		BEGIN
			-- If this word contains numbers then leave
			-- the character as it is
			IF @numerics = 1
				SET @output = @output + @char
			ELSE
				-- Otherwise make the character lower case
				SET @output = @output + LOWER(@char)
		END

		-- If no numbers have been found in this word
		-- yet then check this character
		IF @numerics = 0
		BEGIN
			-- If this character is a number then set
			-- the numerics flag
			IF @char LIKE @numbers
			BEGIN
				SET @numerics = 1

				-- If a number has only just been found in this word
				-- then restart the word again.
				IF (@index - @lastindex) > 1
				BEGIN
					SET @index = @lastindex
					SET @output = LEFT(@output, @lastindex)
				END
			END
		END

		-- If this character is one of the 'whitespace' characters
		-- then reset the start of the word and numerics flags
		IF @char LIKE @whitespaces
		BEGIN
			SET @first = 1
			SET @numerics = 0
		END

		-- Increment the character position
	    SET @index = @index + 1
	END

	RETURN @output
END

GO
