# Text to MSSSQL
PowerSync-Text2MSSQL -Path "$rootPath\TestCSVToSQL\Sample100.csv" -Server $sqlServerInstance -Database $testDBPath -TableFQName 'dbo.TestShortcutCLI1' -NoHeader -NoAutoIndex
PowerSync-Text2MSSQL -Path "$rootPath\TestCSVToSQL\Sample100.csv" -Server $sqlServerInstance -Database $testDBPath -TableFQName 'dbo.TestShortcutCLI1' -Overwrite -NoAutoIndex

# MSSQL to MSSQL
PowerSync-MSSQL2MSSQL -SourceServer $sqlServerInstance -SourceDatabase $testDBPath -TargetServer $sqlServerInstance -TargetDatabase $testDBPath -ExtractQuery "SELECT * FROM dbo.TestShortcutCLI1" -TableFQName 'dbo.TestShortcutCLI2' -NoAutoIndex
PowerSync-MSSQL2MSSQL -SourceServer $sqlServerInstance -SourceDatabase $testDBPath -TargetServer $sqlServerInstance -TargetDatabase $testDBPath -ExtractQuery "SELECT * FROM dbo.TestShortcutCLI1" -TableFQName 'dbo.TestShortcutCLI2' -Overwrite -NoAutoIndex