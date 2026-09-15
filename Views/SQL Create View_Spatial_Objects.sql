USE [NBNExtract]
GO

/****** Object:  View [dbo].[Spatial_Objects]    Script Date: 28/10/2024 19:00:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[Spatial_Objects]
AS
SELECT        schema_name(o.schema_id) + '.' + o.name AS ObjectName
FROM            sys.columns AS c INNER JOIN
                         sys.objects AS o ON o.object_id = c.object_id
WHERE        (schema_name(o.schema_id) = 'dbo') AND (type_name(c.user_type_id) IN ('geometry', 'geography'))
GO
