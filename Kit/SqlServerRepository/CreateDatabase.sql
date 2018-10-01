------------------------------------------------------------------------
-- Create the Sql Server Repository against an existing (empty) database
------------------------------------------------------------------------

/****** Object:  Schema [PSY]    Script Date: 10/1/2018 8:09:49 AM ******/
CREATE SCHEMA [PSY]
GO
/****** Object:  Table [PSY].[ActivityLog]    Script Date: 10/1/2018 8:09:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [PSY].[ActivityLog](
	[ActivityID] [int] IDENTITY(1,1) NOT NULL,
	[ParentActivityID] [int] NULL,
	[Name] [varchar](100) NULL,
	[Status] [varchar](50) NOT NULL,
	[StartDateTime] [datetime] NOT NULL,
	[ExecutionDateTime] [datetime] NULL,
	[EndDateTime] [datetime] NULL,
	[Queue] [varchar](100) NULL,
	[OriginatingServer] [varchar](100) NOT NULL,
	[ExecutionServer] [varchar](100) NULL,
	[InputObject] [varchar](max) NULL,
	[ScriptBlock] [varchar](max) NOT NULL,
	[ScriptPath] [varchar](max) NOT NULL,
	[JobInstanceID] [varchar](50) NULL,
	[OutputObject] [varchar](max) NULL,
	[HadErrors] [bit] NULL,
	[Error] [varchar](max) NULL,
 CONSTRAINT [PK_ActivityLog] PRIMARY KEY CLUSTERED 
(
	[ActivityID] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF)
)
GO
/****** Object:  Table [PSY].[Connection]    Script Date: 10/1/2018 8:09:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [PSY].[Connection](
	[ConnectionID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](100) NOT NULL,
	[Provider] [varchar](50) NOT NULL,
	[Class] [varchar](100) NOT NULL,
	[ConnectionString] [varchar](1000) NOT NULL,
	[CreatedDateTime] [datetime] NOT NULL,
	[ModifiedDateTime] [datetime] NOT NULL,
 CONSTRAINT [PK_Connection] PRIMARY KEY CLUSTERED 
(
	[ConnectionID] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF)
)
GO
/****** Object:  Table [PSY].[ErrorLog]    Script Date: 10/1/2018 8:09:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [PSY].[ErrorLog](
	[ErrorLogID] [int] IDENTITY(1,1) NOT NULL,
	[ActivityID] [int] NULL,
	[Type] [varchar](50) NOT NULL,
	[Message] [varchar](max) NULL,
	[Exception] [varchar](max) NOT NULL,
	[StackTrace] [varchar](max) NOT NULL,
	[Invocation] [varchar](max) NOT NULL,
	[CreatedDateTime] [datetime] NOT NULL,
 CONSTRAINT [PK_ErrorLog] PRIMARY KEY CLUSTERED 
(
	[ErrorLogID] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF)
)
GO
/****** Object:  Table [PSY].[MessageLog]    Script Date: 10/1/2018 8:09:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [PSY].[MessageLog](
	[MessageLogID] [int] IDENTITY(1,1) NOT NULL,
	[ActivityID] [int] NULL,
	[Type] [varchar](50) NOT NULL,
	[Category] [varchar](100) NULL,
	[Message] [varchar](max) NOT NULL,
	[CreatedDateTime] [datetime] NOT NULL,
 CONSTRAINT [PK_MessageLog] PRIMARY KEY CLUSTERED 
(
	[MessageLogID] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF)
)
GO
/****** Object:  Table [PSY].[QueryLog]    Script Date: 10/1/2018 8:09:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [PSY].[QueryLog](
	[QueryLogID] [int] IDENTITY(1,1) NOT NULL,
	[ActivityID] [int] NULL,
	[Type] [varchar](50) NOT NULL,
	[Connection] [varchar](100) NOT NULL,
	[QueryName] [varchar](500) NOT NULL,
	[Query] [varchar](max) NOT NULL,
	[QueryParam] [varchar](max) NULL,
	[CreatedDateTime] [datetime] NOT NULL,
 CONSTRAINT [PK_QueryLog] PRIMARY KEY CLUSTERED 
(
	[QueryLogID] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF)
)
GO
/****** Object:  Table [PSY].[Variable]    Script Date: 10/1/2018 8:09:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [PSY].[Variable](
	[Name] [varchar](50) NOT NULL,
	[Value] [varchar](max) NULL,
	[CreatedDateTime] [datetime] NOT NULL,
	[ModifiedDateTime] [datetime] NOT NULL,
 CONSTRAINT [PK_Variable] PRIMARY KEY CLUSTERED 
(
	[Name] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF)
)
GO
/****** Object:  Table [PSY].[VariableLog]    Script Date: 10/1/2018 8:09:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [PSY].[VariableLog](
	[VariableLogID] [int] IDENTITY(1,1) NOT NULL,
	[ActivityID] [int] NULL,
	[Type] [varchar](50) NOT NULL,
	[VariableName] [varchar](100) NOT NULL,
	[VariableValue] [varchar](max) NULL,
	[CreatedDateTime] [datetime] NOT NULL,
 CONSTRAINT [PK_VariableLog] PRIMARY KEY CLUSTERED 
(
	[VariableLogID] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF)
)
GO
ALTER TABLE [PSY].[Connection] ADD  CONSTRAINT [DF_Connection_CreatedDateTime]  DEFAULT (getdate()) FOR [CreatedDateTime]
GO
ALTER TABLE [PSY].[Connection] ADD  CONSTRAINT [DF_Connection_ModifiedDateTime]  DEFAULT (getdate()) FOR [ModifiedDateTime]
GO
ALTER TABLE [PSY].[MessageLog] ADD  CONSTRAINT [DF_InformationLog_CreatedDateTime]  DEFAULT (getdate()) FOR [CreatedDateTime]
GO
ALTER TABLE [PSY].[Variable] ADD  CONSTRAINT [DF_Variable_CreatedDateTime]  DEFAULT (getdate()) FOR [CreatedDateTime]
GO
ALTER TABLE [PSY].[Variable] ADD  CONSTRAINT [DF_Variable_ModifiedDateTime]  DEFAULT (getdate()) FOR [ModifiedDateTime]
GO
ALTER TABLE [PSY].[VariableLog] ADD  CONSTRAINT [DF_VariableLog_CreatedDateTime]  DEFAULT (getdate()) FOR [CreatedDateTime]
GO
/****** Object:  StoredProcedure [PSY].[ActivityCreate]    Script Date: 10/1/2018 8:09:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [PSY].[ActivityCreate]
	@ParentActivityID INT,
	@Name VARCHAR(100),
	@Status VARCHAR(50),
	@StartDateTime DATETIME,
	@ExecutionDateTime DATETIME,
	@EndDateTime DATETIME,
	@Queue VARCHAR(100),
	@OriginatingServer VARCHAR(100),
	@ExecutionServer VARCHAR(100),
	@InputObject VARCHAR(MAX),
	@ScriptBlock VARCHAR(MAX),
	@ScriptPath VARCHAR(MAX),
	@JobInstanceID VARCHAR(50),
	@OutputObject VARCHAR(MAX),
	@HadErrors BIT,
	@Error VARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON

	INSERT INTO [PSY].[ActivityLog]
		([ParentActivityID]
		,[Name]
		,[Status]
		,[StartDateTime]
		,[ExecutionDateTime]
		,[EndDateTime]
		,[Queue]
		,[OriginatingServer]
		,[ExecutionServer]
		,[InputObject]
		,[ScriptBlock]
		,[ScriptPath]
		,[JobInstanceID]
		,[OutputObject]
		,[HadErrors]
		,[Error])
	VALUES
		(@ParentActivityID
		,@Name
		,@Status
		,@StartDateTime
		,@ExecutionDateTime
		,@EndDateTime
		,@Queue
		,@OriginatingServer
		,@ExecutionServer
		,@InputObject
		,@ScriptBlock
		,@ScriptPath
		,@JobInstanceID
		,@OutputObject
		,@HadErrors
		,@Error)

	SELECT @@IDENTITY [ActivityLogID]
END
GO
/****** Object:  StoredProcedure [PSY].[ErrorLogCreate]    Script Date: 10/1/2018 8:09:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [PSY].[ErrorLogCreate]
	@ActivityID INT = NULL,
	@Type VARCHAR(50),
	@Message VARCHAR(MAX),
	@Exception VARCHAR(MAX),
	@StackTrace VARCHAR(MAX),
	@Invocation VARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON

	INSERT INTO [PSY].[ErrorLog]
		([ActivityID]
		,[Type]
		,[Message]
		,[Exception]
		,[StackTrace]
		,[Invocation]
		,[CreatedDateTime])
	VALUES
		(@ActivityID
		,@Type
		,@Message
		,@Exception
		,@StackTrace
		,@Invocation
		,GETDATE())

	SELECT @@IDENTITY ErrorLogID
END
GO
/****** Object:  StoredProcedure [PSY].[MessageLogCreate]    Script Date: 10/1/2018 8:09:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [PSY].[MessageLogCreate]
	@ActivityID INT = NULL,
	@Type VARCHAR(50),
	@Category VARCHAR(100),
	@Message VARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON

	INSERT INTO [PSY].[MessageLog]
		([ActivityID]
		,[Type]
		,[Category]
		,[Message]
		,[CreatedDateTime])
	VALUES
		(@ActivityID
		,@Type
		,@Category
		,@Message
		,GETDATE())

	SELECT @@IDENTITY MessageLogID
END
GO
/****** Object:  StoredProcedure [PSY].[QueryLogCreate]    Script Date: 10/1/2018 8:09:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [PSY].[QueryLogCreate]
	@ActivityID INT = NULL,
	@Type VARCHAR(50),
	@Connection VARCHAR(100),
	@QueryName VARCHAR(500),	
	@Query VARCHAR(MAX),
	@QueryParam VARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON

	INSERT INTO [PSY].[QueryLog]
		([ActivityID]
		,[Type]
		,[Connection]
		,[QueryName]
		,[Query]
		,[QueryParam]
		,[CreatedDateTime])
	VALUES
		(@ActivityID
		,@Type
		,@Connection
		,@QueryName
		,@Query
		,@QueryParam
		,GETDATE())

	SELECT @@IDENTITY QueryLogID
END
GO
/****** Object:  StoredProcedure [PSY].[VariableLogCreate]    Script Date: 10/1/2018 8:09:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [PSY].[VariableLogCreate]
	@ActivityID INT = NULL,
	@Type VARCHAR(50),
	@VariableName VARCHAR(100),
	@VariableValue VARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON

	INSERT INTO [PSY].[VariableLog]
		([ActivityID]
		,[Type]
		,[VariableName]
		,[VariableValue]
		,[CreatedDateTime])
	VALUES
		(@ActivityID
		,@Type
		,@VariableName
		,@VariableValue
		,GETDATE())

	SELECT @@IDENTITY VariableLogID
END
GO
