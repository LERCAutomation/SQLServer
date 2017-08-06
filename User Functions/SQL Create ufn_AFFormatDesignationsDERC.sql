USE NBNData
GO

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

/*===========================================================================*\
  Description:	
		Return a formatted string of taxon designations in a more
		concentrated way.

  Parameters:
		@TextIn						The string of taxon designations to be
									formatted.

  Created:	Dec 2015

  Last revision information:
    $Revision: 2 $
    $Date: 13/01/16 $
    $Author: AndyFoy $

\*===========================================================================*/

-- Drop the user function if it already exists
if exists (select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'AFFormatDesignationsDERC')
	DROP FUNCTION dbo.AFFormatDesignationsDERC
GO

-- Create the user function
CREATE FUNCTION [dbo].[AFFormatDesignationsDERC]
(
	@TextIn varchar(200)
)
RETURNS varchar(200)

AS
BEGIN

DECLARE @TextOut varchar (200)
DECLARE @FirstDesig int
DECLARE @FirstPart varchar(200)
DECLARE @SecondPart varchar(200)
DECLARE @WholePart varchar(200)

SET @WholePart = @TextIn
SET @FirstDesig = CHARINDEX('WACA-Sch5-', @WholePart)

IF @FirstDesig > 0
BEGIN

	SET @FirstPart = LEFT(@WholePart, @FirstDesig + 10 ) 
	SET @SecondPart = RIGHT(@WholePart, LEN(@WholePart) - (@FirstDesig + 10))
	     
	SET @SecondPart = REPLACE(@SecondPart,'WACA-Sch5-','/')
	SET @SecondPart = REPLACE(@SecondPart,', /','/')
	SET @TextOut = @FirstPart + @SecondPart
         
END
ELSE

     SET @TextOut = @WholePart

RETURN @TextOut

END

GO
