------------------------------------------------------------------
-- Repo Objects
------------------------------------------------------------------
CREATE SCHEMA [PSY]
GO


CREATE TABLE [PSY].[Connection](
	[ConnectionID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](100) NOT NULL,
	[Provider]  [varchar](50) NOT NULL,
	[Class] [varchar](100) NOT NULL,
	[ConnectionString] [varchar](1000) NOT NULL,
	[CreatedDateTime] [datetime] NOT NULL,
	[ModifiedDateTime] [datetime] NOT NULL,
 CONSTRAINT [PK_Connection] PRIMARY KEY CLUSTERED 
(
	[ConnectionID] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF)
)

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
CREATE TABLE [PSY].[ActivityLog](
	[ActivityLogID] [int] IDENTITY(1,1) NOT NULL,
	[ParentActivityLogID] [int] NULL,
	[Name] [varchar](100) NULL,
	[Server] [varchar](100) NOT NULL,
	[ScriptFile] [varchar](4000) NOT NULL,
	[ScriptAst] [varchar](max) NOT NULL,
	[Status] [varchar](50) NOT NULL,
	[StartDateTime] [datetime] NOT NULL,
	[EndDateTime] [datetime] NULL,
 CONSTRAINT [PK_ActivityLog] PRIMARY KEY CLUSTERED 
(
	[ActivityLogID] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF)
)
GO

CREATE TABLE [PSY].[ExceptionLog](
	[ExceptionLogID] [int] IDENTITY(1,1) NOT NULL,
	[ActivityLogID] [int] NOT NULL,
	[Message] [varchar](max) NULL,
	[Exception] [varchar](max) NOT NULL,
	[StackTrace] [varchar](max) NOT NULL,
	[CreatedDateTime] [datetime] NOT NULL,
 CONSTRAINT [PK_ExceptionLog] PRIMARY KEY CLUSTERED 
(
	[ExceptionLogID] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF)
)
GO

CREATE TABLE [PSY].[InformationLog](
	[InformationLogID] [int] IDENTITY(1,1) NOT NULL,
	[ActivityLogID] [int] NOT NULL,
	[Category] [varchar](100) NULL,
	[Message] [varchar](max) NULL,
	[CreatedDateTime] [datetime] NOT NULL,
 CONSTRAINT [PK_InformationLog] PRIMARY KEY CLUSTERED 
(
	[InformationLogID] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF)
)
GO

CREATE TABLE [PSY].[VariableLog](
	[VariableLogID] [int] IDENTITY(1,1) NOT NULL,
	[ActivityLogID] [int] NOT NULL,
	[Type] VARCHAR(50),
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
ALTER TABLE [PSY].[Variable] ADD  CONSTRAINT [DF_Variable_CreatedDateTime]  DEFAULT (getdate()) FOR [CreatedDateTime]
GO
ALTER TABLE [PSY].[Variable] ADD  CONSTRAINT [DF_Variable_ModifiedDateTime]  DEFAULT (getdate()) FOR [ModifiedDateTime]
GO
ALTER TABLE [PSY].[ExceptionLog] ADD  CONSTRAINT [DF_ExceptionLog_CreatedDateTime]  DEFAULT (getdate()) FOR [CreatedDateTime]
GO
ALTER TABLE [PSY].[InformationLog] ADD  CONSTRAINT [DF_InformationLog_CreatedDateTime]  DEFAULT (getdate()) FOR [CreatedDateTime]
GO
ALTER TABLE [PSY].[VariableLog] ADD  CONSTRAINT [DF_VariableLog_CreatedDateTime]  DEFAULT (getdate()) FOR [CreatedDateTime]
GO