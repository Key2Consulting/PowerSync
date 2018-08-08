:setvar TargetSchemaInfo "('ID', -1, 0, 0, 0, 1, 0, 'VARCHAR'),('Color', -1, 0, 0, 0, 1, 0, 'VARCHAR'),('Size', -1, 0, 0, 0, 1, 0, 'VARCHAR'),('InStock', -1, 0, 0, 0, 1, 0, 'VARCHAR'),('AvailableOnline', -1, 0, 0, 0, 1, 0, 'VARCHAR'),('Description', -1, 0, 0, 0, 1, 0, 'VARCHAR')"
:setvar TargetAutoCreate "1"
:setvar TargetSchema "dbo"
:setvar TargetTable "Test"
:setvar TargetLoadTable "Test12ABCDEFG12345"

-- If configured to automatically create the target table.
IF $(TargetAutoCreate) = 1
BEGIN
	DECLARE @SchemaInfo TABLE([Name] VARCHAR(128), [Size] INT, [Precision] INT, [Scale] INT, [IsKey] BIT, [IsNullable] BIT, [IsIdentity] BIT, [DataType] VARCHAR(50))
	INSERT INTO @SchemaInfo([Name], [Size], [Precision], [Scale], [IsKey], [IsNullable], [IsIdentity], [DataType])
	VALUES $(TargetSchemaInfo)

	DECLARE @SQL NVARCHAR(MAX)
	
	SELECT @SQL = COALESCE(@SQL + CHAR(13) + CHAR(10), '') + [Line]
	FROM
	(
		SELECT 
			'[' + [Name] + '] [' + [DataType] + '] '
			+ CASE 
				WHEN [DataType] LIKE '%CHAR%' AND [Size] = -1	THEN '(MAX) '
				WHEN [DataType] LIKE '%CHAR%'					THEN '(' + CAST([Size] AS VARCHAR(100)) + ') '
				WHEN [DataType] LIKE 'DECIMAL'					THEN '(' + CAST([Precision] AS VARCHAR(100)) + ', ' + CAST([Scale] AS VARCHAR(100)) + ') '
				ELSE ''
			END
			+ CASE
				WHEN [IsNullable] = 1							THEN 'NULL'
				WHEN [IsNullable] = 0							THEN 'NOT NULL'
			END 
			+ ',' [Line]
		FROM @SchemaInfo
	) q

	-- Remove any brackets from target table name
	SET @SQL = 'CREATE TABLE $(TargetSchema).$(TargetLoadTable)( ' + @SQL + ')'
	EXEC sp_executesql @SQL
END