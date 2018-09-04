:setvar Schema "dbo"
:setvar Table "CSVToSSQLTest12"
:setvar IndexSuffix "dbo"

-- Detect if the table has any columns that can or cannot participate in a columnstore index
DECLARE @ColumnList VARCHAR(MAX)
SELECT @ColumnList = COALESCE(@ColumnList + ',', '') + '[' + [Name] + ']'
FROM sys.columns
WHERE
	object_id = OBJECT_ID('[$(Schema)].[$(Table)]')

DECLARE @EligibleColumnList VARCHAR(MAX)
SELECT @EligibleColumnList = COALESCE(@EligibleColumnList + ',', '') + '[' + [Name] + ']'
FROM sys.columns
WHERE
	object_id = OBJECT_ID('[$(Schema)].[$(Table)]')
	AND NOT
	(
		(TYPE_NAME(user_type_id) = 'VARCHAR' AND max_length = -1)
		OR (TYPE_NAME(user_type_id) = 'NVARCHAR' AND max_length = -1)
		OR (TYPE_NAME(user_type_id) = 'VARBINARY' AND max_length = -1)
		OR (TYPE_NAME(user_type_id) = 'GEOGRAPHY')
		OR (TYPE_NAME(user_type_id) = 'GEOMETRY')
		OR (TYPE_NAME(user_type_id) = 'XML')
		OR (TYPE_NAME(user_type_id) = 'IMAGE')
		OR (TYPE_NAME(user_type_id) = 'HIERARCHYID')
		OR (TYPE_NAME(user_type_id) = 'TIMESTAMP')
	)

-- If all columns are eligible, default to clustered columnstore index
DECLARE @SQL NVARCHAR(MAX) = ''
IF LEN(@ColumnList) = LEN(@EligibleColumnList)
BEGIN
	SET @SQL = 'CREATE CLUSTERED COLUMNSTORE INDEX [CCIX_$(Schema)_$(IndexSuffix)] ON [$(Schema)].[$(Table)] WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0)' 
	EXEC sp_executesql @SQL
END
-- If at least one column is eligible
ELSE IF LEN(@EligibleColumnList) > 0
BEGIN
	SET @SQL = 
		'CREATE NONCLUSTERED COLUMNSTORE INDEX [NCIX_$(Schema)_$(IndexSuffix)] ON [$(Schema)].[$(Table)] ('
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