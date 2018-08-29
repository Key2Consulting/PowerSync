Start-PSYActivity -Name 'Test Registry' -ScriptBlock {
    Set-PSYRegistry -Name 'Hello' -Value 'World'
    Set-PSYRegistry -Name 'Hello' -Value 'World Again!'
    Set-PSYRegistry -Name 'Abc' -Value 123
    $x = Get-PSYRegistry -Name 'Abc'
    $y = Get-PSYRegistry -Name 'Hello'
    if ($x -ne 123 -or $y -ne 'World Again!') {
        throw "Retrieved registry values are incorrect"
    }
    Remove-PSYRegistry -Name 'Abc'
    Remove-PSYRegistry -Name 'Hello'

    Start-PSYActivity -Name 'Test Registry' -ScriptBlock {
    }
}

Start-PSYActivity -Name 'Test Connections' -ScriptBlock {
    Set-PSYDbConnection -Name 'Source' -Provider MySql -ConnectionString 'a valid connectionstring'
    Set-PSYDbConnection -Name 'Target' -Provider OleDb -ConnectionString 'a valid connectionstring'
    Set-PSYDbConnection -Name 'Target' -Provider OleDb -ConnectionString 'an updated connectionstring' -AdditionalProperties 'Whatever=I;Want=ToSet'
    $x = Get-PSYConnection -Name 'Source'
    $y = Get-PSYConnection -Name 'Target'
    if ($x.ConnectionString -ne 'a valid connectionstring' -or $y.AdditionalProperties -ne 'Whatever=I;Want=ToSet' -or $y.Provider -ne [PSYDbConnectionProvider]::OleDb) {
        throw "Retrieved connection values are incorrect"
    }
    Remove-PSYConnection -Name 'Abc'
    Remove-PSYConnection -Name 'Hello'
}