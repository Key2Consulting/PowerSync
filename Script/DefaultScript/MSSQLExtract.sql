:setvar SourceSchema "dbo"
:setvar SourceTable "Test"

SELECT * 
FROM $(SourceSchema).$(SourceTable)