------------------------------------------------------------------
-- RECREATE TEST DATABASE
------------------------------------------------------------------

-- Kill any active connections to the test database (from https://stackoverflow.com/questions/7197574/script-to-kill-all-connections-to-a-database-more-than-restricted-user-rollback)
DECLARE @kill varchar(8000) = '';  
SELECT @kill = @kill + 'kill ' + CONVERT(varchar(5), session_id) + ';'  
FROM sys.dm_exec_sessions
WHERE database_id  = db_id('$(TestDB)')

EXEC(@kill);

-- Drop and recreate the database
IF EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = N'$(TestDB)')
	DROP DATABASE [$(TestDB)]