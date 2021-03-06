Start-PSYActivity -Name 'Test SQL to SQL' -ScriptBlock {

    Start-PSYActivity -Name 'Test Import Options' -ScriptBlock {
        Export-PSYSqlServer -Connection "TestSqlServerSource" -Table "sys.columns" `
        | Import-PSYSqlServer -Connection "TestSqlServerTarget" -Table "dbo.ImportOptions" -Create -Index

        Export-PSYSqlServer -Connection "TestSqlServerSource" -Table "sys.columns" `
        | Import-PSYSqlServer -Connection "TestSqlServerTarget" -Table "dbo.ImportOptions" -Create -Index -Overwrite -Consistent

        Export-PSYSqlServer -Connection "TestSqlServerSource" -Table "sys.columns" `
        | Import-PSYSqlServer -Connection "TestSqlServerTarget" -Table "dbo.ImportOptions" -Create -Index -Consistent
    }

    Start-PSYActivity -Name 'Test Odd Types' -ScriptBlock {
        Export-PSYSqlServer -Connection "TestSqlServerSource" -Table "dbo.OddTypes" `
        | Import-PSYSqlServer -Connection "TestSqlServerTarget" -Table "dbo.OddTypes" -Create -Index
    }

    Start-PSYActivity -Name 'Large Types' -ScriptBlock {
        Export-PSYSqlServer -Connection "TestSqlServerSource" -ExtractQuery "SELECT TOP 10 object_id, REPLICATE(CAST('Hello World' AS VARCHAR(MAX)), 20000) LargeText FROM sys.objects" `
        | Import-PSYSqlServer -Connection "TestSqlServerTarget" -Table "dbo.LargeTypes" -Create -Index -Compress
    }

    Start-PSYActivity -Name 'Big Table' -ScriptBlock {
        Export-PSYSqlServer -Connection "TestSqlServerSource" -ExtractQuery "SELECT A.* FROM sys.columns A CROSS APPLY sys.columns B" `
        | Import-PSYSqlServer -Connection "TestSqlServerTarget" -Table "dbo.BigTable" -Create -Compress -Index
    }

    Start-PSYActivity -Name 'Big Table Type Conversion' -ScriptBlock {
        Export-PSYSqlServer -Connection "TestSqlServerSource" -ExtractQuery "SELECT A.*, geography::Point(47.65100, -122.34900, 4326) ForceConversion FROM sys.columns A CROSS APPLY sys.columns B" `
        | Import-PSYSqlServer -Connection "TestSqlServerTarget" -Table "dbo.BigTableTypeConversion" -Create
    }    
}