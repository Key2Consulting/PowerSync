Start-PSYActivity -Name 'Test Variables CRUD Operations' -ScriptBlock {
    Set-PSYVariable -Name 'UpdateVar' -Value 'World'
    Set-PSYVariable -Name 'UpdateVar' -Value 'World Again!'
    Set-PSYVariable -Name 'NumericVar' -Value 123.456
    Set-PSYVariable -Name 'ComplexVar' -Value @{Complex="object"; Field1=456}
    $updateVar = Get-PSYVariable -Name 'UpdateVar'
    $numericVar = Get-PSYVariable -Name 'NumericVar'
    $complexVar = Get-PSYVariable -Name 'ComplexVar'
    if ($updateVar -ne 'World Again!' -or $numericVar -ne 123.456 -or $complexVar.Complex -ne 'object') {
        throw "Retrieved variables are incorrect"
    }

    $allVars = Get-PSYVariable -Name '*Var' -Extended -Wildcards
    if ($allVars.Count -ne 3) {
        throw "Get variable with wildcards failed."
    }
    Remove-PSYVariable -Name 'UpdateVar'
    Remove-PSYVariable -Name 'NumericVar'
    Remove-PSYVariable -Name 'ComplexVar'
}

Start-PSYActivity -Name 'Test Variables Locking (Basic Test)' -ScriptBlock {
    Set-PSYVariable -Name 'LockVar' -Value 'Catch me if you can'
    Lock-PSYVariable -Name 'LockVar' -ScriptBlock {
        Write-PSYInformationLog 'Variable locked'
    }
}

Start-PSYActivity -Name 'Test Connections' -ScriptBlock {
    Set-PSYConnection -Name 'Source' -Provider MySql -ConnectionString 'a valid connectionstring'
    Set-PSYConnection -Name 'Target' -Provider OleDb -ConnectionString 'a valid connectionstring'
    Set-PSYConnection -Name 'Target' -Provider OleDb -ConnectionString 'an updated connectionstring' -Properties @{Whatever = "I;Want=ToSet"}
    $x = Get-PSYConnection -Name 'Source'
    $y = Get-PSYConnection -Name 'Target'
    if ($x.ConnectionString -ne 'a valid connectionstring' -or $y.Properties.Whatever -ne 'I;Want=ToSet' -or $y.Provider -ne [PSYDbConnectionProvider]::OleDb) {
        throw "Retrieved connection values are incorrect"
    }
    Remove-PSYConnection -Name 'Abc'
    Remove-PSYConnection -Name 'Hello'
}