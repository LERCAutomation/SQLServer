USE NBNData
GO

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

/*===========================================================================*\
  Description:	
		Gets a concatenated string of the Taxon_Designation_Keys for a
		particular Taxon_Designation_Set.

  Parameters:	
		@Taxon_Designation_Set_Key	The primary key of the Taxon_Designation_Set
									to look in.
		@Output_Format				The field to output:
										1. Short_Name
										2. Long Name
										3. Kind
										4. Status_Abbreviation 
										5. Is designated: Yes/No

  Created:	Mar 2015

  Last revision information:
    $Revision: 1 $
    $Date: 08/04/15 $
    $Author: AndyFoy $

\*===========================================================================*/

-- Drop the user function if it already exists
if exists (select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'AFGetSetDesignations')
	DROP FUNCTION dbo.AFGetSetDesignations
GO

-- Create the user function
CREATE FUNCTION [dbo].[AFGetSetDesignations]
(
	@Taxon_Designation_Set_Key	CHAR(16) = NULL,
	@Output_Format				SMALLINT	-- 1. Short_Name
											-- 2. Long Name
											-- 3. Kind
											-- 4. Status_Abbreviation 
											-- 5. Is Designated: Yes/No
)
RETURNS	VARCHAR(1000)

AS
BEGIN
	DECLARE @Seperator	VARCHAR(100)
	
	-- Gets the Seperator from the settings table.
	SELECT	@Seperator	=	Data
	FROM	Setting
	WHERE	Name		=	'DBListSep' 
	
	DECLARE	@ReturnValue	VARCHAR(1000)

	DECLARE @OutputValues	TABLE (
		Item	VARCHAR(100)
	)
	
	INSERT INTO	@OutputValues
	SELECT		CASE @Output_Format
					WHEN 1 THEN TDT.Short_Name
					WHEN 2 THEN TDT.Long_Name
					WHEN 3 THEN TDT.Kind
					WHEN 4 THEN -- Status abbreviation
							CASE -- if no status abbreviation then use short name, otherwise use status abbr.
								WHEN TDT.Status_Abbreviation IS NULL THEN TDT.Short_Name
								ELSE TDT.Status_Abbreviation
							END
					ELSE ''
				END
	FROM	Taxon_Designation_Type		TDT
	JOIN	Taxon_Designation_Set_Item	TDSI
		ON	TDSI.Taxon_Designation_Type_Key	=	TDT.Taxon_Designation_Type_Key
	JOIN	Taxon_Designation_Set		TDS
		ON	TDS.Taxon_Designation_Set_Key	=	TDSI.Taxon_Designation_Set_Key
	WHERE	(TDS.Taxon_Designation_Set_Key	=	@Taxon_Designation_Set_Key)
	
	IF @Output_Format = 5
		SET @ReturnValue = CASE -- Were there any matching designations?
							WHEN EXISTS(SELECT 1 FROM @OutputValues) THEN 'Yes'
							ELSE 'No'
						   END
	ELSE
		SELECT	@ReturnValue	=
					-- Blank when this is the first value, otherwise
					-- the previous string plus the seperator
					CASE
						WHEN @ReturnValue IS NULL THEN ''
						ELSE @ReturnValue + @Seperator
					END + Item
		FROM		@OutputValues
		GROUP BY	Item
	
	RETURN	@ReturnValue
END

GO
