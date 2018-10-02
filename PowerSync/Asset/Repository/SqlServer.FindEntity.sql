/****************************************************************************************************************/
--	Find Entity
/****************************************************************************************************************/

:setvar EntityType "Variable"
:setvar SearchField "Name"
:setvar SearchValue "Test"
:setvar Wildcards "False"


/*********************************
-- Input Values
-- EntityType: $(EntityType) 
-- SearchField: $(SearchField)
-- SearchValue: $(SearchValue)
-- Wildcards: $(Wildcards)
*********************************/

IF '$(Wildcards)' = 'True' 
	SELECT *
	FROM [PSYConfig].$(EntityType)
	WHERE $(SearchField) LIKE REPLACE(REPLACE('$(SearchValue)','*','%'),'?','_')
ELSE
	SELECT *
	FROM [PSYConfig].$(EntityType)
	WHERE $(SearchField) = '$(SearchValue)'



