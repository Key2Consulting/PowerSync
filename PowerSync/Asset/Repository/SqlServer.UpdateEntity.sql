/****************************************************************************************************************/
--	Update Entity
/****************************************************************************************************************/

	:setvar ModifiedDateTime "1/1/1900"

--Variable
	:setvar EntityType "Variable"
	:setvar Type "Variable"
	:setvar Name "TestVar Default"
	:setvar Value "Test Default"

	:setvar ActivityLogID "0"

--VariableLog
	:setvar VariableValue "TestVar Default"
	:setvar VariableName "TestVar Default"

--ErrorLog
	:setvar Message "Test Error Message Default"
	:setvar Exception "Test Exeption Default"
	:setvar StackTrace ""

--Connection
	:setvar ConnectionString	"Server=DBName;Integrated Security=true;Database=TestTarget"
	:setvar Properties			""
	:setvar Provider			"SqlServer"


--ActivityLog
	:setvar ScriptAst			""
	:setvar Server				"DESKTOP"
	:setvar ScriptFile			"OleDB.ps1"
	:setvar StartDateTime		"1/1/1900"
	:setvar Status				"Started"



IF '$(EntityType)' = 'Variable' 
BEGIN
	UPDATE [PSYConfig].Variable
		SET [Value] = '$(Value)'
			,[ModifiedDateTime] = '$(ModifiedDateTime)'
		WHERE [Name] = '$(Name)'
END
ELSE IF '$(EntityType)' = 'Connection'
BEGIN
	UPDATE [PSYConfig].[Connection]  
		SET [Provider] = '$(Provider)'
			,[ConnectionString] = '$(ConnectionString)'
			,[CreatedDateTime] = '$(CreatedDateTime)'
			,[ModifiedDateTime] = '$(ModifiedDateTime)'
		WHERE [Name] = '$(Name)'
END

/*********************************
-- Input Values
-- EntityType: $(EntityType) 
-- CreatedDateTime: $(CreatedDateTime)
-- ModifiedDateTime: $(ModifiedDateTime)

Variable
	-- Type: $(Type)
	-- Name: $(Name)
	-- Value: $(Value)

	-- ActivityLogID: $(ActivityLogID)


--Connection
	--ConnectionString: $(ConnectionString)
	--Properties: $(Properties)			
	--Provider: $(Provider)

*********************************/