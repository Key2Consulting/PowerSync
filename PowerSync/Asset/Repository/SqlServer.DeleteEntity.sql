/****************************************************************************************************************/
--	Delete Entity
--NOT TESTED
/****************************************************************************************************************/

:setvar EntityType "Variable"
:setvar SearchField "Name"
:setvar SearchValue "Test"

DELETE  
FROM [PSYConfig].$(EntityType)
WHERE $(SearchField) = '$(SearchValue)'

SELECT  @@ROWCOUNT AS RowsAffected