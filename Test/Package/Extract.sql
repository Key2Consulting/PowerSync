:setvar SourceTableName "sys.objects"
:setvar SourceMaxRows "100"

SELECT TOP $(SourceMaxRows) * 
FROM $(SourceTableName)