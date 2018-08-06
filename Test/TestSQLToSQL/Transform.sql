:setvar PublishSchema "dbo"
:setvar TargetSchema "Load"
:setvar TargetTable "Test"

--
-- Perform any staging or transformations to the loaded table per your specific requirements
--

-- Publish this one table in a transactionally consistent manner (could also wait until Publish step)
BEGIN TRANSACTION
BEGIN TRY
	IF (OBJECT_ID('$(PublishSchema).$(TargetTable)') IS NOT NULL)
		DROP TABLE $(PublishSchema).$(TargetTable)
	ALTER SCHEMA $(PublishSchema) TRANSFER $(TargetSchema).$(TargetTable)
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION
END CATCH

IF @@TRANCOUNT > 0
	COMMIT TRANSACTION