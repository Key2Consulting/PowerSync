:setvar PublishTableName "dbo.Test"
:setvar LoadTableName "Load.Test"

--
-- Perform any staging or transformations to the loaded table per your specific requirements
--

-- Publish this one table in a transactionally consistent manner (could also wait until Publish step)
SET XACT_ABORT ON
BEGIN TRANSACTION

DROP TABLE IF EXISTS $(PublishTableName)

ALTER SCHEMA dbo TRANSFER $(LoadTableName)

COMMIT TRANSACTION