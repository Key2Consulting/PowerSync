:setvar PublishTableName "dbo.Test"
:setvar TargetTableName "Load.Test"

--
-- Perform any staging or transformations to the loaded table per your specific requirements
--

-- Publish this one table in a transactionally consistent manner (could also wait until Publish step)
SET XACT_ABORT ON
BEGIN TRANSACTION

IF (OBJECT_ID('$(PublishTableName)') IS NOT NULL)
    DROP TABLE $(PublishTableName)

ALTER SCHEMA dbo TRANSFER $(TargetTableName)

COMMIT TRANSACTION