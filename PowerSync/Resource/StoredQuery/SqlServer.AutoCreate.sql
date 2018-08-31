:setvar SchemaTable ""
:setvar Table "dbo.Test"

DECLARE @SchemaTable TABLE([ColumnName] VARCHAR(128), [ColumnOrdinal] INT, [ColumnSize] INT, [DataType] VARCHAR(100), [AllowDBNull] BIT, [NumericPrecision] INT, [NumericScale] INT)
INSERT INTO @SchemaTable([ColumnName], [ColumnOrdinal], [ColumnSize], [DataType], [AllowDBNull], [NumericPrecision], [NumericScale])
VALUES $(SchemaTable)

DECLARE @SQL NVARCHAR(MAX)

-- Our source is SqlServer, so no need to map types. This ensures no data loss in type conversion.
SELECT @SQL = COALESCE(@SQL + CHAR(13) + CHAR(10), '') + [Line]
FROM
(
	SELECT
		'[' + [ColumnName] + '] [' + [DataType] + '] '
		+ CASE 
			WHEN [DataType] LIKE '%CHAR%' AND [Size] = -1	THEN '(MAX) '
			WHEN [DataType] LIKE '%CHAR%'					THEN '(' + CAST([ColumnSize] AS VARCHAR(100)) + ') '
			WHEN [DataType] LIKE 'DECIMAL'					THEN '(' + CAST([NumericPrecision] AS VARCHAR(100)) + ', ' + CAST([NumericScale] AS VARCHAR(100)) + ') '
			ELSE ''
		END`
		+ CASE
			WHEN [AllowDBNull] = 1							THEN 'NULL'
			WHEN [AllowDBNull] = 0							THEN 'NOT NULL'
		END 
		+ ',' [Line]
	FROM @SchemaTable
) q

-- Remove any brackets from target table name
SET @SQL = 'CREATE TABLE $(Table)( ' + @SQL + ')'
EXEC sp_executesql @SQL