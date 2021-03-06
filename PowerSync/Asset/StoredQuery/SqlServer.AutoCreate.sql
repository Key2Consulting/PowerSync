:setvar SchemaTable ""
:setvar Table "dbo.Test"

DECLARE @SchemaTable TABLE([ColumnName] VARCHAR(128), [ColumnOrdinal] INT, [ColumnSize] INT, [DataTypeName] VARCHAR(100), [AllowDBNull] BIT, [NumericPrecision] INT, [NumericScale] INT, [TransportDataTypeName] VARCHAR(100))
INSERT INTO @SchemaTable([ColumnName], [ColumnOrdinal], [ColumnSize], [DataTypeName], [AllowDBNull], [NumericPrecision], [NumericScale], [TransportDataTypeName])
VALUES $(SchemaTable)

DECLARE @SQL NVARCHAR(MAX)

-- Our source is SqlServer, so no need to map types. This ensures no data loss in type conversion.
SELECT @SQL = COALESCE(@SQL + CHAR(13) + CHAR(10), '') + [Line]
FROM
(
	SELECT
		'[' + [ColumnName] + '] [' + [DataTypeName] + '] '
		+ CASE 
			WHEN [DataTypeName] LIKE '%CHAR%' AND [ColumnSize] = -1	THEN '(MAX) '
			WHEN [DataTypeName] LIKE '%CHAR%'						THEN '(' + CAST([ColumnSize] AS VARCHAR(100)) + ') '
			WHEN [DataTypeName] LIKE 'DECIMAL'						THEN '(' + CAST([NumericPrecision] AS VARCHAR(100)) + ', ' + CAST([NumericScale] AS VARCHAR(100)) + ') '
			WHEN [DataTypeName] LIKE '%BINARY%'						THEN '(' + CAST([ColumnSize] AS VARCHAR(100)) + ') '
			WHEN [DataTypeName] LIKE '%DATETIME2%'					THEN '(' + CAST([NumericScale] AS VARCHAR(100)) + ') '
			ELSE ''
		END
		+ CASE
			WHEN [AllowDBNull] = 1									THEN 'NULL'
			WHEN [AllowDBNull] = 0									THEN 'NOT NULL'
		END 
		+ ',' [Line]
	FROM @SchemaTable
) q

-- Remove any brackets from target table name
SET @SQL = 'CREATE TABLE $(Table)( ' + @SQL + ')'
EXEC sp_executesql @SQL