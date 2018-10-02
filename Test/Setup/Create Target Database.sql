CREATE DATABASE [PSYTestTarget]
GO
USE [PSYTestTarget]
GO

CREATE TABLE [dbo].[QuickTypedCSVCopy]
(
    [ID] INT NULL,
    [Size] [VARCHAR](50) NULL,
    [Price] SMALLMONEY NULL,
    [Color] [VARCHAR](50) NULL,
    [IsBackOrdered] BIT NULL,
    [Description] [VARCHAR](MAX) NULL
)