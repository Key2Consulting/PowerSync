/****** Object:  Schema [Configuration]    Script Date: 8/28/2018 7:35:17 AM ******/
CREATE SCHEMA [Configuration]
GO
/****** Object:  Schema [Custom]    Script Date: 8/28/2018 7:35:17 AM ******/
CREATE SCHEMA [Custom]
GO
/****** Object:  Schema [CustomState]    Script Date: 8/28/2018 7:35:17 AM ******/
CREATE SCHEMA [CustomState]
GO
/****** Object:  Schema [Log]    Script Date: 8/28/2018 7:35:17 AM ******/
CREATE SCHEMA [Log]
GO
/****** Object:  Schema [State]    Script Date: 8/28/2018 7:35:17 AM ******/
CREATE SCHEMA [State]
GO
/****** Object:  Table [Configuration].[Connection]    Script Date: 8/28/2018 7:35:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Configuration].[Connection](
	[ConnectionID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](100) NOT NULL,
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
/****** Object:  Table [Configuration].[Registry]    Script Date: 8/28/2018 7:35:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Configuration].[Registry](
	[Name] [varchar](50) NOT NULL,
	[Value] [varchar](max) NULL,
	[CreatedDateTime] [datetime] NOT NULL,
	[ModifiedDateTime] [datetime] NOT NULL,
 CONSTRAINT [PK_Registry] PRIMARY KEY CLUSTERED 
(
	[Name] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF)
)
GO
/****** Object:  Table [Custom].[MyCustomState]    Script Date: 8/28/2018 7:35:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Custom].[MyCustomState](
	[MyCustomStateID] [int] NOT NULL,
	[StateContainerID] [int] NOT NULL,
	[Name] [varchar](100) NULL,
	[SourceConnection] [varchar](100) NULL,
	[SourceObject] [varchar](1000) NULL,
	[TargetConnection] [varchar](100) NULL,
	[TargetObject] [varchar](1000) NULL,
	[State] [nvarchar](max) NULL,
 CONSTRAINT [PK_MyCustomState] PRIMARY KEY CLUSTERED 
(
	[MyCustomStateID] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF)
)
GO
/****** Object:  Table [Log].[ActivityLog]    Script Date: 8/28/2018 7:35:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Log].[ActivityLog](
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
/****** Object:  Table [Log].[ExceptionLog]    Script Date: 8/28/2018 7:35:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Log].[ExceptionLog](
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
/****** Object:  Table [Log].[InformationLog]    Script Date: 8/28/2018 7:35:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Log].[InformationLog](
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
/****** Object:  Table [Log].[VariableLog]    Script Date: 8/28/2018 7:35:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Log].[VariableLog](
	[VariableLogID] [int] IDENTITY(1,1) NOT NULL,
	[ActivityLogID] [int] NOT NULL,
	[VariableName] [varchar](100) NOT NULL,
	[VariableValue] [varchar](max) NULL,
	[CreatedDateTime] [datetime] NOT NULL,
 CONSTRAINT [PK_VariableLog] PRIMARY KEY CLUSTERED 
(
	[VariableLogID] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF)
)
GO
/****** Object:  Table [State].[State]    Script Date: 8/28/2018 7:35:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [State].[State](
	[StateID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](100) NOT NULL,
	[Type] [tinyint] NOT NULL,
	[Value] [varchar](max) NULL,
	[CreatedDateTime] [datetime] NOT NULL,
	[ModifiedDateTime] [datetime] NOT NULL,
	[ReadDateTime] [datetime] NULL,
 CONSTRAINT [PK_State] PRIMARY KEY CLUSTERED 
(
	[StateID] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF)
)
GO
/****** Object:  Table [State].[StateItem]    Script Date: 8/28/2018 7:35:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [State].[StateItem](
	[StateItemID] [int] NOT NULL,
	[StateID] [int] NOT NULL,
	[Name] [varchar](100) NOT NULL,
	[Value] [varchar](max) NULL,
	[CreatedDateTime] [datetime] NOT NULL,
	[ModifiedDateTime] [datetime] NOT NULL,
	[ReadDateTime] [datetime] NULL,
 CONSTRAINT [PK_StateItem] PRIMARY KEY CLUSTERED 
(
	[StateItemID] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF)
)
GO
ALTER TABLE [Configuration].[Connection] ADD  CONSTRAINT [DF_Connection_CreatedDateTime]  DEFAULT (getdate()) FOR [CreatedDateTime]
GO
ALTER TABLE [Configuration].[Connection] ADD  CONSTRAINT [DF_Connection_ModifiedDateTime]  DEFAULT (getdate()) FOR [ModifiedDateTime]
GO
ALTER TABLE [Configuration].[Registry] ADD  CONSTRAINT [DF_Registry_CreatedDateTime]  DEFAULT (getdate()) FOR [CreatedDateTime]
GO
ALTER TABLE [Configuration].[Registry] ADD  CONSTRAINT [DF_Registry_ModifiedDateTime]  DEFAULT (getdate()) FOR [ModifiedDateTime]
GO
ALTER TABLE [Log].[ExceptionLog] ADD  CONSTRAINT [DF_ExceptionLog_CreatedDateTime]  DEFAULT (getdate()) FOR [CreatedDateTime]
GO
ALTER TABLE [Log].[InformationLog] ADD  CONSTRAINT [DF_InformationLog_CreatedDateTime]  DEFAULT (getdate()) FOR [CreatedDateTime]
GO
ALTER TABLE [Log].[VariableLog] ADD  CONSTRAINT [DF_VariableLog_CreatedDateTime]  DEFAULT (getdate()) FOR [CreatedDateTime]
GO
ALTER TABLE [State].[State] ADD  CONSTRAINT [DF_State_CreatedDateTime]  DEFAULT (getdate()) FOR [CreatedDateTime]
GO
ALTER TABLE [State].[State] ADD  CONSTRAINT [DF_State_ModifiedDateTime]  DEFAULT (getdate()) FOR [ModifiedDateTime]
GO
ALTER TABLE [State].[StateItem] ADD  CONSTRAINT [DF_StateItem_CreatedDateTime]  DEFAULT (getdate()) FOR [CreatedDateTime]
GO
ALTER TABLE [State].[StateItem] ADD  CONSTRAINT [DF_StateItem_ModifiedDateTime]  DEFAULT (getdate()) FOR [ModifiedDateTime]
GO
