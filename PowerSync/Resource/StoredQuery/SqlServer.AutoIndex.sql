:setvar Table "dbo.CSVToSSQLTest12"

-- Detect if the table has any columns that can or cannot participate in a columnstore index
DECLARE @ColumnList VARCHAR(MAX)
SELECT @ColumnList = COALESCE(@ColumnList + ',', '') + '[' + [Name] + ']'
FROM sys.columns
WHERE
	object_id = OBJECT_ID('$(Table)')

DECLARE @CleanTableName VARCHAR(128) = OBJECT_NAME(OBJECT_ID('$(Table)'))
DECLARE @CleanSchemaName VARCHAR(128) = OBJECT_SCHEMA_NAME(OBJECT_ID('$(Table)'))

DECLARE @EligibleColumnList VARCHAR(MAX)
SELECT @EligibleColumnList = COALESCE(@EligibleColumnList + ',', '') + '[' + [Name] + ']'
FROM sys.columns
WHERE
	object_id = OBJECT_ID('$(Table)')
	AND NOT
	(
		(TYPE_NAME(user_type_id) = 'VARCHAR' AND max_length = -1)
		OR (TYPE_NAME(user_type_id) = 'NVARCHAR' AND max_length = -1)
		OR (TYPE_NAME(user_type_id) = 'VARBINARY' AND max_length = -1)
	)

-- If all columns are eligible, default to clustered columnstore index
DECLARE @SQL NVARCHAR(MAX) = ''
IF LEN(@ColumnList) = LEN(@EligibleColumnList)
BEGIN
	SET @SQL = 'CREATE CLUSTERED COLUMNSTORE INDEX [CCIX_' + @CleanSchemaName + '_' + @CleanTableName + '] ON $(Table) WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0)' 
	EXEC sp_executesql @SQL
END
-- If at least one column is eligible
ELSE IF LEN(@EligibleColumnList) > 0
BEGIN
	SET @SQL = 
		'CREATE NONCLUSTERED COLUMNSTORE INDEX [NCIX_' + @CleanSchemaName + '_' + @CleanTableName + '] ON $(Table) ('
		+ @EligibleColumnList 
		+ ')WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0)'
	EXEC sp_executesql @SQL
END
ELSE
-- Otherwise, leave as heap
BEGIN
	PRINT 'Automatic index not possible due to incompatible data types.';
	THROW 51000, 'Automatic index not possible due to incompatible data types.', 20;
END