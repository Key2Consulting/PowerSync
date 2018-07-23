

 IF (OBJECT_ID('[Log].[Execution]') IS NULL)

	CREATE TABLE [Log].[Execution](
		[LogExecutionID] [int] IDENTITY(1,1) NOT NULL,
		[LogID] [varchar](50) NULL,
		[ScriptName] [varchar](50) NULL,
		[StartDateTime] [smalldatetime] NULL,
		[EndDateTime] [smalldatetime] NULL,
		[Status] [varchar](50) NULL,
	 CONSTRAINT [PK_Log.Execution] PRIMARY KEY CLUSTERED 
	(
		[LogExecutionID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
	GO


IF (OBJECT_ID('[Log].[ExecutionDetails]') IS NULL)

	CREATE TABLE [Log].[ExecutionDetails](
		[ExecutionDetailsID] [int] IDENTITY(1,1) NOT NULL,
		[LogExecutionID] [int] NULL,
		[LogDateTime] [smalldatetime] NULL,
		[MessageType] [varchar](50) NULL,
		[MessageText] [varchar](8000) NULL,
		[Severity] [int] NULL,
	CONSTRAINT [PK_Log_ExecutionDetails] PRIMARY KEY CLUSTERED ([ExecutionDetailsID] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
	GO


 IF (OBJECT_ID('[dbo].[Manifest]') IS NULL)

	CREATE TABLE [dbo].[Manifest](
		[ManifestID] [int] IDENTITY(1,1) NOT NULL,
		[SourceTableName] [varchar](50) NULL,
		[LoadTableName] [varchar](50) NULL,
		[PublishTableName] [varchar](50) NULL,
		[ProcessType] [varchar](50) NULL,
		[IncrementalField] [varchar](50) NULL,
		[MaxIncrementalValue] [varchar](50) NULL,
		[LastRunDateTime] [smalldatetime] NULL,
	 CONSTRAINT [PK_Manifest] PRIMARY KEY CLUSTERED 
	(
		[ManifestID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
	GO

