:setvar LogTableName "[Log].[Execution]"
:setvar Message "Logging Message"
:setvar LoggingGUID "11112222"
:setvar Status "In Process"

--Begin Logging to SQL Table
	INSERT INTO $(LogTableName) (LogID,ScriptName,StartDateTime,[Status]) VALUES('$(LoggingGUID)','$(Message)',GETDATE(),'$(Status)') 

	SELECT @@IDENTITY AS LogExecutionID