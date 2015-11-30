USE NBNData
GO

EXECUTE dbo.AFSpatialiseSppExtract 'dbo', 'GiGL_SPP_Test', 400000, 700000, 50000, 350000, 1, 10000, 0, 1
GO
