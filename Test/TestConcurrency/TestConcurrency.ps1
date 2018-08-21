Start-PSYMainActivity -PrintVerbose -DisableParallel -ConnectScriptBlock {
    #Connect-PSYOleDbRepository -ConnectionString "Server=(LocalDb)\MSSQLLocalDB;Integrated Security=true;Database=SqlServerKit"
    Connect-PSYJsonRepository
} -Name 'TestConcurrency' -ScriptBlock {
    
    Set-PSYState 'TestVariable' "Initial value"

    Start-PSYParallelActivity -Name 'Test Parallel Delayed Execution' -ScriptBlock ({
        Write-PSYInformationLog 'Parallel nested script 1 is executing'
        Set-PSYState 'TestVariable' "Concurrent update 1"
        Start-Sleep -Seconds 3
        if ((Get-PSYState 'TestVariable') -ne 'Concurrent update 3') { throw "TestConcurrency failed."}
    }, {
        Write-PSYInformationLog 'Parallel nested script 2 is executing'
        Set-PSYState 'TestVariable' "Concurrent update 2"
        Start-Sleep -Seconds 2
        if ((Get-PSYState 'TestVariable') -ne 'Concurrent update 3') { throw "TestConcurrency failed."}
    }, {
        Write-PSYInformationLog 'Parallel nested script 3 is executing'
        Set-PSYState 'TestVariable' "Concurrent update 3"
        Start-Sleep -Seconds 1
        if ((Get-PSYState 'TestVariable') -ne 'Concurrent update 3') { throw "TestConcurrency failed."}
    })

    Remove-PSYState 'TestVariable'
}