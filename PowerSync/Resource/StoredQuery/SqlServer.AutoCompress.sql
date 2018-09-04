:setvar Schema "dbo"
:setvar Table "CSVToSSQLTest12"

IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('[$(Schema)].[$(Table)]') AND type_desc = 'CLUSTERED COLUMNSTORE')
BEGIN
    -- Even though this block doesn't execute when the above IF block is false, will still cause runtime errors. So we hide
    -- the SQL from SQL Server.
    EXEC sp_executesql N'ALTER TABLE [$(Schema)].[$(Table)] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = COLUMNSTORE_ARCHIVE)'
END
ELSE
BEGIN
    EXEC sp_executesql N'ALTER TABLE [$(Schema)].[$(Table)] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)'
END