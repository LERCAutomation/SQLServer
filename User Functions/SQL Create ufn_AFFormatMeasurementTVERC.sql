USE NBNData
GO

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

/*===========================================================================*\
  Description:	
		Return a the measurement formatted as a string as a very specific
		way particular to TVERC's requirements.

  Parameters:
		@MUnit						Short name for Unit.
		@MQualifier					Short name for Qualifier.
		@MData 						Actual Data value.
		@DAFORApplies				Whether the DAFOR scale applies to this
									species type (e.g. flora not fauna).

  Created:	Oct 2015

  Last revision information:
    $Revision: 1 $
    $Date: 01/10/15 $
    $Author: AndyFoy $

\*===========================================================================*/

-- Drop the user function if it already exists
if exists (select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'AFFormatMeasurementTVERC')
	DROP FUNCTION dbo.AFFormatMeasurementTVERC
GO

-- Create the user function
CREATE FUNCTION [dbo].[AFFormatMeasurementTVERC]
(
	@MUnit varchar(40),
	@MQual varchar(40),
	@Mdata varchar(20),
	@DAFORApplies char(1)
)
RETURNS varchar(110)

AS
BEGIN
	DECLARE @Qual varchar(40)
	DECLARE @Unit varchar(40)
	DECLARE @Data varchar(20)
	DECLARE @TData varchar(20)
	DECLARE @RETURNDATA varchar (110)

	SET @RETURNDATA = ''

	-- Remove leading and trailing spaces from the measurement
	-- components
	SET @Data = LTrim(RTrim(@Data))
	SET @Unit = LTrim(RTrim(@Unit))
	SET @Qual = LTrim(RTrim(@Qual))

	-- Reformat or remove some data components
	SELECT @Data = CASE @MData
		WHEN NULL THEN ''
		WHEN 'P' THEN ''
		WHEN 'Presence' THEN ''
		WHEN 'Present' THEN ''
		WHEN 'n/a' THEN ''
		WHEN 'na' THEN ''
		WHEN '+' THEN ''
		WHEN 'Y' THEN ''
		WHEN 'Yes' THEN ''
		WHEN 'one' THEN '1'
		WHEN 'two' THEN '2'
		WHEN 'three' THEN '3'
		WHEN 'four' THEN '4'
		WHEN 'five' THEN '5'
		WHEN 'six' THEN '6'
		WHEN 'seven' THEN '7'
		WHEN 'eight' THEN '8'
		WHEN 'nine' THEN '9'
		WHEN 'ten' THEN '10'
		WHEN 'on site' THEN ''
		WHEN 'sev.' THEN 'Several'
		WHEN 'several' THEN 'Several'
		ELSE @MData
	END

	-- Remove trailing full stops from the data component
	IF RIGHT(@Data, 1) = '.'
		SET @Data = LEFT(@Data, LEN(@Data) - 1)

	-- Reformat or remove some unit components
	SELECT @Unit = CASE @MUnit
		WHEN 'None'THEN ''
		WHEN 'Count' THEN ''
		WHEN 'Observed' THEN ''
		WHEN 'Presence' THEN ''
		WHEN 'Range' THEN ''
		ELSE @MUnit
	END

	-- Reformat or remove some qualifier components
	SELECT @Qual = CASE @MQual
		WHEN 'None' THEN ''
		WHEN 'Count' THEN ''
		WHEN 'Present' THEN ''
		WHEN 'Presence' THEN ''
		WHEN 'Species' THEN ''
	--	WHEN 'Individual' THEN ''
	--	WHEN 'Ind' THEN ''
		WHEN 'Ind' THEN 'Individual'
		WHEN 'Default' THEN ''
		ELSE REPLACE(@MQual, '/', '/ ')
	END

	-- If DAFOR units can apply to this species type
	IF @DAFORApplies = 'Y'
	BEGIN

		-- Abbreviate and standardise the data component
		SET @TData = UPPER(@Data)
		SELECT @Data = CASE @TData
			WHEN 'DOMINANT' THEN 'D'
			WHEN 'ABUNDANT' THEN 'A'
			WHEN 'FREQUENT' THEN 'F'
			WHEN 'OCCASSIONAL' THEN 'O'
			WHEN 'OCCASIONAL' THEN 'O'
			WHEN 'RARE' THEN 'R'
			WHEN 'LOCALLY DOMINANT' THEN 'LD'
			WHEN 'LOCALLY ABUNDANT' THEN 'LA'
			WHEN 'loc. dom' THEN 'LD'
			WHEN 'loc. abun' THEN 'LA'
			WHEN 'loc. frqt' THEN 'LF'
			WHEN 'loc. occ' THEN 'LO'
			WHEN 'loc dom' THEN 'LD'
			WHEN 'loc abun' THEN 'LA'
			WHEN 'loc frqt' THEN 'LF'
			WHEN 'loc occ' THEN 'LO'
			WHEN 'LOCALLY FREQUENT' THEN 'LF'
			WHEN 'VLD' THEN 'LD'
			WHEN 'VLA' THEN 'LA'
			WHEN 'VLF' THEN 'LF'
			WHEN 'VLO' THEN 'LO'
			WHEN 'VLR' THEN 'LR'
			WHEN 'VD' THEN 'D'
			WHEN 'VA' THEN 'A'
			WHEN 'VF' THEN 'F'
			WHEN 'VO' THEN 'O'
			WHEN 'VR' THEN 'R'
			WHEN 'A / LR' THEN 'A/LR'
			WHEN 'A (LD)' THEN 'A/LD'
			WHEN 'A.LD' THEN 'A/LD'
			WHEN 'F (LA)' THEN 'F/LA'
			WHEN 'F (LD)' THEN 'F/LD'
			WHEN 'F / LD' THEN 'F/LD'
			WHEN 'FA' THEN 'F/A'
			WHEN 'L/D' THEN 'LD'
			WHEN 'L/A' THEN 'LA'
			WHEN 'L/F' THEN 'LF'
			WHEN 'L/O' THEN 'LO'
			WHEN 'L/R' THEN 'LR'
			WHEN 'LO`' THEN 'LO'
			WHEN 'O (LD)' THEN 'O/LD'
			WHEN 'O (LA)' THEN 'O/LA'
			WHEN 'O (LF)' THEN 'O/LF'
			WHEN 'O (LR)' THEN 'O/LR'
			WHEN 'OF' THEN 'O/F'
			WHEN 'R (LD)' THEN 'R/LD'
			WHEN 'R (LO)' THEN 'R/LO'
			WHEN 'R (LF)' THEN 'R/LF'
			WHEN 'R (LA)' THEN 'R/LA'
			WHEN 'RO' THEN 'R/O'
			WHEN 'D-A' THEN 'D/A'
			WHEN 'D-F' THEN 'D/F'
			WHEN 'D-O' THEN 'D/O'
			WHEN 'D-R' THEN 'D/R'
			WHEN 'D-LA' THEN 'D/LA'
			WHEN 'D-LF' THEN 'D/LF'
			WHEN 'D-LO' THEN 'D/LO'
			WHEN 'D-LR' THEN 'D/LR'
			WHEN 'F-D' THEN 'F/D'
			WHEN 'F-A' THEN 'F/A'
			WHEN 'F-O' THEN 'F/O'
			WHEN 'F-R' THEN 'F/R'
			WHEN 'F-LD' THEN 'F/LD'
			WHEN 'F-LA' THEN 'F/LA'
			WHEN 'F-LO' THEN 'F/LO'
			WHEN 'F-LR' THEN 'F/LR'
			WHEN 'O-D' THEN 'O/D'
			WHEN 'O-A' THEN 'O/A'
			WHEN 'O-F' THEN 'O/F'
			WHEN 'O-R' THEN 'O/R'
			WHEN 'O-LD' THEN 'O/LD'
			WHEN 'O-LA' THEN 'O/LA'
			WHEN 'O-LF' THEN 'O/LF'
			WHEN 'O-LR' THEN 'O/LR'
			WHEN 'R-D' THEN 'R/D'
			WHEN 'R-A' THEN 'R/A'
			WHEN 'R-F' THEN 'R/F'
			WHEN 'R-O' THEN 'R/O'
			WHEN 'R-LD' THEN 'R/LD'
			WHEN 'R-LA' THEN 'R/LA'
			WHEN 'R-LF' THEN 'R/LF'
			WHEN 'R-LO' THEN 'R/LO'
			ELSE @TData
		END

		-- If the data component is DAFOR related then
		-- make sure the unit is DAFOR
		IF @Data IN ('D', 'A', 'F', 'O', 'R',
					'LD', 'LA', 'LF','LO', 'LR',
					'L/D', 'L/A', 'L/F',' L/O', 'L/R',
					'D/L', 'A/L', 'F/L', 'O/L', 'R/L',
					'A/D', 'A/F', 'A/O', 'A/R', 'A/LD', 'A/LA', 'A/LF', 'A/LR', 
					'D/A', 'D/F', 'D/O', 'D/R', 'D/LA', 'D/LF',
					'F/A', 'F/O', 'F/LD', 'F/LA', 'F/LO', 'F/LR',
					'LA/D', 'LA/F', 'LA/LD', 'LA/O', 'LA/R',
					'LD/A', 'LD/F', 'LD/LA' ,'LD/O', 'LD/R',
					'LF/D', 'LF/A', 'LF/O', 'LF/R', 'LF/LO',
					'LO/D', 'LO/A', 'LO/F', 'LO/R',
					'O/D', 'O/A', 'O/F', 'O/R', 'O/LD', 'O/LA', 'O/LF', 'O/LR',
					'R/D', 'R/A', 'R/F', 'R/O', 'R/LD', 'R/LA', 'R/LF', 'R/LO',
					'?F', '?R'
					)
			SET @Unit = '(DAFOR)'
		ELSE
		BEGIN
			-- If the data component is not DAFOR related but
			-- the unit is then clear them both as they are
			-- not compatible
			IF @Unit = 'DAFOR'
				SET @Data = ''
				SET @Unit = ''
		END

	END
	-- If DAFOR units cannot apply to this species type
	ELSE
	BEGIN

		-- If the unit is DAFOR and the data component is 
		-- clearly DAFOR related then set the unit to DAFOR
		IF @Unit = 'DAFOR'
		BEGIN
			IF @Data IN ('D', 'A', 'F', 'O', 'R',
						'LD', 'LA', 'LF','LO', 'LR',
						'L/D', 'L/A', 'L/F',' L/O', 'L/R',
						'D/L', 'A/L', 'F/L', 'O/L', 'R/L',
						'A/D', 'A/F', 'A/O', 'A/R', 'A/LD', 'A/LA', 'A/LF', 'A/LR', 
						'D/A', 'D/F', 'D/O', 'D/R', 'D/LA', 'D/LF',
						'F/A', 'F/O', 'F/LD', 'F/LA', 'F/LO', 'F/LR',
						'LA/D', 'LA/F', 'LA/LD', 'LA/O', 'LA/R',
						'LD/A', 'LD/F', 'LD/LA' ,'LD/O', 'LD/R',
						'LF/D', 'LF/A', 'LF/O', 'LF/R', 'LF/LO',
						'LO/D', 'LO/A', 'LO/F', 'LO/R',
						'O/D', 'O/A', 'O/F', 'O/R', 'O/LD', 'O/LA', 'O/LF', 'O/LR',
						'R/D', 'R/A', 'R/F', 'R/O', 'R/LD', 'R/LA', 'R/LF', 'R/LO',
						'?F', '?R'
						)
				SET @Unit = '(DAFOR)'
			ELSE
			-- If the unit is DAFOR but the data component is 
			-- not DAFOR related then clear them both as they
			-- are not compatible
			BEGIN
				SET @Data = ''
				SET @Unit = ''
			END
		END

	END

	-- If the data and qualifiers are both the same
	-- (e.g. 'Adult' and 'Adult') then clear the qualifier
	IF UPPER(CAST(@Data as varchar)) = UPPER(@Qual)
		SET @Qual = ''

	-- Reset the plural data flag
	DECLARE @Plural bit
	SET @Plural = 0

	-- If there is a qualifier component
	IF @Qual <> ''
	BEGIN
		-- Set the plural flag based on the data component
		SELECT @Plural = CASE
			WHEN ISNUMERIC(@Data) = 1 AND (REPLACE(REPLACE(@Data, '.', ''), ',', '') > 1 OR REPLACE(REPLACE(@Data, '.', ''), ',', '') = 0) THEN 1
			WHEN LEFT(@Data, 1) = 'c' AND ISNUMERIC(RIGHT(@Data, Len(@Data)- 1)) = 1 THEN 1
			WHEN @Data = 'Several' THEN 1
			WHEN @Data = 'Absent' THEN 1
			WHEN @Data = 'Present' THEN 1
			WHEN @Data = 'Many' THEN 1
			WHEN @Data = 'Numerous' THEN 1
			WHEN @Data LIKE 'sev. %' THEN 1
			WHEN @Data = 'lots' THEN 1
			WHEN @Data LIKE '>%' AND @Data <> '>1' THEN 1
			WHEN @Data LIKE '%+%' AND @Data NOT LIKE '1+%' THEN 1
			WHEN @Data LIKE '<%' AND @Data NOT LIKE '<1' AND @Data NOT LIKE '< 1' THEN 1
			WHEN @Data LIKE '%-%' THEN 1
			WHEN @Data LIKE '% to %' THEN 1
			WHEN @Data LIKE '% or %' THEN 1
			WHEN @Data = '' THEN 1
			ELSE 0
		END

		-- If the data is plural then make sure the qualifier
		-- is plural
		IF @Plural = 1
		BEGIN
			SELECT @Qual = CASE
				WHEN @Qual = 'Exuvia' THEN 'Exuviae'
				WHEN @Qual = 'Larva' THEN 'Larvae'
				WHEN @Qual = 'Pupa' THEN 'Pupae'
				WHEN @Qual = 'Egg/ Ovum' THEN 'Eggs/ Ova'
				WHEN @Qual = 'Colony' THEN 'Colonies'
				WHEN @Qual = 'Fruitbody' THEN 'Fruitbodies'
				WHEN @Qual = 'Territory' THEN 'Territories'
				WHEN RIGHT(@Qual,4) = 'PAIR' THEN @Qual + 's'
				WHEN RIGHT(@Qual,4) = 'NEST' THEN @Qual + 's'
				WHEN RIGHT(@Qual,6) = 'FEMALE' THEN @Qual + 's'
				WHEN RIGHT(@Qual,4) = 'MALE' THEN @Qual + 's'
				WHEN RIGHT(@Qual,5) = 'ADULT' THEN @Qual + 's'
				WHEN RIGHT(@Qual,3) = 'EGG' THEN @Qual + 's'
				WHEN RIGHT(@Qual,10) = 'INDIVIDUAL' THEN @Qual + 's'
				WHEN RIGHT(@Qual,8) = 'JUVENILE' THEN @Qual + 's'
				WHEN RIGHT(@Qual,8) = 'IMMATURE' THEN @Qual + 's'
				WHEN RIGHT(@Qual,5) = 'CHICK' THEN @Qual + 's'
				WHEN RIGHT(@Qual,5) = 'CLUMP' THEN @Qual + 's'
				WHEN RIGHT(@Qual,7) = 'TADPOLE' THEN @Qual + 's'
				WHEN RIGHT(@Qual,4) = 'SETT' THEN @Qual + 's'
				WHEN RIGHT(@Qual,5) = 'BROOD' THEN @Qual + 's'
				WHEN RIGHT(@Qual,6) = 'BURROW' THEN @Qual + 's'
				WHEN RIGHT(@Qual,4) = 'NEST' THEN @Qual + 's'
				WHEN RIGHT(@Qual,9) = 'FLEDGLING' THEN @Qual + 's'
				WHEN RIGHT(@Qual,9) = 'HATCHLING' THEN @Qual + 's'
				WHEN RIGHT(@Qual,4) = 'SEED' THEN @Qual + 's'
				WHEN RIGHT(@Qual,8) = 'SEEDLING' THEN @Qual + 's'
				WHEN RIGHT(@Qual,5) = 'SPORE' THEN @Qual + 's'
				WHEN RIGHT(@Qual,6) = 'WORKER' THEN @Qual + 's'
				WHEN RIGHT(@Qual,3) = 'CUB' THEN @Qual + 's'
				WHEN RIGHT(@Qual,4) = 'GALL' THEN @Qual + 's'
				WHEN RIGHT(@Qual,7) = 'GOSLING' THEN @Qual + 's'
				WHEN RIGHT(@Qual,7) = 'LATRINE' THEN @Qual + 's'
				WHEN RIGHT(@Qual,8) = 'MOLEHILL' THEN @Qual + 's'
				ELSE @Qual
			END
		END
		ELSE
		BEGIN
			-- Make sure the qualifier is singlular
			SELECT @Qual = CASE
				WHEN @Qual = 'Species' THEN 'Species'
				WHEN @Qual = 'Patches' THEN 'Patch'
				WHEN @Qual = 'Thallus' THEN 'Thallus'
				WHEN @Qual = 'Exuviae' THEN 'Exuvia'
				WHEN @Qual = 'Larvae' THEN 'Larva'
				WHEN @Qual = 'Pupae' THEN 'Pupa'
				WHEN @Qual = 'Broods' THEN 'Brood'
				WHEN @Qual = 'Groups' THEN 'Group'
				WHEN @Qual = 'Patches' THEN 'Patch'
				WHEN @Qual = 'Droppings' THEN 'Dropping'
				WHEN RIGHT(@Qual, 1) = 's' THEN LEFT(@Qual, LEN(@Qual) - 1)
				ELSE @Qual
			END
		END
	END

	-- If the data contains a range (i.e. a hyphen) then replace
	-- the hyphen with 'to'
	IF @Data LIKE '%_-%'
		SET @Data = REPLACE(REPLACE(@Data, ' - ', ' to '), '-', ' to ')

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
		WHEN 'P; ' THEN NULL
		WHEN '0; ' THEN NULL
	--	WHEN 'Some' THEN NULL
		ELSE @RETURNDATA
	END

	RETURN @RC
END

GO
