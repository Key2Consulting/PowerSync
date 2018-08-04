-- Note how MaxRows is not defined in either the manifest or command line configuration.
:setvar SourceSchema "sys"
:setvar SourceTable "objects"
:setvar MaxRows "100"

SELECT TOP $(MaxRows) *
FROM [$(SourceSchema)].[$(SourceTable)]