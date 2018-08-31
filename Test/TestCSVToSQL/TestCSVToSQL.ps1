Start-PSYActivity -Name 'Test CSV to SQL' -ScriptBlock {
    Export-PSYTextFile -Connection "SampleFiles" -Path "Sample100.csv" -Format CSV -Header `
    | Import-PSYSqlServer -Connection "TestDbSqlServer" -Table "dbo.Sample100" -AutoCreate -AutoIndex

    Export-PSYSqlServer -Connection "TestDbSqlServer" -ExtractQuery (Resolve-PSYStoredCommand -Name 'GetData' -Parameters @('Foo')) `
    | Import-PSYSqlServer -Connection "TestDbSqlServer" -Table "dbo.Sample100" -AutoCreate -AutoIndex

    Export-PSYSqlServer -Connection "TestDbSqlServer" -ExtractStoredQuery 'GetData' -Parameters @('Foo') `
    | Import-PSYSqlServer -Connection "TestDbSqlServer" -Table "dbo.Sample100" -AutoCreate -AutoIndex
}