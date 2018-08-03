
:setvar MessageDate ""
:setvar Message ""
:setvar MessageType "Log Begin"
:setvar VariableName ""
:setvar VariableValue ""
:setvar LogID "111111"
:setvar ParentLogID "AAAAA"
:setvar Status "In Process"
:setvar Severity "1"

--Check to see if the Log has been Created Yet
	DECLARE @LogExecutionID INT 
		,@LogMessage VARCHAR(8000) = '$(Message)'
		,@MessageType VARCHAR(50) = '$(MessageType)'
		,@MessageDate SMALLDATETIME = '$(MessageDate)'
		,@ErrorFlag BIT = 0

	IF @MessageDate = '1/1/1900' 
		SET  @MessageDate = GETDATE()

	SELECT @LogExecutionID = LogExecutionID
	FROM [Log].[Execution]
	WHERE LogID = '$(LogID)'

	IF @LogExecutionID IS NULL
	BEGIN
		--Begin Logging to SQL Table
		INSERT INTO [Log].[Execution] (LogID,ParentLogID,ScriptName,StartDateTime,[Status]) VALUES('$(LogID)','$(ParentLogID)','$(Message)',@MessageDate,'$(Status)') 

		SELECT @LogExecutionID =  @@IDENTITY 

		IF @LogMessage = ''
			SET @LogMessage = 'Logging Begin'
	END

	ELSE BEGIN--@LogExecutionID IS NULL
		IF @MessageType = 'EndLog'
		BEGIN
			UPDATE [Log].[Execution]
			SET EndDateTime = '$(MessageDate)'
				,[Status] = CASE WHEN [Status] = 'Error' THEN 'Error' ELSE 'Completed' END 
			WHERE  LogID = '$(LogID)'
		END
		ELSE IF @MessageType = 'Exception'
		BEGIN
			UPDATE [Log].[Execution]
			SET [Status] = 'Error'
			WHERE  LogID = '$(LogID)'

		END
	END

	INSERT INTO [Log].[ExecutionDetails]([LogExecutionID],[LogDateTime],[MessageType],[MessageText],[Severity])
	VALUES (@LogExecutionID,@MessageDate,@MessageType,@LogMessage,'$(Severity)')