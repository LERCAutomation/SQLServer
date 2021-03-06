USE NBNData
GO

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

/*===========================================================================*\
  Description:	
		Gets a concatenated string of the Taxon_Designation Short_Name
		values for a particular Taxon_List_Item_Key.

  Parameters:	
		@Taxon_List_Item_Key 		The Taxon_List_Item_Key of interest.
		@Taxon_Designation_Set_Key	The primary key of the Taxon_Designation_Set
									to look in.

  Created:	Aug 2015

  Last revision information:
    $Revision: 2 $
    $Date: 11/10/17 $
    $Author: AndyFoy $

\*===========================================================================*/

-- Drop the user function if it already exists
if exists (select ROUTINE_NAME from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA = 'dbo' and ROUTINE_NAME = 'AFGetDesignations')
	DROP FUNCTION dbo.AFGetDesignations
GO

-- Create the user function
CREATE FUNCTION [dbo].[AFGetDesignations]
(
	@Taxon_List_Item_Key		CHAR(16),
	@Taxon_Designation_Set_Key	CHAR(16) = NULL
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
	SELECT DISTINCT
		TDT.Short_Name
	FROM	Index_Taxon_Designation ITD
	INNER JOIN Taxon_Designation_Type TDT ON TDT.Taxon_Designation_Type_Key = ITD.Taxon_Designation_Type_Key
	INNER JOIN Taxon_Designation_Set_Item TDSI ON TDSI.Taxon_Designation_Type_Key = TDT.Taxon_Designation_Type_Key
	INNER JOIN Taxon_Designation_Set TDS ON TDS.Taxon_Designation_Set_Key = TDSI.Taxon_Designation_Set_Key
	WHERE ITD.Taxon_List_Item_Key = @Taxon_List_Item_Key
	-- Filters by Taxon_Designation_Set if the Key is not null
	AND (@Taxon_Designation_Set_Key IS NULL
	OR TDS.Taxon_Designation_Set_Key = @Taxon_Designation_Set_Key)
	
	SELECT @ReturnValue	=
		-- Blank when this is the first value, otherwise
		-- the previous string plus the seperator
		CASE
			WHEN @ReturnValue IS NULL THEN ''
			ELSE @ReturnValue + @Seperator
		END + Item
	FROM @OutputValues
	GROUP BY Item
	
	RETURN	@ReturnValue
END

GO
