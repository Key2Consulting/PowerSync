/****************************************************************************************************************/
--	Create Entity
/****************************************************************************************************************/
	:setvar CreatedDateTime "1/1/1900"
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
	INSERT INTO  [PSYConfig].Variable( [Name],[Value],[CreatedDateTime],[ModifiedDateTime])
	VALUES('$(Name)','$(Value)','$(CreatedDateTime)','$(ModifiedDateTime)')
END
ELSE IF '$(EntityType)' = 'VariableLog'
BEGIN
	INSERT INTO  [PSYConfig].VariableLog ([ActivityLogID],[Type],VariableName,VariableValue,CreatedDateTime)
	VALUES($(ActivityLogID),'$(Type)','$(VariableName)','$(VariableValue)','$(CreatedDateTime)')
END
ELSE IF '$(EntityType)' = 'ErrorLog'
BEGIN
	INSERT INTO [PSYConfig].[ExceptionLog]  ([ActivityLogID],[Message],[Exception],[StackTrace],[CreatedDateTime])
	VALUES($(ActivityLogID),'$(Message)','$(Exception)','$(StackTrace)','$(CreatedDateTime)')
END
ELSE IF '$(EntityType)' = 'Connection'
BEGIN
	INSERT INTO [PSYConfig].[Connection]  ([Name],[Provider],[ConnectionString],[CreatedDateTime],[ModifiedDateTime])
	VALUES('$(Name)','$(Provider)','$(ConnectionString)','$(CreatedDateTime)','$(ModifiedDateTime)')
END
ELSE IF '$(EntityType)' = 'ActivityLog'
BEGIN
	INSERT INTO [PSYConfig].[ActivityLog]([ParentActivityLogID],[Name],[Server],[ScriptFile],[ScriptAst],[Status],[StartDateTime])
	VALUES(0,'$(Name)','$(Server)','$(ScriptFile)','$(ScriptAst)','$(Status)','$(StartDateTime)')
END

SELECT @@IDENTITY AS NewRow



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

VariableValue
	--VariableValue: $(VariableValue)
	--VariableName: $(VariableName)

ErrorLog
	-- Message: $(Message) 
	-- Exception: $(Exception)
	-- StackTrace: $(StackTrace)

--Connection
	--ConnectionString: $(ConnectionString)
	--Properties: $(Properties)			
	--Provider: $(Provider)

--ActivityLog
	-- Name: $(Name)
	-- ScriptAst: $(ScriptAst)
	-- Server: $(Server)
	-- ScriptFile: $(ScriptFile)
	-- StartDateTime: $(StartDateTime)
	-- Status: $(Status)


*********************************/