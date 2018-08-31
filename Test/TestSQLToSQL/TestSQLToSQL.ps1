Start-PSYActivity -Name 'Test SQL to SQL' -ScriptBlock {
    Export-PSYSqlServer -Connection "SampleData" -ExtractQuery 'SELECT Geography FROM [dbo].[OddTypes]' `
    | Import-PSYSqlServer -Connection "TestDbSqlServer" -Table "dbo.OddTypes" -AutoCreate -AutoIndex
}