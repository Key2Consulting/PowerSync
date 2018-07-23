:setvar SourceTableName "sys.objects"
:setvar MaxRows "100"

SELECT TOP $(MaxRows) * 
FROM $(SourceTableName)