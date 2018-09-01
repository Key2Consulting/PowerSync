Start-PSYActivity -Name 'Test Concurrency' -ScriptBlock {
    
    Set-PSYStateVar 'TestVariable' "Initial value"

    Start-PSYActivity -Name 'Test Parallel Race Execution' -Parallel -ScriptBlock ({
        Write-PSYInformationLog 'Parallel nested script 1 is executing'
        Set-PSYStateVar 'TestVariable' "Concurrent update 1"
        Start-Sleep -Seconds 5
        Get-PSYStateVar 'TestVariable'
        if ((Get-PSYStateVar 'TestVariable') -ne 'Concurrent update 3') { Write-PSYExceptionLog -Message "Failed test 'Test Parallel Race Execution'"}
    }, {
        Write-PSYInformationLog 'Parallel nested script 2 is executing'
        Set-PSYStateVar 'TestVariable' "Concurrent update 2"
        Start-Sleep -Seconds 3
        Get-PSYStateVar 'TestVariable'
        if ((Get-PSYStateVar 'TestVariable') -ne 'Concurrent update 3') { Write-PSYExceptionLog -Message "Failed test 'Test Parallel Race Execution'"}
    }, {
        Write-PSYInformationLog 'Parallel nested script 3 is executing'
        Set-PSYStateVar 'TestVariable' "Concurrent update 3"
        Start-Sleep -Seconds 0
        Get-PSYStateVar 'TestVariable'
        if ((Get-PSYStateVar 'TestVariable') -ne 'Concurrent update 3') { Write-PSYExceptionLog -Message "Failed test 'Test Parallel Race Execution'"}
    })

    Set-PSYStateVar 'TestVariable' 0
    Start-PSYForEachActivity -Name 'Test ForEach Incorrect Concurrency Execution' -InputObject (1..10) -Parallel -ScriptBlock {
        Set-PSYStateVar 'TestVariable' ((Get-PSYStateVar 'TestVariable') + 1)     # will not work as expected
    }

    if ((Get-PSYStateVar 'TestVariable') -eq 10) {
        Write-PSYExceptionLog -Message "Failed test 'Test ForEach Incorrect Concurrency Execution'"      # the code above isn't synchronized, so TestVariable should never equal 10
    }

    Set-PSYStateVar 'TestVariable' 0
    Start-PSYForEachActivity -Name 'Test ForEach Correct Concurrency Execution' -InputObject (1..10) -Parallel -ScriptBlock {
        Lock-PSYStateVar 'TestVariable' {
            Set-PSYStateVar 'TestVariable' ((Get-PSYStateVar 'TestVariable') + 1)     # will work as expected since we're locking the variable
        }
    }
    if ((Get-PSYStateVar 'TestVariable') -ne 10) {
        Write-PSYExceptionLog -Message "Failed test 'Test ForEach Correct Concurrency Execution'"
    }

    Remove-PSYStateVar 'TestVariable'
}