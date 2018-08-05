:setvar ManifestID "1"
:setvar SourceSchema "[dbo]"
:setvar SourceTable "[TestCSVToSQL10000]"
:setvar TargetSchema "dbo"
:setvar TargetTable "TestRepository1"
:setvar ProcessType "F"
:setvar IncrementalField ""
:setvar LastIncrementalDateTime ""
:setvar MaxIncrementalDateTime ""
:setvar LastRunDateTime ""

UPDATE [dbo].[Manifest]
SET
	ProcessType = '$(ProcessType)'
	,IncrementalField = '$(IncrementalField)'
	,LastIncrementalDateTime = '$(LastIncrementalDateTime)'
	,MaxIncrementalDateTime = '$(MaxIncrementalDateTime)'
	,LastRunDateTime = '$(LastRunDateTime)'
WHERE
	ManifestID = $(ManifestID)