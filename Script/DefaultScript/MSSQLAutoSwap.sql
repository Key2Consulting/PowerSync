:setvar TargetSchema "dbo"
:setvar TargetTable "Test"
:setvar TargetLoadTable "Test12ABCDEFG12345"
:setvar TargetOverwrite "False"

BEGIN TRANSACTION
BEGIN TRY
	IF OBJECT_ID('$(TargetSchema).$(TargetTable)') IS NOT NULL AND '$(TargetOverwrite)' = 'TRUE'
		DROP TABLE $(TargetSchema).$(TargetTable)
	EXEC sp_rename '$(TargetSchema).$(TargetLoadTable)', '$(TargetTable)'
END TRY
BEGIN CATCH
	DECLARE @Error VARCHAR(500) = ERROR_MESSAGE()
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
	THROW 51000, @Error, 1
END CATCH

IF @@TRANCOUNT > 0
	COMMIT TRANSACTION