USE NBNData
GO

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

/*===========================================================================*\
  Description:	
		Gets a concatenated string of the Taxon_Designation
		Status Abbreviations used by SxBRC for a particular
		Taxon_List_Item_Key.

  Parameters:	
		@Taxon_List_Item_Key 		The Taxon_List_Item_Key of interest.
		@Taxon_Designation_Set_Key	The primary key of the Taxon_Designation_Set
									to look in.

  Created:	Apr 2015

  Last revision information:
    $Revision: 3 $
    $Date: 12/05/17 $
    $Author: AndyFoy $

\*===========================================================================*/
ALTER FUNCTION [dbo].[AFGetDesignationsSxBRC]
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

	DECLARE @OutputValues TABLE
	(
		Item		VARCHAR(100),
		SortOrder	INT
	)
	
	INSERT INTO	@OutputValues
	SELECT 
			CASE -- if no status abbreviation then use short name, otherwise use status abbr.
			WHEN TTDT.Status_Abbreviation IS NULL THEN TDT.Short_Name
			ELSE TTDT.Status_Abbreviation
		END,
		TTDT.Sort_Order

	FROM Index_Taxon_Designation ITD
	INNER JOIN Taxon_Designation_Type TDT ON TDT.Taxon_Designation_Type_Key = ITD.Taxon_Designation_Type_Key
	INNER JOIN Taxon_Designation_Set_Item TDSI ON	TDSI.Taxon_Designation_Type_Key = TDT.Taxon_Designation_Type_Key
	INNER JOIN Taxon_Designation_Set TDS ON TDS.Taxon_Designation_Set_Key = TDSI.Taxon_Designation_Set_Key
	LEFT JOIN SxBRC_Taxon_Designation_Types TTDT ON TTDT.Taxon_Designation_Type_Key = TDT.Taxon_Designation_Type_Key
	WHERE	ITD.Taxon_List_Item_Key		=	@Taxon_List_Item_Key
			-- Filters by Taxon_Designation_Set if the Key is not null
		AND (@Taxon_Designation_Set_Key IS NULL
		OR	TDS.Taxon_Designation_Set_Key	=	@Taxon_Designation_Set_Key)
	
	ORDER BY TTDT.Sort_Order

	SELECT	@ReturnValue	=
				-- Blank when this is the first value, otherwise
				-- the previous string plus the seperator
				CASE
					WHEN @ReturnValue IS NULL THEN ''
					ELSE @ReturnValue + @Seperator
				END + Item
	FROM		@OutputValues
	GROUP BY Item, SortOrder
	ORDER BY SortOrder
	
	-- Format the list of designations by concatenating similar types
	RETURN dbo.AFFormatDesignationsSxBRC(@ReturnValue)

END

GO
