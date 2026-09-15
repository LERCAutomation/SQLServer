USE [NBNData]
GO
/****** Object:  UserDefinedFunction [gis].[AFFormatDesignationsSBIC]    Script Date: 18/12/2018 12:09:42 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

-- Create the user function
ALTER FUNCTION [gis].[AFFormatDesignationsSBIC]
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
SET @FirstDesig = CHARINDEX('WCA Sch5 ', @WholePart)

IF @FirstDesig > 0
BEGIN

	SET @FirstPart = LEFT(@WholePart, @FirstDesig + 9 ) 
	SET @SecondPart = RIGHT(@WholePart, LEN(@WholePart) - (@FirstDesig + 9))
	
	SET @SecondPart = REPLACE(@SecondPart,'WCA Sch5 ','/')
	SET @SecondPart = REPLACE(@SecondPart,', /','/')
	SET @TextOut = @FirstPart + @SecondPart
    
END
ELSE

     SET @TextOut = @WholePart

RETURN @TextOut

END
