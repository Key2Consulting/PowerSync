Start-PSYActivity -Name 'Test CSV to SQL' -ScriptBlock {
    Export-PSYTextFile -Connection "SampleFiles" -Path "Sample100.csv" -Format CSV -Header `
    | Import-PSYSqlServer -Connection "TestDbSqlServer" -Table "dbo.Sample100" -Create

    Export-PSYTextFile -Connection "SampleFiles" -Path "Sample1000.csv" -Format CSV -Header `
    | Import-PSYSqlServer -Connection "TestDbSqlServer" -Table "dbo.Sample1000" -Create

    Export-PSYTextFile -Connection "SampleFiles" -Path "Sample10000.csv" -Format CSV -Header `
    | Import-PSYSqlServer -Connection "TestDbSqlServer" -Table "dbo.Sample10000" -Create -Compress -Consistent
}