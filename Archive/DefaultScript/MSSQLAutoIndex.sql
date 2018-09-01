:setvar TargetSchema "dbo"
:setvar TargetTable "CSVToSSQLTest12"
:setvar TargetLoadTable "CSVToSSQLTest12ABCDEFG12345"

-- Detect if the table has any columns that can or cannot participate in a columnstore index
DECLARE @ColumnList VARCHAR(MAX)
SELECT @ColumnList = COALESCE(@ColumnList + ',', '') + '[' + [Name] + ']'
FROM sys.columns
WHERE
	object_id = OBJECT_ID('$(TargetSchema).$(TargetLoadTable)')
SELECT @ColumnList

DECLARE @EligibleColumnList VARCHAR(MAX)
SELECT @EligibleColumnList = COALESCE(@EligibleColumnList + ',', '') + '[' + [Name] + ']'
FROM sys.columns
WHERE
	object_id = OBJECT_ID('$(TargetSchema).$(TargetLoadTable)')
	AND NOT
	(
		(TYPE_NAME(user_type_id) = 'VARCHAR' AND max_length = -1)
		OR (TYPE_NAME(user_type_id) = 'NVARCHAR' AND max_length = -1)
		OR (TYPE_NAME(user_type_id) = 'VARBINARY' AND max_length = -1)
	)

-- If all columns are eligible, default to clustered columnstore index
IF LEN(@ColumnList) = LEN(@EligibleColumnList)
BEGIN
	CREATE CLUSTERED COLUMNSTORE INDEX [CCIX_$(TargetSchema)_$(TargetTable)] ON $(TargetSchema).$(TargetLoadTable) WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0)
END
-- If at least one column is eligible
ELSE IF LEN(@EligibleColumnList) > 0
BEGIN
	DECLARE @SQL NVARCHAR(MAX) = 
		'CREATE NONCLUSTERED COLUMNSTORE INDEX [CIX_$(TargetSchema)_' + REPLACE(REPLACE('$(TargetTable)', '[', ''), ']', '') + '] ON $(TargetSchema).$(TargetLoadTable) (' 
		+ @EligibleColumnList 
		+ ')WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0)'
	EXEC sp_executesql @SQL
END
ELSE
-- Otherwise, leave as heap
BEGIN
	PRINT 'Automatic index not possible due to incompatible data types.';
	THROW 51000, 'Automatic index not possible due to incompatible data types.', 1;
END