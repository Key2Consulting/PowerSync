------------------------------------------------------------------------
-- Create the Sql Server Repository against an existing (empty) database
------------------------------------------------------------------------

/****** Object:  Schema [PSY]    Script Date: 10/30/2018 4:32:17 PM ******/
CREATE SCHEMA [PSY]
GO
/****** Object:  Table [PSY].[Activity]    Script Date: 10/30/2018 4:32:17 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [PSY].[Activity](
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
	[ExecutionPID] [int] NULL,	
	[InputObject] [varchar](max) NULL,
	[ScriptBlock] [varchar](max) NOT NULL,
	[ScriptPath] [varchar](max) NOT NULL,
	[JobInstanceID] [varchar](50) NULL,
	[OutputObject] [varchar](max) NULL,
	[HadErrors] [bit] NULL,
	[Error] [varchar](max) NULL,
 CONSTRAINT [PK_Activity] PRIMARY KEY CLUSTERED 
(
	[ActivityID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
)
GO
/****** Object:  Table [PSY].[Connection]    Script Date: 10/30/2018 4:32:17 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [PSY].[Connection](
	[ConnectionID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](100) NOT NULL,
	[Provider] [varchar](50) NOT NULL,
	[Class] [varchar](100) NULL,
	[ConnectionString] [varchar](1000) NOT NULL,
	[Properties] [varchar](max) NULL,
	[CreatedDateTime] [datetime] NOT NULL,
	[ModifiedDateTime] [datetime] NOT NULL,
 CONSTRAINT [PK_Connection] PRIMARY KEY CLUSTERED 
(
	[ConnectionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
)
GO
/****** Object:  Table [PSY].[ErrorLog]    Script Date: 10/30/2018 4:32:17 PM ******/
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
)
GO
/****** Object:  Table [PSY].[MessageLog]    Script Date: 10/30/2018 4:32:17 PM ******/
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
)
GO
/****** Object:  Table [PSY].[QueryLog]    Script Date: 10/30/2018 4:32:17 PM ******/
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
)
GO
/****** Object:  Table [PSY].[Variable]    Script Date: 10/30/2018 4:32:17 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [PSY].[Variable](
	[Name] [varchar](50) NOT NULL,
	[Value] [varchar](max) NULL,
	[DataType] [varchar](50) NULL,
	[CreatedDateTime] [datetime] NOT NULL,
	[ModifiedDateTime] [datetime] NOT NULL,
 CONSTRAINT [PK_Variable] PRIMARY KEY CLUSTERED 
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
)
GO
/****** Object:  Table [PSY].[VariableLog]    Script Date: 10/30/2018 4:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [PSY].[VariableLog](
	[VariableLogID] [int] IDENTITY(1,1) NOT NULL,
	[ActivityID] [int] NULL,
	[Type] [varchar](50) NOT NULL,
	[Name] [varchar](100) NOT NULL,
	[Value] [varchar](max) NULL,
	[CreatedDateTime] [datetime] NOT NULL,
 CONSTRAINT [PK_VariableLog] PRIMARY KEY CLUSTERED 
(
	[VariableLogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
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
/****** Object:  StoredProcedure [PSY].[ActivityCreate]    Script Date: 10/30/2018 4:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [PSY].[ActivityCreate]
	@ParentActivityID INT = NULL,
	@Name VARCHAR(100),
	@Status VARCHAR(50),
	@StartDateTime DATETIME,
	@ExecutionDateTime DATETIME = NULL,
	@EndDateTime DATETIME = NULL,
	@Queue VARCHAR(100),
	@OriginatingServer VARCHAR(100),
	@ExecutionServer VARCHAR(100) = NULL,
	@ExecutionPID INT = NULL,
	@InputObject VARCHAR(MAX) = NULL,
	@ScriptBlock VARCHAR(MAX),
	@ScriptPath VARCHAR(MAX),
	@JobInstanceID VARCHAR(50) = NULL,
	@OutputObject VARCHAR(MAX) = NULL,
	@HadErrors BIT = NULL,
	@Error VARCHAR(MAX) = NULL
AS
BEGIN
	SET NOCOUNT ON

	INSERT INTO [PSY].[Activity]
		([ParentActivityID]
		,[Name]
		,[Status]
		,[StartDateTime]
		,[ExecutionDateTime]
		,[ExecutionPID]
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
		,@ExecutionPID
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

	SELECT @@IDENTITY [ActivityID]
END
GO
/****** Object:  StoredProcedure [PSY].[ActivityUpdate]    Script Date: 10/30/2018 4:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [PSY].[ActivityUpdate]
	@ActivityID INT,
	@Status VARCHAR(50),
	@ExecutionDateTime DATETIME = NULL,
	@ExecutionServer VARCHAR(100) = NULL,
	@ExecutionPID INT = NULL,
	@JobInstanceID VARCHAR(50) = NULL,
	@EndDateTime DATETIME = NULL,
	@Queue VARCHAR(100) = NULL,
	@InputObject VARCHAR(MAX) = NULL,
	@OutputObject VARCHAR(MAX) = NULL,
	@HadErrors BIT = NULL,
	@Error VARCHAR(MAX) = NULL
AS

	
BEGIN
	SET NOCOUNT ON

	UPDATE [PSY].[Activity]
	SET	[Status] = @Status
		,[ExecutionDateTime] = @ExecutionDateTime
		,[ExecutionServer] = @ExecutionServer
		,[ExecutionPID] = @ExecutionPID
		,[JobInstanceID] = @JobInstanceID
		,[EndDateTime] = @EndDateTime
		,[Queue] = @Queue
		,[InputObject] = @InputObject
		,[OutputObject] = @OutputObject
		,[HadErrors] = @HadErrors
		,[Error] = @Error
	WHERE ActivityID = @ActivityID

END
GO
CREATE PROCEDURE [PSY].[ActivityRead]
	@ActivityID INT
AS

BEGIN
	SET NOCOUNT ON

	SELECT *
	FROM [PSY].[Activity]
	WHERE ActivityID = @ActivityID

END
GO
/****** Object:  StoredProcedure [PSY].[ConnectionCreate]    Script Date: 10/30/2018 4:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [PSY].[ConnectionCreate]
		@Name VARCHAR(100)
		,@Provider  VARCHAR(50)
		,@ConnectionString  VARCHAR(1000)
		,@Properties  VARCHAR(MAX) = NULL
	AS

	
BEGIN
	SET NOCOUNT ON

	INSERT INTO [PSY].[Connection]
	(	[Name]
      ,[Provider]
      ,[Class]
      ,[ConnectionString]
	  ,[Properties]
      ,[CreatedDateTime]
	)
	VALUES(@Name 
		,@Provider  
		,NULL
		,@ConnectionString  
		,@Properties
		,GETDATE())

	SELECT @@IDENTITY [ConnectionID]
END
GO
/****** Object:  StoredProcedure [PSY].[ConnectionDelete]    Script Date: 10/30/2018 4:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [PSY].[ConnectionDelete]
	@ConnectionID  VARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON

	DELETE FROM [PSY].[Connection]
	WHERE [ConnectionID] = @ConnectionID
END
GO
/****** Object:  StoredProcedure [PSY].[ConnectionFind]    Script Date: 10/30/2018 4:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [PSY].[ConnectionFind]
	@EntityField VARCHAR(100) 
    ,@EntityFieldValue VARCHAR(100)
    ,@Wildcards INT
AS

IF @EntityField = 'Name'
BEGIN
	SELECT *
	FROM [PSY].[Connection]
	WHERE [Name] = @EntityFieldValue
END
ELSE BEGIN
	DECLARE @ErrorMessage VARCHAR(1000) = 'ConnectionFindEntity has not been configured for EntityField:' + @EntityField
	RAISERROR(@ErrorMessage,99, @ErrorMessage, 1)
END
GO
/****** Object:  StoredProcedure [PSY].[ConnectionUpdate]    Script Date: 10/30/2018 4:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [PSY].[ConnectionUpdate]
		@Name VARCHAR(100)
		,@Provider  VARCHAR(50)
		,@ConnectionString  VARCHAR(1000)
		,@Properties  VARCHAR(Max) = NULL
	AS

	
BEGIN
	SET NOCOUNT ON

	UPDATE [PSY].[Connection]
	SET	[Provider] = @Provider
      ,[Class] = NULL
      ,[ConnectionString] = @ConnectionString
	  ,[Properties] = @Properties
      ,[ModifiedDateTime] = GETDATE()
	WHERE [Name] = @Name

	SELECT [ConnectionID]
	FROM  [PSY].[Connection]
	WHERE [Name] = @Name
END
GO
/****** Object:  StoredProcedure [PSY].[ErrorLogCreate]    Script Date: 10/30/2018 4:32:18 PM ******/
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
/****** Object:  StoredProcedure [PSY].[MessageLogCreate]    Script Date: 10/30/2018 4:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [PSY].[MessageLogCreate]
	@ActivityID INT = NULL,
	@Type VARCHAR(50),
	@Category VARCHAR(100) = NULL,
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
/****** Object:  StoredProcedure [PSY].[QueryLogCreate]    Script Date: 10/30/2018 4:32:18 PM ******/
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
	@QueryParam VARCHAR(MAX) = NULL
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
/****** Object:  StoredProcedure [PSY].[VariableCreate]    Script Date: 10/30/2018 4:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [PSY].[VariableCreate]
		@Name VARCHAR(100)
		,@Value  VARCHAR(MAX)
		,@DataType VARCHAR(50)
	AS

	
BEGIN
	SET NOCOUNT ON

	INSERT INTO [PSY].[Variable]
	(	[Name]
      ,[Value]
	  ,[DataType]
      ,[CreatedDateTime]
	)
	VALUES(@Name 
		,@Value  
		,@DataType
		,GETDATE())

	SELECT @Name AS [VariableName]
END
GO
/****** Object:  StoredProcedure [PSY].[VariableDelete]    Script Date: 10/30/2018 4:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [PSY].[VariableDelete]
	@ID  VARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON

	DELETE FROM [PSY].[Variable]
	WHERE [Name] = @ID
END
GO
/****** Object:  StoredProcedure [PSY].[VariableFind]    Script Date: 10/30/2018 4:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [PSY].[VariableFind]
	@EntityField VARCHAR(100) 
    ,@EntityFieldValue VARCHAR(100)
    ,@Wildcards INT
AS


--DECLARE @EntityField VARCHAR(100) = 'Name'
--    ,@EntityFieldValue VARCHAR(100) = '*Var'
--    ,@Wildcards INT = 1

IF @EntityField = 'Name'
BEGIN
	IF @Wildcards = 0
	BEGIN
		SELECT *
		FROM [PSY].[Variable]
		WHERE [Name] = @EntityFieldValue
	END
	ELSE BEGIN
		SET @EntityFieldValue = REPLACE(REPLACE(@EntityFieldValue,'*','%'),'?','_')

		SELECT *
		FROM [PSY].[Variable]
		WHERE [Name] LIKE  @EntityFieldValue 
	END
END
ELSE BEGIN
	DECLARE @ErrorMessage VARCHAR(1000) = 'VariableFind has not been configured for EntityField:' + @EntityField
	RAISERROR(@ErrorMessage,99, @ErrorMessage, 1)
END

GO
/****** Object:  StoredProcedure [PSY].[VariableLogCreate]    Script Date: 10/30/2018 4:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [PSY].[VariableLogCreate]
	@ActivityID INT = NULL,
	@Type VARCHAR(50),
	@Name VARCHAR(100),
	@Value VARCHAR(MAX) = NULL
AS
BEGIN
	SET NOCOUNT ON

	INSERT INTO [PSY].[VariableLog]
		([ActivityID]
		,[Type]
		,[Name]
		,[Value]
		,[CreatedDateTime])
	VALUES
		(@ActivityID
		,@Type
		,@Name
		,@Value
		,GETDATE())

	SELECT @@IDENTITY VariableLogID
END
GO
/****** Object:  StoredProcedure [PSY].[VariableUpdate]    Script Date: 10/30/2018 4:32:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [PSY].[VariableUpdate]
		@Name VARCHAR(100)
		,@Value  VARCHAR(MAX)
		,@DataType VARCHAR(50)
	AS

	
BEGIN
	SET NOCOUNT ON

	UPDATE [PSY].[Variable]
	SET [Value] = @Value
		,[DataType] = @DataType
		,[ModifiedDateTime] = GETDATE()
	WHERE [Name] = @Name
	
	SELECT @Name AS [Name]
END
GO

CREATE PROCEDURE [PSY].[LogSearch]
	@Attribute VARCHAR(128),
	@Search VARCHAR(MAX),
	@Wildcards BIT
AS
BEGIN
	SET NOCOUNT ON

	-- Convert PowerShell's wildcard tokens to SQL Server compatible ones.
	IF @Wildcards = 1
	BEGIN
		SET @Search = REPLACE(@Search, '*', '%')
		SET @Search = REPLACE(@Search, '?', '_')
	END

	;WITH Logs AS
	(
		SELECT
			[ErrorLogID] [ID]
			,[ActivityID]
			,[Type]
			,[CreatedDateTime]
			,[Message] [Generic1]
			,[Exception] [Generic2]
			,[StackTrace] [Generic3]
			,[Invocation] [Generic4]
		FROM [PSY].[ErrorLog]
		UNION ALL
		SELECT
			[MessageLogID]
			,[ActivityID]
			,[Type]
			,[CreatedDateTime]
			,[Category] [Generic1]
			,[Message] [Generic2]
			,NULL [Generic3]
			,NULL [Generic4]
		FROM [PSY].[MessageLog]
		UNION ALL
		SELECT
			[QueryLogID]
			,[ActivityID]
			,[Type]
			,[CreatedDateTime]
			,[Connection] [Generic1]
			,[QueryName] [Generic2]
			,[Query] [Generic3]
			,[QueryParam] [Generic4]
		FROM [PSY].[QueryLog]
		UNION ALL
		SELECT 
			[VariableLogID]
			,[ActivityID]
			,[Type]
			,[CreatedDateTime]
			,[Name] [Generic1]
			,[Value] [Generic2]
			,NULL [Generic3]
			,NULL [Generic4]
		FROM [PSY].[VariableLog]
	)
	SELECT *
	FROM Logs
	WHERE
		([ActivityID] = @Search AND (@Attribute = 'ActivityID' OR @Attribute IS NULL))
		OR [Generic1] LIKE '%' + @Search + '%'
		OR [Generic2] LIKE '%' + @Search + '%'
		OR [Generic3] LIKE '%' + @Search + '%'
		OR [Generic4] LIKE '%' + @Search + '%'
		
END
GO

CREATE PROCEDURE [PSY].[ActivityDequeue]
	@Queue VARCHAR(100)
AS
BEGIN
	SET NOCOUNT ON

	-- Remove any available activity from the given queue concurrent with other processes. The update should
	-- block anyone else trying to do the same.
	DECLARE @affected TABLE(ActivityID INT)

	;WITH Available AS
	(
		SELECT TOP 1 *
		FROM [PSY].[Activity]
		WHERE
			[Queue] = @Queue				-- in our queue
			AND [Status] = 'Started'		-- started (which is the first phase of an activity)
		ORDER BY ActivityID ASC
	)
	UPDATE Available
	SET [Status] = 'Dequeued'
	OUTPUT inserted.ActivityID
	INTO @affected
	
	-- Return the dequeued activity.
	SELECT *
	FROM [PSY].[Activity]
	WHERE ActivityID IN (SELECT ActivityID FROM @affected)
		
END
GO