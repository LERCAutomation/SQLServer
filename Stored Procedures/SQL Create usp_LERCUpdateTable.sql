-- Create the stored procedure
CREATE PROCEDURE [dbo].[LERCUpdateTable]
AS
BEGIN

	/*===========================================================================*\
	  Description:
			Extracts species occurrences and associated details from the
			Recorder 6 tables and 'flattens' them into a new 'master'
			table for use in data searches and for sending to partners.
	
	  Parameters:		None
	
	  Created:			Jul 2017
	  Last revised:		Jul 2018
	
	 *****************  Version 7  *****************
	 Author: Andy Foy		Date: 31/07/2018
	 A. Indicate truncation of Comments, DeterminerComments
	    and SampleComments with ' ...'.
	 B. Truncate ObsSource to 254 chars.
	 C. Increase length of Recorder field (and truncate
		if necessary).
	 D. Store Recorder and Determiner values in PrivateRecorder
		and PrivateDeterminer fields to comply with GDPR.
	 E. Exclude records with date 'Unknown'.
	 F. Add SurveyRef.
	 G. Reduce length of TaxonName, CommonName, Recorder,
		Abundance and SurveyRunBy fields.
	 H. Add parameter to Survey table to exclude whole survey.
	
	 *****************  Version 6  *****************
	 Author: Andy Foy		Date: 09/02/2018
	 A. Drop indexes before rebuilding table.
	
	 *****************  Version 5  *****************
	 Author: Andy Foy		Date: 01/10/2017
	 A. Convert to stored procedure.
	 B. Write outputs to log table.
	 C. Change parameters to AFSpatialiseSppView store procedure.
	
	 *****************  Version 5  *****************
	 Author: Andy Foy		Date: 15/08/2016
	 A. Include Provenance and DeterminerComments fields.
	 B. Clear Determiner field if name is one of the Recorders.
	
	 *****************  Version 4  *****************
	 Author: Andy Foy		Date: 10/08/2016
	 A. Change to use abbreviations for the status columns.
	
	 *****************  Version 3  *****************
	 Author: Andy Foy		Date: 24/07/2016
	 A. Include SampleComments and ObsSource fields.
	 B. Truncate Comments and SampleComments fields to 254 chars.
	 C. Add confidential and sensitive location/grid ref
	    logic to Taxon_Group and Taxon_Name tables.
	
	 *****************  Version 2  *****************
	 Author: Andy Foy		Date: 08/07/2016
	 A. Include Grid1k, PrivateLocation and PrivateCode fields.
	
	 *****************  Version 1  *****************
	 Author: Andy Foy		Date: 07/07/2016
	 A. Initial draft based on standard fields.
	
	\*===========================================================================*/
	
	/*---------------------------------------------------------------------------*\
		Clear the existing results table
	\*---------------------------------------------------------------------------*/

	TRUNCATE TABLE LERC_SQL_Update_Results

	/*---------------------------------------------------------------------------*\
		Drop permanent indexes
	\*---------------------------------------------------------------------------*/
	
	IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[LERC_Spp_Table]') AND name = N'SIndex_LERC_Spp_Table_SP_GEOMETRY')
	BEGIN
		INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Dropping spatial index from LERC_Spp_Table'
		DROP INDEX [SIndex_LERC_Spp_Table_SP_GEOMETRY] ON [dbo].[LERC_Spp_Table]
	END
	
	IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[LERC_Spp_Table]') AND name = N'IX_LERC_Spp_Table_Confidential')
	BEGIN
		INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Dropping Confidential index from LERC_Spp_Table'
		DROP INDEX [IX_LERC_Spp_Table_Confidential] ON [dbo].[LERC_Spp_Table]
	END
	
	IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[LERC_Spp_Table]') AND name = N'IX_LERC_Spp_Table_HistoricRec')
	BEGIN
		INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Dropping HistoricRec index from LERC_Spp_Table'
		DROP INDEX [IX_LERC_Spp_Table_HistoricRec] ON [dbo].[LERC_Spp_Table]
	END
	
	IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[LERC_Spp_Table]') AND name = N'IX_LERC_Spp_Table_NegativeRec')
	BEGIN
		INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Dropping NegativeRec index from LERC_Spp_Table'
		DROP INDEX [IX_LERC_Spp_Table_NegativeRec] ON [dbo].[LERC_Spp_Table]
	END
	
	IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[LERC_Spp_Table]') AND name = N'IX_LERC_Spp_Table_TaxonGroup')
	BEGIN
		INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Dropping TaxonGroup index from LERC_Spp_Table'
		DROP INDEX [IX_LERC_Spp_Table_TaxonGroup] ON [dbo].[LERC_Spp_Table]
	END
	
	IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[LERC_Spp_Table]') AND name = N'IX_LERC_Spp_Table_TaxonName')
	BEGIN
		INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Dropping TaxonName index from LERC_Spp_Table'
		DROP INDEX [IX_LERC_Spp_Table_TaxonName] ON [dbo].[LERC_Spp_Table]
	END
	
	/*---------------------------------------------------------------------------*\
		Drop temporary indexes
	\*---------------------------------------------------------------------------*/
	
	IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[LERC_Spp_Table]') AND name = N'IX_LERC_Spp_Table_RecOccKey')
	BEGIN
		INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Dropping temporary TOCC index from LERC_Spp_Table'
		DROP INDEX [IX_LERC_Spp_Table_RecOccKey] ON [dbo].[LERC_Spp_Table] WITH ( ONLINE = OFF )
	END
	
	IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[LERC_Spp_Table]') AND name = N'IX_LERC_Spp_Table_RecTLIKey')
	BEGIN
		INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Dropping temporary TLIK index from LERC_Spp_Table'
		DROP INDEX [IX_LERC_Spp_Table_RecTLIKey] ON [dbo].[LERC_Spp_Table] WITH ( ONLINE = OFF )
	END
	
	IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[LERC_Spp_Table]') AND name = N'IX_LERC_Spp_Table_RecSamKey')
	BEGIN
		INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Dropping temporary Sample_Key index from LERC_Spp_Table'
		DROP INDEX [IX_LERC_Spp_Table_RecSamKey] ON [dbo].[LERC_Spp_Table] WITH ( ONLINE = OFF )
	END
	
	IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[LERC_Spp_Table]') AND name = N'IX_LERC_Spp_Table_Easting')
	BEGIN
		INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Dropping Easting index from LERC_Spp_Table'
		DROP INDEX [IX_LERC_Spp_Table_Easting] ON [dbo].[LERC_Spp_Table] WITH ( ONLINE = OFF )
	END
	
	IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[LERC_Spp_Table]') AND name = N'IX_LERC_Spp_Table_Northing')
	BEGIN
		INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Dropping Northing index from LERC_Spp_Table'
		DROP INDEX [IX_LERC_Spp_Table_Northing] ON [dbo].[LERC_Spp_Table] WITH ( ONLINE = OFF )
	END
	
	IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[LERC_Spp_Table]') AND name = N'IX_LERC_Spp_Table_GRPrecision')
	BEGIN
		INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Dropping GRPrecision index from LERC_Spp_Table'
		DROP INDEX [IX_LERC_Spp_Table_GRPrecision] ON [dbo].[LERC_Spp_Table] WITH ( ONLINE = OFF )
	END
	
	/*---------------------------------------------------------------------------*\
		Clear existing table
	\*---------------------------------------------------------------------------*/
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Truncating table LERC_Spp_Table'
	TRUNCATE TABLE LERC_Spp_Table
	
	/*---------------------------------------------------------------------------*\
		Insert occurrence keys
	\*---------------------------------------------------------------------------*/
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Inserting verified and checked occurrences into LERC_Spp_Table'
	
	DECLARE @VersionDate [date]
	SET @VersionDate = CONVERT(date, GETDATE())
	
	INSERT INTO LERC_Spp_Table (RecOccKey, RecTLIKey, RecSamKey, RecType, Provenance,
		VersionDate, NegativeRec, Confidential, Verification, HistoricRec, Sensitive, SurveyRef,
		Abundance, AbundanceCount)
	SELECT TOCC.TAXON_OCCURRENCE_KEY,
		TDET.TAXON_LIST_ITEM_KEY,
		S.SAMPLE_KEY,
		CASE RT.SHORT_NAME WHEN 'None' THEN '' ELSE RT.SHORT_NAME END,
		CASE TOCC.PROVENANCE WHEN 'None' THEN NULL WHEN '' THEN NULL ELSE TOCC.PROVENANCE END,
		@VersionDate,
		CASE TOCC.ZERO_ABUNDANCE WHEN 1 THEN 'Y' ELSE 'N' END,
		CASE TOCC.CONFIDENTIAL WHEN 1 THEN 'Y' ELSE 'N' END,
		DT.SHORT_NAME,
		'N',
		'N',
		TOCC.SURVEYORS_REF,
		LEFT(dbo.AFFormatAbundanceDataLERC(TOCC.TAXON_OCCURRENCE_KEY),150),
		dbo.AFAbundanceValue(TOCC.TAXON_OCCURRENCE_KEY)
	FROM TAXON_OCCURRENCE TOCC
	INNER JOIN SAMPLE S ON S.SAMPLE_KEY = TOCC.SAMPLE_KEY
	INNER JOIN TAXON_DETERMINATION TDET ON TDET.TAXON_OCCURRENCE_KEY = TOCC.TAXON_OCCURRENCE_KEY
	INNER JOIN DETERMINATION_TYPE DT ON DT.DETERMINATION_TYPE_KEY = TDET.DETERMINATION_TYPE_KEY
	INNER JOIN RECORD_TYPE RT ON RT.RECORD_TYPE_KEY = TOCC.RECORD_TYPE_KEY
	WHERE TDET.PREFERRED = 1
	AND DT.VERIFIED != 1
	AND TOCC.VERIFIED != 1
	AND TOCC.CHECKED = 1
	AND S.SPATIAL_REF_SYSTEM <> 'LTLN'
	AND S.SPATIAL_REF IS NOT NULL
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows inserted into LERC_Spp_Table'

	/*---------------------------------------------------------------------------*\
		Update last updated date
	\*---------------------------------------------------------------------------*/

	IF OBJECT_ID('tempdb..#LastUpdated') IS NOT NULL
	BEGIN
		INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Dropping temporary last updated table'
		DROP TABLE #LastUpdated
	END

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Creating temporary last updated table'

	CREATE TABLE #LastUpdated
	(
		TOCCKey char(16) COLLATE database_default NOT NULL,
		LastEntered date NULL,
		LastChanged date NULL
	)

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Populating temporary last updated table'

	INSERT INTO #LastUpdated (TOCCKey, LastEntered, LastChanged)
	SELECT TOCC.Taxon_Occurrence_Key,
		CONVERT(date, CASE WHEN TOCC.ENTRY_DATE > TDET.ENTRY_DATE THEN TOCC.ENTRY_DATE ELSE TDET.ENTRY_DATE END),
		CONVERT(date, CASE WHEN TOCC.CHANGED_DATE > TDET.CHANGED_DATE THEN TOCC.CHANGED_DATE ELSE TDET.CHANGED_DATE END)
	FROM TAXON_OCCURRENCE TOCC
	INNER JOIN TAXON_DETERMINATION TDET ON TDET.TAXON_OCCURRENCE_KEY = TOCC.TAXON_OCCURRENCE_KEY AND TDET.PREFERRED = 1
	ORDER BY TOCC.Taxon_Occurrence_Key

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows inserted into temporary last updated table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Setting last updated in LERC_Spp_Table'

	UPDATE LERC_Spp_Table
	SET LastUpdated = CASE WHEN LastChanged > LastEntered THEN LastChanged ELSE LastEntered END
	FROM LERC_Spp_Table Spp
	INNER JOIN #LastUpdated Last ON Last.TOCCKey = Spp.RecOccKey

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Deleting temporary last updated table'

	DROP TABLE #LastUpdated

	/*---------------------------------------------------------------------------*\
		Adding temporary indexes
	\*---------------------------------------------------------------------------*/

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Adding temporary TOCC index to LERC_Spp_Table'
	
	CREATE NONCLUSTERED INDEX [IX_LERC_Spp_Table_RecOccKey] ON [dbo].[LERC_Spp_Table] 
	( [RecOccKey] ASC )
	WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Adding temporary TLIK index to LERC_Spp_Table'
	
	CREATE NONCLUSTERED INDEX [IX_LERC_Spp_Table_RecTLIKey] ON [dbo].[LERC_Spp_Table] 
	( [RecTLIKey] ASC )
	WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Adding temporary Sample_Key index to LERC_Spp_Table'
	
	CREATE NONCLUSTERED INDEX [IX_LERC_Spp_Table_RecSamKey] ON [dbo].[LERC_Spp_Table]
	( [RecSamKey] ASC )
	WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	
	/*---------------------------------------------------------------------------*\
		Update survey, sample and location details
	\*---------------------------------------------------------------------------*/
	
	IF OBJECT_ID('tempdb..#SampleDets') IS NOT NULL
	BEGIN
		INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Dropping temporary sample table'
		DROP TABLE #SampleDets
	END
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Creating temporary sample table'
	
	CREATE TABLE #SampleDets
	(
		SampleKey char(16) COLLATE database_default NOT NULL,
		VagueDateStart int NULL,
		VagueDateEnd int NULL,
		VagueDateType varchar(2) COLLATE database_default NULL,
		RecDate varchar(40) COLLATE database_default NULL,
		RecYear int NULL,
		RecMonthStart int NULL,
		RecMonthEnd int NULL,
		Recorder varchar(150) COLLATE database_default NULL,
		RecSurKey char(16) COLLATE database_default NULL,
		SurveyName varchar(100) COLLATE database_default NULL,
		SurveyRunBy varchar(75) COLLATE database_default NULL,
		SurveyTags varchar(250) COLLATE database_default NULL,
		GridRef varchar(12) COLLATE database_default NULL,
		RefSystem varchar(4) COLLATE database_default NULL,
		Grid10k varchar(4) COLLATE database_default NULL,
		Grid1k varchar(6) COLLATE database_default NULL,
		GRPrecision int NULL,
		Easting int NULL,
		Northing int NULL,
		GRQualifier varchar(20) COLLATE database_default NULL,
		RecLocKey char(16) COLLATE database_default NULL,
		Location varchar(100) COLLATE database_default NULL,
		Location2 varchar(100) COLLATE database_default NULL,
		SampleType varchar(20) COLLATE database_default NULL,
		SampleComments varchar(254) COLLATE database_default NULL,
		PrivateLocation varchar(100) COLLATE database_default NULL,
		PrivateCode varchar(20) COLLATE database_default NULL,
		LastUpdated date NULL
	)
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Populating temporary sample table'
	
	INSERT INTO #SampleDets (SampleKey, VagueDateStart, VagueDateEnd, VagueDateType, GridRef, RefSystem, GRQualifier,
		RecSurKey, SampleType, RecLocKey, SampleComments, PrivateLocation, PrivateCode)
	SELECT S.SAMPLE_KEY,
		S.VAGUE_DATE_START,
		S.VAGUE_DATE_END,
		S.VAGUE_DATE_TYPE,
		REPLACE(S.SPATIAL_REF, ' ', ''),
		S.SPATIAL_REF_SYSTEM,
		S.SPATIAL_REF_QUALIFIER,
		SV.SURVEY_KEY,
		ST.SHORT_NAME,
		S.LOCATION_KEY,
		Left(dbo.ufn_RtfToPlaintext(S.COMMENT), 254),
		CASE WHEN S.PRIVATE_LOCATION = '' THEN NULL ELSE S.PRIVATE_LOCATION END,
		CASE WHEN S.PRIVATE_CODE = '' THEN NULL ELSE S.PRIVATE_CODE END
	FROM SAMPLE S
	INNER JOIN SAMPLE_TYPE ST ON ST.SAMPLE_TYPE_KEY = S.SAMPLE_TYPE_KEY
	INNER JOIN SURVEY_EVENT SE ON SE.SURVEY_EVENT_KEY = S.SURVEY_EVENT_KEY
	INNER JOIN SURVEY SV ON SV.SURVEY_KEY = SE.SURVEY_KEY
	WHERE S.SPATIAL_REF_SYSTEM <> 'LTLN'
	AND S.SPATIAL_REF IS NOT NULL
	ORDER BY S.SAMPLE_KEY
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows inserted into temporary sample table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Setting Recorders and Last Updated in temporary sample table'

	UPDATE #SampleDets
	SET Recorder = LEFT(dbo.FormatEventRecorders(SampleKey), 150),
	    LastUpdated = dbo.AFSampleLastUpdated(SampleKey, 2)
	FROM #SampleDets Dets

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary sample table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Setting locations in temporary sample table'
	
	UPDATE #SampleDets
	SET	Location = LN.ITEM_NAME,
		Location2 = S.LOCATION_NAME
		--Location2 = CASE WHEN SE.LOCATION_NAME IS NULL THEN S.LOCATION_NAME ELSE SE.LOCATION_NAME END
	FROM #SampleDets Dets
	INNER JOIN SAMPLE S ON S.SAMPLE_KEY = Dets.SampleKey
	INNER JOIN SURVEY_EVENT SE ON SE.SURVEY_EVENT_KEY = S.SURVEY_EVENT_KEY
	LEFT JOIN LOCATION_NAME LN ON LN.LOCATION_KEY = SE.LOCATION_KEY AND LN.PREFERRED = 1
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary sample table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating Locations to remove invalid characters in temporary sample table'

	UPDATE #SampleDets
	SET Location = dbo.AFRemoveInvalidChars(Location)
	FROM #SampleDets Dets
	WHERE Location IS NOT NULL

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary sample table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating Locations2 to remove invalid characters in temporary sample table'

	UPDATE #SampleDets
	SET Location2 = dbo.AFRemoveInvalidChars(Location2)
	FROM #SampleDets Dets
	WHERE Location2 IS NOT NULL

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary sample table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating Locations to title case in temporary sample table'
	
	UPDATE #SampleDets
	SET Location = dbo.AFReturnTitleCase(Location)
	FROM #SampleDets Dets
	WHERE Location = UPPER(Location) COLLATE Latin1_General_CS_AS
	OR    Location = LOWER(Location) COLLATE Latin1_General_CS_AS
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary sample table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating Locations2 to title case in temporary sample table'
	
	UPDATE #SampleDets
	SET Location2 = dbo.AFReturnTitleCase(Location2)
	FROM #SampleDets Dets
	WHERE Location2 = UPPER(Location2) COLLATE Latin1_General_CS_AS
	OR    Location2 = LOWER(Location2) COLLATE Latin1_General_CS_AS
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary sample table'

	--INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Replacing locations in temporary sample table'
	
	--UPDATE #SampleDets
	--SET	Location = Location2,
	--	Location2 = NULL
	--FROM #SampleDets Dets
	--WHERE Location IS NULL
	--AND Location2 IS NOT NULL AND Location2 <> ''
	
	--INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary sample table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating truncated sample comments in temporary sample table'

	UPDATE #SampleDets
	SET SampleComments = Left(SampleComments, 250) + ' ...'
	FROM #SampleDets Dets
	INNER JOIN SAMPLE S ON S.SAMPLE_KEY = Dets.SampleKey
	WHERE SampleComments IS NOT NULL
	AND LEN(dbo.ufn_RtfToPlaintext(S.COMMENT)) > 254

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary sample table'

	IF OBJECT_ID('tempdb..#SurveyDets') IS NOT NULL
	BEGIN
		INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Dropping temporary survey table'
		DROP TABLE #SurveyDets
	END

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Creating temporary survey table'

	CREATE TABLE #SurveyDets
	(
		SurveyKey char(16) COLLATE database_default NOT NULL,
		SurveyName varchar(100) COLLATE database_default NULL,
		SurveyRunBy varchar(75) COLLATE database_default NULL,
		SurveyTags varchar(250) COLLATE database_default NULL
	)

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Populating temporary survey table'

	INSERT INTO #SurveyDets (SurveyKey, SurveyName, SurveyRunBy, SurveyTags)
	SELECT SV.SURVEY_KEY,
		SV.ITEM_NAME,
		dbo.ufn_GetFormattedName(SV.RUN_BY),
		dbo.ufn_GetSurveyTagString(SV.SURVEY_KEY)
	FROM SURVEY SV
	ORDER BY SV.SURVEY_KEY

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows inserted into temporary survey table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Setting survey details in temporary sample table'

	UPDATE #SampleDets
	SET	SurveyName = SurDets.SurveyName,
		SurveyRunBy = SurDets.SurveyRunBy,
		SurveyTags = SurDets.SurveyTags
	FROM #SampleDets SamDets
	INNER JOIN #SurveyDets SurDets ON SurDets.SurveyKey = SamDets.RecSurKey

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary sample table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Deleting temporary survey table'

	DROP TABLE #SurveyDets

	IF OBJECT_ID('tempdb..#SampleDates') IS NOT NULL
	BEGIN
		INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Dropping temporary sample dates table'
		DROP TABLE #SampleDates
	END

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Creating temporary sample dates table'

	CREATE TABLE #SampleDates
	(
		VagueDateStart int NULL,
		VagueDateEnd int NULL,
		VagueDateType varchar(2) COLLATE database_default NULL,
		RecDate varchar(40) COLLATE database_default NULL,
		RecYear int NULL,
		RecMonthStart int NULL,
		RecMonthEnd int NULL
	)

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Populating temporary sample dates table'

	INSERT INTO #SampleDates (VagueDateStart, VagueDateEnd, VagueDateType)
	SELECT DISTINCT S.VAGUE_DATE_START,
		S.VAGUE_DATE_END,
		S.VAGUE_DATE_TYPE
	FROM SAMPLE S

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows inserted into temporary sample dates table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating temporary sample dates table'

	UPDATE #SampleDates
	SET RecDate = dbo.LCReturnVagueDateShort(VagueDateStart, VagueDateEnd, VagueDateType),
		RecYear = dbo.FormatDatePart(VagueDateEnd, VagueDateEnd, VagueDateType, 0),
		RecMonthStart = CASE WHEN VagueDateStart IS NULL THEN 0 ELSE dbo.FormatDatePart(VagueDateStart, VagueDateStart, VagueDateType, 1) END,
		RecMonthEnd = CASE WHEN VagueDateEnd IS NULL THEN 0 ELSE dbo.FormatDatePart(VagueDateEnd, VagueDateEnd, VagueDateType, 1) END
	FROM #SampleDates

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary sample dates table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Setting sample dates in temporary sample table'

	UPDATE #SampleDets
	SET	VagueDateStart = SamDates.VagueDateStart,
		VagueDateEnd = SamDates.VagueDateEnd,
		VagueDateType = SamDates.VagueDateType,
		RecDate = SamDates.RecDate,
		RecYear = SamDates.RecYear,
		RecMonthStart = SamDates.RecMonthStart,
		RecMonthEnd = SamDates.RecMonthEnd
	FROM #SampleDets SamDets
	INNER JOIN #SampleDates SamDates ON SamDates.VagueDateStart = SamDets.VagueDateStart
		AND SamDates.VagueDateEnd = SamDets.VagueDateEnd
		AND SamDates.VagueDateType = SamDets.VagueDateType

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary sample table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Deleting temporary sample dates table'

	DROP TABLE #SampleDates

	IF OBJECT_ID('tempdb..#SampleGR') IS NOT NULL
	BEGIN
		INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Dropping temporary sample gridrefs table'
		DROP TABLE #SampleGR
	END

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Creating temporary sample gridrefs table'

	CREATE TABLE #SampleGR
	(
		GridRef varchar(12) COLLATE database_default NULL,
		RefSystem varchar(4) COLLATE database_default NULL,
		Grid10k varchar(4) COLLATE database_default NULL,
		Grid1k varchar(6) COLLATE database_default NULL,
		GRPrecision int NULL,
		Easting int NULL,
		Northing int NULL
	)

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Populating temporary sample gridrefs table'

	INSERT INTO #SampleGR (GridRef, RefSystem)
	SELECT DISTINCT REPLACE(S.SPATIAL_REF, ' ', ''),
		SPATIAL_REF_SYSTEM
	FROM SAMPLE S
	WHERE S.SPATIAL_REF_SYSTEM <> 'LTLN'
	AND S.SPATIAL_REF IS NOT NULL

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows inserted into temporary sample gridrefs table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating temporary sample gridrefs table'

	UPDATE #SampleGR
	SET Grid10k = dbo.FormatGridRef(GridRef, RefSystem, 0),
		Grid1k = dbo.FormatGridRef(GridRef, RefSystem, 1),
		GRPrecision = dbo.AFGridRefPrecision(GridRef, RefSystem, 0),
		Easting = dbo.LCRETURNEASTINGSV2(GridRef, RefSystem, 1),
		Northing = dbo.LCRETURNNORTHINGSV2(GridRef, RefSystem, 1)
	FROM #SampleGR

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary sample gridrefs table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Setting sample gridrefs in temporary sample table'

	UPDATE #SampleDets
	SET	Grid10k = SamGR.Grid10k,
		Grid1k = SamGR.Grid1k,
		GRPrecision = SamGR.GRPrecision,
		Easting = SamGR.Easting,
		Northing = SamGR.Northing
	FROM #SampleDets SamDets
	INNER JOIN #SampleGR SamGR ON SamGR.GridRef = SamDets.GridRef
		AND SamGR.RefSystem = SamDets.RefSystem

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary sample table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Deleting temporary sample gridrefs table'

	DROP TABLE #SampleGR

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Setting sample details in LERC_Spp_Table'
	
	UPDATE LERC_Spp_Table
	SET VagueDateStart = Dets.VagueDateStart,
		VagueDateEnd = Dets.VagueDateEnd,
		VagueDateType = Dets.VagueDateType,
		RecDate = Dets.RecDate,
		RecYear = Dets.RecYear,
		RecMonthStart = Dets.RecMonthStart,
		RecMonthEnd = Dets.RecMonthEnd,
		Recorder = 'Available from LERC',
		RecSurKey = Dets.RecSurKey,
		SurveyName = Dets.SurveyName,
		SurveyRunBy = Dets.SurveyRunBy,
		SurveyTags = Dets.SurveyTags,
		GridRef = Dets.GridRef,
		RefSystem = Dets.RefSystem,
		Grid10k = Dets.Grid10k,
		Grid1k = Dets.Grid1k,
		GRPrecision = Dets.GRPrecision,
		GRQualifier = Dets.GRQualifier,
		Easting = Dets.Easting,
		Northing = Dets.Northing,
		RecLocKey = Dets.RecLocKey,
		Location = Dets.Location,
		Location2 = Dets.Location2,
		SampleType = Dets.SampleType,
		SampleComments = Dets.SampleComments,
		PrivateLocation = Dets.PrivateLocation,
		PrivateCode = Dets.PrivateCode,
		PrivateRecorder = Dets.Recorder,
		LastUpdated = CASE WHEN Dets.LastUpdated > Spp.LastUpdated THEN Dets.LastUpdated ELSE Spp.LastUpdated END
	FROM LERC_Spp_Table Spp
	INNER JOIN #SampleDets Dets ON Dets.SampleKey = Spp.RecSamKey
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Deleting temporary sample table'
	
	DROP TABLE #SampleDets
	
	/*---------------------------------------------------------------------------*\
		Delete records for excluded surveys
	\*---------------------------------------------------------------------------*/

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Deleting excluded survey records from LERC_Spp_Table'

	DELETE Spp
	FROM LERC_Spp_Table Spp
	INNER JOIN LERC_Surveys LSV ON LSV.SurveyName LIKE Spp.SurveyName
	WHERE LSV.Exclude = 'Y'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows deleted from LERC_Spp_Table'

	/*---------------------------------------------------------------------------*\
		Update taxon occurrence comment details
	\*---------------------------------------------------------------------------*/
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Setting taxon occurrence comments in LERC_Spp_Table'
	
	UPDATE LERC_Spp_Table
	SET	Comments = Left(dbo.ufn_RtfToPlaintext(TOCC.COMMENT), 254)
	FROM LERC_Spp_Table Spp
	INNER JOIN TAXON_OCCURRENCE TOCC ON TOCC.TAXON_OCCURRENCE_KEY = Spp.RecOccKey
	WHERE TOCC.COMMENT IS NOT NULL
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating taxon occurrence comments with full-stops in LERC_Spp_Table'

	UPDATE LERC_Spp_Table
	SET Comments = NULL
	FROM LERC_Spp_Table Spp
	WHERE COMMENTS = '.' OR COMMENTS = ''

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating taxon occurrence comments with CRLFs in LERC_Spp_Table'

	UPDATE LERC_Spp_Table
	SET	Comments = Left(Spp.Comments, Len(RTrim(Replace(Spp.Comments, Char(13) + CHAR(10), '  '))))
	FROM LERC_Spp_Table Spp
	WHERE Spp.Comments IS NOT NULL
	AND Right(Spp.Comments, 2) = Char(13) + CHAR(10)

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating taxon occurrence comments with CRs/LFs/Tabs in LERC_Spp_Table'

	UPDATE LERC_Spp_Table
	SET	Comments = Left(Replace(Replace(Replace(Spp.Comments, Char(9), ' '), Char(13), ' '), Char(10), ' '), 254)
	FROM LERC_Spp_Table Spp
	WHERE Spp.Comments IS NOT NULL
	AND (Spp.Comments LIKE '%' + CHAR(9) + '%'
	OR   Spp.Comments LIKE '%' + CHAR(10) + '%'
	OR   Spp.Comments LIKE '%' + CHAR(13) + '%')

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating inches in taxon occurrence comments in LERC_Spp_Table'

	UPDATE LERC_Spp_Table
	SET	Comments = Left(Replace(Spp.Comments, '"', 'inches'), 254)
	FROM LERC_Spp_Table Spp
	WHERE Comments LIKE '%"%' AND Comments NOT LIKE '%"%"%' AND Comments NOT LIKE '"%'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating double quotes in taxon occurrence comments in LERC_Spp_Table'

	UPDATE LERC_Spp_Table
	SET	Comments = Replace(Spp.Comments, '"', Char(39))
	FROM LERC_Spp_Table Spp
	WHERE Comments LIKE '%"%'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating truncated taxon occurrence comments in LERC_Spp_Table'

	UPDATE LERC_Spp_Table
	SET Comments = Left(Comments, 250) + ' ...'
	FROM LERC_Spp_Table Spp
	INNER JOIN TAXON_OCCURRENCE TOCC ON TOCC.TAXON_OCCURRENCE_KEY = Spp.RecOccKey
	WHERE Comments IS NOT NULL
	AND LEN(dbo.ufn_RtfToPlaintext(TOCC.COMMENT)) > 254

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'

	/*---------------------------------------------------------------------------*\
		Update determiner comment details
	\*---------------------------------------------------------------------------*/
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Setting determiner comments in LERC_Spp_Table'
	
	UPDATE LERC_Spp_Table
	SET	DeterminerComments = Left(dbo.ufn_RtfToPlaintext(TDET.COMMENT), 254)
	FROM LERC_Spp_Table Spp
	INNER JOIN TAXON_DETERMINATION TDET ON TDET.TAXON_OCCURRENCE_KEY = Spp.RecOccKey AND TDET.PREFERRED = 1
	AND TDET.COMMENT IS NOT NULL
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating determiner comments with CRLFs in LERC_Spp_Table'

	UPDATE LERC_Spp_Table
	SET	DeterminerComments = Left(Spp.DeterminerComments, Len(RTrim(Replace(Spp.DeterminerComments, Char(13) + CHAR(10), '  '))))
	FROM LERC_Spp_Table Spp
	WHERE Spp.DeterminerComments IS NOT NULL
	AND Right(Spp.DeterminerComments, 2) = Char(13) + CHAR(10)

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating determiner comments with CRs/LFs/Tabs in LERC_Spp_Table'

	UPDATE LERC_Spp_Table
	SET	DeterminerComments = Left(Replace(Replace(Replace(Spp.DeterminerComments, Char(9), ' '), Char(13), ' '), Char(10), ' '), 254)
	FROM LERC_Spp_Table Spp
	WHERE Spp.DeterminerComments IS NOT NULL
	AND (Spp.DeterminerComments LIKE '%' + CHAR(9) + '%'
	OR   Spp.DeterminerComments LIKE '%' + CHAR(10) + '%'
	OR   Spp.DeterminerComments LIKE '%' + CHAR(13) + '%')

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating double quotes in determiner comments in LERC_Spp_Table'

	UPDATE LERC_Spp_Table
	SET	DeterminerComments = Replace(Spp.DeterminerComments, '"', Char(39))
	FROM LERC_Spp_Table Spp
	WHERE DeterminerComments LIKE '%"%'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating truncated taxon determiner comments in LERC_Spp_Table'

	UPDATE LERC_Spp_Table
	SET DeterminerComments = Left(DeterminerComments, 250) + ' ...'
	FROM LERC_Spp_Table Spp
	INNER JOIN TAXON_DETERMINATION TDET ON TDET.TAXON_OCCURRENCE_KEY = Spp.RecOccKey AND TDET.PREFERRED = 1
	WHERE Comments IS NOT NULL
	AND LEN(dbo.ufn_RtfToPlaintext(TDET.COMMENT)) > 254

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'

	/*---------------------------------------------------------------------------*\
		Update observation source
	\*---------------------------------------------------------------------------*/
	
	IF OBJECT_ID('tempdb..#Source') IS NOT NULL
	BEGIN
		INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Dropping temporary source table'
		DROP TABLE #Source
	END
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Creating temporary source table'
	
	CREATE TABLE #Source
	(
		SourceKey char(16) COLLATE database_default NOT NULL,
		ReferenceName varchar(300) COLLATE database_default NULL
	)
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Populating temporary source table'
	
	INSERT INTO #Source (SourceKey)
	SELECT DISTINCT SOURCE_KEY
	FROM TAXON_OCCURRENCE_SOURCES
	ORDER BY SOURCE_KEY
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows inserted into temporary source table'
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating temporary source table'
	
	UPDATE #Source
	SET ReferenceName = dbo.ufn_GetFormattedReferenceName(SourceKey)
	FROM #Source Src
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary source table'
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Setting obervation source in LERC_Spp_Table'
	
	UPDATE LERC_Spp_Table
	SET	ObsSource = LEFT(Src.ReferenceName, 254)
	FROM LERC_Spp_Table Spp
	INNER JOIN TAXON_OCCURRENCE_SOURCES TOS ON TOS.TAXON_OCCURRENCE_KEY = Spp.RecOccKey
	INNER JOIN #Source Src ON Src.SourceKey = TOS.SOURCE_KEY
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary source table'
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Deleting temporary source table'
	
	DROP TABLE #Source
	
	/*---------------------------------------------------------------------------*\
		Update taxon determiner details
	\*---------------------------------------------------------------------------*/
	
	IF OBJECT_ID('tempdb..#DeterminerDets') IS NOT NULL
	BEGIN
		INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Dropping temporary determiner table'
		DROP TABLE #DeterminerDets
	END
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Creating temporary determiner table'
	
	CREATE TABLE #DeterminerDets
	(
		DeterminerKey char(16) COLLATE database_default NOT NULL,
		Determiner varchar(60) COLLATE database_default NULL
	)
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Populating temporary determiner table'
	
	INSERT INTO #DeterminerDets (DeterminerKey)
	SELECT DISTINCT DETERMINER
	FROM TAXON_DETERMINATION
	ORDER BY DETERMINER
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows inserted into temporary determiner table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Adding TLIK index to temporary determiner table'

	CREATE NONCLUSTERED INDEX [IX_DeterminerDets_DeterminerKey] ON #DeterminerDets 
	( [DeterminerKey] ASC )
	WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating temporary determiner table'
	
	UPDATE #DeterminerDets
	SET Determiner = LEFT(dbo.ufn_GetFormattedName(DeterminerKey), 60)
	FROM #DeterminerDets Dets
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary determiner table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Setting taxon determiner in LERC_Spp_Table'
	
	UPDATE LERC_Spp_Table
	SET Determiner = 'Available from LERC',
		PrivateDeterminer = Dets.Determiner
--		PrivateDeterminer = CASE WHEN Dets.Determiner = Spp.Recorder THEN NULL
--						  WHEN EXISTS(SELECT 1 FROM SURVEY_EVENT_RECORDER SER WHERE SER.SURVEY_EVENT_KEY = SE.SURVEY_EVENT_KEY AND SER.NAME_KEY = Dets.DeterminerKey) THEN NULL
--						  ELSE Dets.Determiner END
	FROM LERC_Spp_Table Spp
	INNER JOIN TAXON_DETERMINATION TDET ON TDET.TAXON_OCCURRENCE_KEY = Spp.RecOccKey
--	INNER JOIN SAMPLE S ON S.SAMPLE_KEY = Spp.RecSamKey
--	INNER JOIN SURVEY_EVENT SE ON SE.SURVEY_EVENT_KEY = S.SURVEY_EVENT_KEY
	INNER JOIN #DeterminerDets Dets ON Dets.DeterminerKey = TDET.DETERMINER
	WHERE TDET.PREFERRED = 1
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Deleting temporary determiner table'
	
	DROP TABLE #DeterminerDets
	
	/*---------------------------------------------------------------------------*\
		Update taxon details
	\*---------------------------------------------------------------------------*/
	
	IF OBJECT_ID('tempdb..#TaxonDets') IS NOT NULL
	BEGIN
		INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Dropping temporary taxon details table'
		DROP TABLE #TaxonDets
	END
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Creating temporary taxon details table'
	
	CREATE TABLE #TaxonDets
	(
		TLIKey char(16) COLLATE database_default NOT NULL,
		TaxonName varchar(75) COLLATE database_default NULL,
		CommonName varchar(75) COLLATE database_default NULL,
		TaxonRank varchar(20) COLLATE database_default NULL,
		TaxonGroup varchar(60) COLLATE database_default NULL,
		TaxonClass varchar(75) COLLATE database_default NULL,
		TaxonOrder varchar(75) COLLATE database_default NULL,
		TaxonFamily varchar(75) COLLATE database_default NULL,
		SortOrder varchar(36) COLLATE database_default NULL,
		GroupOrder int NULL,
		RecTVKey char(16) COLLATE database_default NULL,
		StatusEuro varchar(50) COLLATE database_default NULL,
		StatusUK varchar(100) COLLATE database_default NULL,
		StatusOther varchar(150) COLLATE database_default NULL,
		StatusINNS varchar(50) COLLATE database_default NULL
	)
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Populating temporary taxon details table'
	
	INSERT INTO #TaxonDets (TLIKey)
	SELECT DISTINCT Spp.RecTLIKey
	FROM LERC_Spp_Table Spp
	ORDER BY Spp.RecTLIKey
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows inserted into temporary taxon details table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Adding TLIK index to temporary taxon details table'

	CREATE NONCLUSTERED INDEX [IX_TaxonDets_TLIKey] ON #TaxonDets 
	( [TLIKey] ASC )
	WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Setting taxon group and sort order in temporary taxon details table'
	
	UPDATE #TaxonDets
	SET TaxonGroup = CASE WHEN LTG.TaxonGroup IS NULL THEN TG.TAXON_GROUP_NAME ELSE LTG.TaxonGroup END,
		GroupOrder = TG.SORT_ORDER,
		RecTVKey = TLI.TAXON_VERSION_KEY
	FROM #TaxonDets Dets
	INNER JOIN INDEX_TAXON_NAME ITN ON ITN.TAXON_LIST_ITEM_KEY = Dets.TLIKey
	INNER JOIN TAXON_LIST_ITEM TLI ON TLI.TAXON_LIST_ITEM_KEY = ITN.RECOMMENDED_TAXON_LIST_ITEM_KEY
	INNER JOIN TAXON_VERSION TV ON TV.TAXON_VERSION_KEY = TLI.TAXON_VERSION_KEY
	LEFT JOIN TAXON_GROUP TG ON TG.TAXON_GROUP_KEY = TV.OUTPUT_GROUP_KEY
	LEFT JOIN LERC_TAXON_GROUPS LTG ON LTG.Taxon_Group_Name = TG.TAXON_GROUP_NAME

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary taxon details table'
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating taxon group and sort order for bats in temporary taxon details table'
	
	UPDATE #TaxonDets
	SET TaxonGroup = 'Mammals - Terrestrial (bats)',
		GroupOrder = 111
	FROM #TaxonDets Dets
	INNER JOIN INDEX_TAXON_NAME ITN ON ITN.TAXON_LIST_ITEM_KEY = Dets.TLIKey
	INNER JOIN INDEX_TAXON_NAME ITN2 ON ITN2.RECOMMENDED_TAXON_LIST_ITEM_KEY = ITN.RECOMMENDED_TAXON_LIST_ITEM_KEY
	INNER JOIN INDEX_TAXON_GROUP ITG ON ITG.CONTAINED_LIST_ITEM_KEY = ITN2.TAXON_LIST_ITEM_KEY
	INNER JOIN INDEX_TAXON_NAME ITN3 ON ITN3.TAXON_LIST_ITEM_KEY = ITG.TAXON_LIST_ITEM_KEY
	WHERE ITN3.ACTUAL_NAME = 'Chiroptera'
	AND TaxonGroup = 'Mammals - Terrestrial (excl. bats)'
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary taxon details table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating undetermined taxon groups in temporary taxon details table'
	
	UPDATE #TaxonDets
	SET TaxonGroup = 'Undetermined',
		GroupOrder = 0
	FROM #TaxonDets Dets
	WHERE TaxonGroup IS NULL
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary taxon details table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Setting taxon rank in temporary taxon details table'
	
	UPDATE #TaxonDets
	SET TaxonRank = TR.LONG_NAME
	FROM #TaxonDets Dets
	INNER JOIN INDEX_TAXON_NAME ITN ON ITN.TAXON_LIST_ITEM_KEY = Dets.TLIKey
	INNER JOIN TAXON_LIST_ITEM TLI ON TLI.TAXON_LIST_ITEM_KEY = ITN.RECOMMENDED_TAXON_LIST_ITEM_KEY
	INNER JOIN TAXON_RANK TR ON TR.TAXON_RANK_KEY = TLI.TAXON_RANK_KEY
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary taxon details table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Setting taxon class in temporary taxon details table'

	UPDATE #TaxonDets
	SET TaxonClass = T.ITEM_NAME
	FROM #TaxonDets Dets
	INNER JOIN Index_Taxon_Name ITN ON ITN.TAXON_LIST_ITEM_KEY = Dets.TLIKey
	INNER JOIN TAXON_LIST_ITEM TLI ON TLI.TAXON_LIST_ITEM_KEY = ITN.Recommended_Taxon_List_Item_Key AND ITN.System_Supplied_Data = 1
	LEFT JOIN Index_Taxon_Hierarchy ITH ON ITH.Recommended_Taxon_Version_Key = TLI.TAXON_VERSION_KEY AND ITH.Hierarchy_Type = 'C'
	LEFT JOIN TAXON_VERSION TV ON TV.Taxon_Version_key = ITH.Hierarchy_Taxon_Version_key  
	LEFT JOIN TAXON T ON T.Taxon_Key = TV.Taxon_key

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary taxon details table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Setting taxon order in temporary taxon details table'

	UPDATE #TaxonDets
	SET TaxonOrder = T.ITEM_NAME
	FROM #TaxonDets Dets
	INNER JOIN Index_Taxon_Name ITN ON ITN.TAXON_LIST_ITEM_KEY = Dets.TLIKey
	INNER JOIN TAXON_LIST_ITEM TLI ON TLI.TAXON_LIST_ITEM_KEY = ITN.Recommended_Taxon_List_Item_Key AND ITN.System_Supplied_Data = 1
	LEFT JOIN Index_Taxon_Hierarchy ITH ON ITH.Recommended_Taxon_Version_Key = TLI.TAXON_VERSION_KEY AND ITH.Hierarchy_Type = 'O'
	LEFT JOIN TAXON_VERSION TV ON TV.Taxon_Version_key = ITH.Hierarchy_Taxon_Version_key  
	LEFT JOIN TAXON T ON T.Taxon_Key = TV.Taxon_key

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary taxon details table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Setting taxon family in temporary taxon details table'

	UPDATE #TaxonDets
	SET TaxonFamily = T.ITEM_NAME
	FROM #TaxonDets Dets
	INNER JOIN Index_Taxon_Name ITN ON ITN.TAXON_LIST_ITEM_KEY = Dets.TLIKey
	INNER JOIN TAXON_LIST_ITEM TLI ON TLI.TAXON_LIST_ITEM_KEY = ITN.Recommended_Taxon_List_Item_Key AND ITN.System_Supplied_Data = 1
	LEFT JOIN Index_Taxon_Hierarchy ITH ON ITH.Recommended_Taxon_Version_Key = TLI.TAXON_VERSION_KEY AND ITH.Hierarchy_Type = 'F'
	LEFT JOIN TAXON_VERSION TV ON TV.Taxon_Version_key = ITH.Hierarchy_Taxon_Version_key  
	LEFT JOIN TAXON T ON T.Taxon_Key = TV.Taxon_key

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary taxon details table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Setting taxon names and sort order in temporary taxon details table'
	
	UPDATE #TaxonDets
	SET TaxonName = ITN2.ACTUAL_NAME,
		CommonName = ITN2.COMMON_NAME,
		SortOrder = ITN2.SORT_ORDER
	FROM #TaxonDets Dets
	INNER JOIN INDEX_TAXON_NAME ITN ON ITN.TAXON_LIST_ITEM_KEY = Dets.TLIKey
	INNER JOIN INDEX_TAXON_NAME ITN2 ON ITN2.TAXON_LIST_ITEM_KEY = ITN.RECOMMENDED_TAXON_LIST_ITEM_KEY
	WHERE ITN.SYSTEM_SUPPLIED_DATA = 1
	AND ITN2.SYSTEM_SUPPLIED_DATA = 1
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary taxon details table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating common names from species in temporary taxon details table'
	
	UPDATE #TaxonDets
	SET CommonName = LTN.DefaultCommonName
	FROM #TaxonDets Dets
	INNER JOIN LERC_TAXON_NAMES LTN ON LTN.TaxonGroup = Dets.TaxonGroup AND LTN.TaxonName = Dets.TaxonName
	WHERE LTN.DefaultCommonName IS NOT NULL AND LTN.DefaultCommonName <> ''

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary taxon details table'
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating common names from groups in temporary taxon details table'
	
	UPDATE #TaxonDets
	SET CommonName = LTG.DefaultCommonName
	FROM #TaxonDets Dets
	INNER JOIN LERC_TAXON_GROUPS LTG ON LTG.TaxonGroup = Dets.TaxonGroup
	WHERE Dets.TaxonName = Dets.CommonName
	AND LTG.DefaultCommonName IS NOT NULL AND LTG.DefaultCommonName <> ''
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary taxon details table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating taxon statuses in temporary taxon details table'
	
	UPDATE #TaxonDets
	SET StatusEuro = dbo.AFGetDesignationsLERC(TLIKey,'SR00060400000001'),
		StatusUK = dbo.AFGetDesignationsLERC(TLIKey,'SR00060400000002'),
		StatusOther = dbo.AFGetDesignationsLERC(TLIKey,'SR00060400000003'),
		StatusINNS = dbo.AFGetDesignationsLERC(TLIKey,'SR00060400000004')
	FROM #TaxonDets Dets
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary taxon details table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating statuses for mis-designated species in temporary taxon details table'
	
	UPDATE #TaxonDets
	SET StatusEuro = LTN.DefaultStatusEuro,
		StatusUk = LTN.DefaultStatusUK,
		StatusOther = LTN.DefaultStatusOther,
		StatusINNS = LTN.DefaultStatusINNS
	FROM #TaxonDets Dets
	INNER JOIN LERC_TAXON_NAMES LTN ON LTN.TaxonGroup = Dets.TaxonGroup AND LTN.TaxonName = Dets.TaxonName
	WHERE LTN.NonNotableSpp <> 'Y' AND LTN.OverrideStatus = 'Y'
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary taxon details table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Clearing statuses for dodgy species in temporary taxon details table'
	
	UPDATE #TaxonDets
	SET StatusEuro = NULL,
		StatusUk = NULL,
		StatusOther = NULL
	FROM #TaxonDets Dets
	INNER JOIN LERC_TAXON_NAMES LTN ON LTN.TaxonGroup = Dets.TaxonGroup AND LTN.TaxonName = Dets.TaxonName
	WHERE LTN.NonNotableSpp = 'Y'
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in temporary taxon details table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Setting taxon details in LERC_Spp_Table'
	
	UPDATE LERC_Spp_Table
	SET	TaxonName = Dets.TaxonName,
		CommonName = Dets.CommonName,
		TaxonRank = Dets.TaxonRank,
		TaxonGroup = Dets.TaxonGroup,
		TaxonClass = Dets.TaxonClass,
		TaxonOrder = Dets.TaxonOrder,
		TaxonFamily = Dets.TaxonFamily,
		SortOrder = Dets.SortOrder,
		GroupOrder = Dets.GroupOrder,
		RecTVKey = Dets.RecTVKey,
		StatusEuro = Dets.StatusEuro,
		StatusUK = Dets.StatusUK,
		StatusOther = Dets.StatusOther,
		StatusINNS = Dets.StatusINNS
	FROM LERC_Spp_Table Spp
	INNER JOIN #TaxonDets Dets ON Dets.TLIKey = Spp.RecTLIKey
	--WHERE COALESCE(Dets.StatusEuro, Dets.StatusUK, Dets.StatusOther, Dets.StatusINNS) IS NOT NULL
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Deleting temporary taxon details table'
	
	DROP TABLE #TaxonDets
	
	/*---------------------------------------------------------------------------*\
		Update confidential record flag for surveys, taxon groups and names
	\*---------------------------------------------------------------------------*/
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating confidential flag from surveys in LERC_Spp_Table'
	
	UPDATE LERC_Spp_Table
	SET Confidential = 'Y'
	FROM LERC_Spp_Table Spp
	INNER JOIN LERC_Surveys LSV ON LSV.SurveyName LIKE Spp.SurveyName
	WHERE LSV.Confidential = 'Y'
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating confidential flag from taxon groups in LERC_Spp_Table'
	
	UPDATE LERC_Spp_Table
	SET Confidential = 'Y'
	FROM LERC_Spp_Table Spp
	INNER JOIN LERC_TAXON_GROUPS LTG ON LTG.TaxonGroup = Spp.TaxonGroup
	WHERE LTG.Confidential = 'Y'
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating confidential flag from taxon names in LERC_Spp_Table'
	
	UPDATE LERC_Spp_Table
	SET Confidential = 'Y'
	FROM LERC_Spp_Table Spp
	INNER JOIN LERC_TAXON_NAMES LTN ON LTN.TaxonGroup = Spp.TaxonGroup AND LTN.TaxonName = Spp.TaxonName
	WHERE LTN.Confidential = 'Y'
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'

	/*---------------------------------------------------------------------------*\
		Update location and grid reference for surveys
	\*---------------------------------------------------------------------------*/
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating location details from surveys in LERC_Spp_Table'
	
	UPDATE LERC_Spp_Table
	SET Location = LSV.DefaultLocation,
		Location2 = NULL,
		Sensitive = 'Y'
	FROM LERC_Spp_Table Spp
	INNER JOIN LERC_Surveys LSV ON Spp.SurveyName LIKE LSV.SurveyName
	WHERE LSV.DefaultLocation IS NOT NULL AND LSV.DefaultLocation <> ''
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating grid ref from surveys in LERC_Spp_Table'
	
	UPDATE LERC_Spp_Table
	SET GridRef = dbo.AFSensitiveGR(GridRef, LSV.DefaultGR),
		Sensitive = 'Y'
	FROM LERC_Spp_Table Spp
	INNER JOIN LERC_Surveys LSV ON Spp.SurveyName LIKE LSV.SurveyName
	WHERE LSV.DefaultGR IS NOT NULL AND LSV.DefaultGR <> ''
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'

	/*---------------------------------------------------------------------------*\
		Update location and grid reference for taxon groups
	\*---------------------------------------------------------------------------*/

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating location details from taxon groups in LERC_Spp_Table'
	
	UPDATE LERC_Spp_Table
	SET Location = LTG.DefaultLocation,
		Location2 = NULL,
		Sensitive = 'Y'
	FROM LERC_Spp_Table Spp
	INNER JOIN LERC_Taxon_Groups LTG ON LTG.TaxonGroup = Spp.TaxonGroup
	WHERE LTG.DefaultLocation IS NOT NULL AND LTG.DefaultLocation <> ''
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating grid ref from taxon groups in LERC_Spp_Table'
	
	UPDATE LERC_Spp_Table
	SET GridRef = dbo.AFSensitiveGR(GridRef, LTG.DefaultGR),
		Sensitive = 'Y'
	FROM LERC_Spp_Table Spp
	INNER JOIN LERC_Taxon_Groups LTG ON LTG.TaxonGroup = Spp.TaxonGroup
	WHERE LTG.DefaultGR IS NOT NULL AND LTG.DefaultGR <> ''
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'

	/*---------------------------------------------------------------------------*\
		Update location and grid reference for taxon names
	\*---------------------------------------------------------------------------*/

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating location details from taxon names in LERC_Spp_Table'
	
	UPDATE LERC_Spp_Table
	SET Location = LTN.DefaultLocation,
		Location2 = NULL,
		Sensitive = 'Y'
	FROM LERC_Spp_Table Spp
	INNER JOIN LERC_Taxon_Names LTN ON LTN.TaxonGroup = Spp.TaxonGroup AND LTN.TaxonName = Spp.TaxonName
	WHERE LTN.DefaultLocation IS NOT NULL AND LTN.DefaultLocation <> ''
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating grid ref from taxon names in LERC_Spp_Table'
	
	UPDATE LERC_Spp_Table
	SET GridRef = dbo.AFSensitiveGR(GridRef, LTN.DefaultGR),
		Sensitive = 'Y'
	FROM LERC_Spp_Table Spp
	INNER JOIN LERC_Taxon_Names LTN ON LTN.TaxonGroup = Spp.TaxonGroup AND LTN.TaxonName = Spp.TaxonName
	WHERE LTN.DefaultGR IS NOT NULL AND LTN.DefaultGR <> ''
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'

	/*---------------------------------------------------------------------------*\
		Update grid reference details for sensitive records
	\*---------------------------------------------------------------------------*/
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating grid ref details for sensitive records in LERC_Spp_Table'
	
	UPDATE LERC_Spp_Table
	SET Grid10k = dbo.FormatGridRef(GridRef, RefSystem, 0),
		Grid1k = dbo.FormatGridRef(GridRef, RefSystem, 1),
		GRPrecision = dbo.AFGridRefPrecision(GridRef, RefSystem, 0),
		Easting = dbo.LCRETURNEASTINGSV2(GridRef, RefSystem, 0),
		Northing = dbo.LCRETURNNORTHINGSV2(GridRef, RefSystem, 0)
	FROM LERC_Spp_Table Spp
	WHERE Sensitive = 'Y'
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'

	/*---------------------------------------------------------------------------*\
		Delete invalid occurrences
	\*---------------------------------------------------------------------------*/
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Deleting invalid occurrences from LERC_Spp_Table'
	
	DELETE LERC_Spp_Table
	FROM LERC_Spp_Table Spp
	WHERE TaxonName IS NULL
	OR Easting = 0
	OR Northing = 0
	OR GridRef IS NULL
	OR RecDate IS NULL
	OR RecDate = 'Unknown'
	OR RecYear = 9999
	OR RecYear > YEAR(GETDATE())
	OR RecYear IS NULL
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows deleted from LERC_Spp_Table'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Deleting invalid species from LERC_Spp_Table'
	
	DELETE LERC_Spp_Table
	FROM LERC_Spp_Table Spp
	INNER JOIN LERC_TAXON_NAMES LTN ON LTN.TaxonGroup = Spp.TaxonGroup AND LTN.TaxonName = Spp.TaxonName
	WHERE LTN.InvalidSpp = 'Y'

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows deleted from LERC_Spp_Table'
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating historic flag from taxon names in LERC_Spp_Table'
	
	UPDATE LERC_Spp_Table
	SET HistoricRec = 'Y'
	FROM LERC_Spp_Table Spp
	INNER JOIN LERC_TAXON_NAMES LTN ON LTN.TaxonGroup = Spp.TaxonGroup AND LTN.TaxonName = Spp.TaxonName
	WHERE Spp.RecYear < LTN.EarliestYear

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating historic flag from taxon groups in LERC_Spp_Table'
	
	UPDATE LERC_Spp_Table
	SET HistoricRec = 'Y'
	FROM LERC_Spp_Table Spp
	INNER JOIN LERC_TAXON_GROUPS LTG ON LTG.TaxonGroup = Spp.TaxonGroup
	WHERE Spp.RecYear < LTG.EarliestYear

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), REPLACE(CONVERT(varchar, CAST(@@RowCount As Money)), '.00', '') + ' rows updated in LERC_Spp_Table'
	
	/*---------------------------------------------------------------------------*\
		Drop temporary indexes
	\*---------------------------------------------------------------------------*/
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Dropping temporary TOCC index from LERC_Spp_Table'
	
	DROP INDEX [IX_LERC_Spp_Table_RecOccKey] ON [dbo].[LERC_Spp_Table] WITH ( ONLINE = OFF )
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Dropping temporary TLIK index from LERC_Spp_Table'
	
	DROP INDEX [IX_LERC_Spp_Table_RecTLIKey] ON [dbo].[LERC_Spp_Table] WITH ( ONLINE = OFF )
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Dropping temporary Sample_Key index from LERC_Spp_Table'
	
	DROP INDEX [IX_LERC_Spp_Table_RecSamKey] ON [dbo].[LERC_Spp_Table] WITH ( ONLINE = OFF )
	
	/*---------------------------------------------------------------------------*\
		Adding permanent indexes
	\*---------------------------------------------------------------------------*/

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Adding Confidential index to LERC_Spp_Table'

	CREATE NONCLUSTERED INDEX [IX_LERC_Spp_Table_Confidential] ON [dbo].[LERC_Spp_Table]
	(
		[Confidential] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Adding HistoricRec index to LERC_Spp_Table'

	CREATE NONCLUSTERED INDEX [IX_LERC_Spp_Table_HistoricRec] ON [dbo].[LERC_Spp_Table]
	(
		[HistoricRec] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Adding NegativeRec index to LERC_Spp_Table'

	CREATE NONCLUSTERED INDEX [IX_LERC_Spp_Table_NegativeRec] ON [dbo].[LERC_Spp_Table]
	(
		[NegativeRec] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Adding TaxonGroup index to LERC_Spp_Table'

	CREATE NONCLUSTERED INDEX [IX_LERC_Spp_Table_TaxonGroup] ON [dbo].[LERC_Spp_Table]
	(
		[TaxonGroup] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Adding TaxonName index to LERC_Spp_Table'

	CREATE NONCLUSTERED INDEX [IX_LERC_Spp_Table_TaxonName] ON [dbo].[LERC_Spp_Table]
	(
		[TaxonName] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

	/*---------------------------------------------------------------------------*\
		Set spatial attributes and build spatial index
	\*---------------------------------------------------------------------------*/
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Updating spatial attributes in LERC_Spp_Table'
	
	EXECUTE dbo.AFSpatialiseSppExtract 'dbo', 'LERC_Spp_Table',  0, 999999, 0, 999999, 1, 10000, 100, 2, 0, 1
	
	INSERT INTO LERC_SQL_Update_Results SELECT CONVERT(VARCHAR(32), CURRENT_TIMESTAMP, 109 ), 'Ended.'

END
