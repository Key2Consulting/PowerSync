:setvar FinalSchema "dbo"
:setvar FinalTable "Test"
:setvar LoadSchema "dbo"
:setvar LoadTable "Load_Test"
:setvar Create "1"
:setvar Overwrite "1"

BEGIN TRANSACTION
BEGIN TRY
    -- If the final table exists
	IF OBJECT_ID('[$(FinalSchema)].[$(FinalTable)]') IS NOT NULL
    BEGIN
        -- and the Create table and Overwrite options are set, we blow away and completely reload via a swap. This
        -- option ensures any new columns that come through the feed are copied over, but is obviously limited in
        -- terms of performance since reloading an entire table isn't always feasible.
        IF '$(Create)' = 'TRUE' AND '$(Overwrite)' = 'TRUE'
        BEGIN
		    DROP TABLE [$(FinalSchema)].[$(FinalTable)]
            EXEC sp_rename '$(LoadSchema).$(LoadTable)', '$(FinalTable)'
        END
        -- and just the Overwrite option is set, truncate the target so it can be reloaded. This option allows
        -- users to own and customize the target table (indexes, constraints, etc), while still overwriting its contents.
        ELSE IF '$(Overwrite)' = 'TRUE'
        BEGIN
            TRUNCATE TABLE [$(FinalSchema)].[$(FinalTable)]
            
            EXEC sp_executesql N'  -- Must use dynamic SQL to avoid compilation errors when this condition is not executed
                INSERT INTO [$(FinalSchema)].[$(FinalTable)] WITH (TABLOCK)
                SELECT *
                FROM [$(LoadSchema)].[$(LoadTable)]
            '
            DROP TABLE [$(LoadSchema)].[$(LoadTable)]                       -- clean up load table
        END
        -- and no Overwrite is set, which means Append. So we simply tack on the new data to the old table.
        ELSE
        BEGIN
            EXEC sp_executesql N'  -- Must use dynamic SQL to avoid compilation errors when this condition is not executed
                INSERT INTO [$(FinalSchema)].[$(FinalTable)] WITH (TABLOCK)
                SELECT *
                FROM [$(LoadSchema)].[$(LoadTable)]
            '
            
            DROP TABLE [$(LoadSchema)].[$(LoadTable)]                       -- clean up load table
        END
    END
    ELSE
    -- Otherwise, the final table does not exist, so we simply rename the load table as the final
    BEGIN
        EXEC sp_rename '$(LoadSchema).$(LoadTable)', '$(FinalTable)'
    END
END TRY
BEGIN CATCH
	DECLARE @Error VARCHAR(500) = ERROR_MESSAGE()
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
	THROW 51000, @Error, 1
END CATCH

IF @@TRANCOUNT > 0
	COMMIT TRANSACTION