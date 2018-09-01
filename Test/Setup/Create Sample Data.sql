CREATE TABLE [dbo].[OddTypes](
	[ID] [int] NULL,
	[Geography] [geography] NULL,
	[Xml] [xml] NULL,
	[Binary] [binary](50) NULL,
	[DateTime2] [datetime2](7) NULL,
	[HierarchyID] [hierarchyid] NULL,
	[Geometry] [geometry] NULL,
	[SmallMoney] [smallmoney] NULL,
	[TimeStamp] [timestamp] NULL
)
GO

INSERT INTO [dbo].[OddTypes]
VALUES
	(
		1
		,geography::Point(47.65100, -122.34900, 4326)
		,'<xml></xml>'
		,CAST('hello world' AS BINARY(50))
		,GETDATE()
		,'/1/'
		,geometry::STGeomFromText('LINESTRING (100 100, 20 180, 180 180)', 0)
		,44.11
		,NULL
	)