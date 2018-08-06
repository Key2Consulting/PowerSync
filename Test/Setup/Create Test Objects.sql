CREATE DATABASE [$(TestDB)]
GO
USE [$(TestDB)]
GO

------------------------------------------------------------------
-- CREATE LOGGING STRUCTURES
------------------------------------------------------------------
GO
CREATE SCHEMA [Log]
GO
CREATE TABLE [Log].[Execution](
	[LogExecutionID] [int] IDENTITY(1,1) NOT NULL,
	[LogID] [varchar](50) NULL,
	[ParentLogID] [varchar](50) NULL,
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

CREATE TABLE [Log].[ExecutionDetails](
	[ExecutionDetailsID] [int] IDENTITY(1,1) NOT NULL,
	[LogExecutionID] [int] NULL,
	[LogDateTime] [smalldatetime] NULL,
	[MessageType] [varchar](50) NULL,
	[MessageText] [varchar](8000) NULL,
	[Severity] [int] NULL,
	CONSTRAINT [PK_Log_ExecutionDetails] PRIMARY KEY CLUSTERED 
(
	[ExecutionDetailsID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


------------------------------------------------------------------
-- TEST SCENARIO OBJECTS
------------------------------------------------------------------
GO
CREATE SCHEMA [Load]
GO
CREATE TABLE [dbo].[TestCSVToSQL10000](
	[ID] [int] NOT NULL,
	[Size] [varchar](max) NULL,
	[Price] [int] NULL,
	[Color] [varchar](max) NULL,
	[IsBackOrdered] [bit] NULL,
	[Description] [varchar](8000) NULL
)
GO
CREATE TABLE [dbo].[Manifest](
	[ManifestID] [int] IDENTITY(1,1) NOT NULL,
	[SourceSchema] [varchar](50) NULL,
	[SourceTable] [varchar](128) NULL,
	[TargetSchema] [varchar](50) NULL,
	[TargetTable] [varchar](128) NULL,
	[ProcessType] [char](1) NULL,
	[IncrementalField] [varchar](50) NULL,
	[LastIncrementalDateTime] [datetime] NULL,
	[MaxIncrementalDateTime] [datetime] NULL,
	[LastRunDateTime] [smalldatetime] NULL,
	CONSTRAINT [PK_Manifest] PRIMARY KEY CLUSTERED
(
	[ManifestID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO