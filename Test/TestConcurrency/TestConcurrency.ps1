Start-PSYMainActivity -Verbose -ConnectScriptBlock {
    Connect-PSYJsonRepository
} -Name 'Test Concurrency' -ScriptBlock {
    
    Set-PSYState 'TestVariable' "Initial value"

    Start-PSYActivity -Name 'Test Parallel Race Execution' -Parallel -ScriptBlock ({
        Write-PSYInformationLog 'Parallel nested script 1 is executing'
        Set-PSYState 'TestVariable' "Concurrent update 1"
        Start-Sleep -Milliseconds 1000
        if ((Get-PSYState 'TestVariable') -ne 'Concurrent update 3') { Write-PSYExceptionLog -Message "Failed test 'Test Parallel Race Execution'"}
    }, {
        Write-PSYInformationLog 'Parallel nested script 2 is executing'
        Set-PSYState 'TestVariable' "Concurrent update 2"
        Start-Sleep -Milliseconds 500
        if ((Get-PSYState 'TestVariable') -ne 'Concurrent update 3') { Write-PSYExceptionLog -Message "Failed test 'Test Parallel Race Execution'"}
    }, {
        Write-PSYInformationLog 'Parallel nested script 3 is executing'
        Set-PSYState 'TestVariable' "Concurrent update 3"
        Start-Sleep -Milliseconds 0
        if ((Get-PSYState 'TestVariable') -ne 'Concurrent update 3') { Write-PSYExceptionLog -Message "Failed test 'Test Parallel Race Execution'"}
    })

    Set-PSYState 'TestVariable' 0
    Start-PSYForEachActivity -Name 'Test ForEach Incorrect Concurrency Execution' -InputObject (1..10) -Parallel -ScriptBlock {
        Set-PSYState 'TestVariable' ((Get-PSYState 'TestVariable') + 1)     # will not work as expected
    }

    if ((Get-PSYState 'TestVariable') -eq 10) {
        Write-PSYExceptionLog -Message "Failed test 'Test ForEach Incorrect Concurrency Execution'"      # the code above isn't synchronized, so TestVariable should never equal 10
    }

    Set-PSYState 'TestVariable' 0
    Start-PSYForEachActivity -Name 'Test ForEach Correct Concurrency Execution' -InputObject (1..10) -Parallel -ScriptBlock {
        Lock-PSYState 'TestVariable' {
            Set-PSYState 'TestVariable' ((Get-PSYState 'TestVariable') + 1)     # will work as expected since we're locking the variable
        }
    }
    if ((Get-PSYState 'TestVariable') -ne 10) {
        Write-PSYExceptionLog -Message "Failed test 'Test ForEach Correct Concurrency Execution'"
    }

    Remove-PSYState 'TestVariable'
}