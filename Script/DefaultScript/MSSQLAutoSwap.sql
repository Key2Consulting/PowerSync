:setvar TargetSchema "dbo"
:setvar TargetTable "Test"
:setvar TargetLoadTable "Test12ABCDEFG12345"

BEGIN TRANSACTION
BEGIN TRY
	IF (OBJECT_ID('$(TargetSchema).$(TargetTable)') IS NOT NULL)
		DROP TABLE $(TargetSchema).$(TargetTable)
	EXEC sp_rename '$(TargetSchema).$(TargetLoadTable)', '$(TargetTable)'
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION
END CATCH

IF @@TRANCOUNT > 0
	COMMIT TRANSACTION