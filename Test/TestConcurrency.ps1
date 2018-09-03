Start-PSYActivity -Name 'Test Concurrency' -ScriptBlock {
    
    Set-PSYVariable -Name 'TestVariable' -Value "Initial value"

    Start-PSYActivity -Name 'Test Parallel Race Execution' -Parallel -ScriptBlock ({
        Write-PSYInformationLog 'Parallel nested script 1 is executing'
        Set-PSYVariable -Name 'TestVariable' -Value "Concurrent update 1"
        Start-Sleep -Seconds 5
        if ((Get-PSYVariable 'TestVariable') -ne 'Concurrent update 3') { Write-PSYErrorLog -Message "Failed test 'Test Parallel Race Execution'"}
    }, {
        Write-PSYInformationLog 'Parallel nested script 2 is executing'
        Set-PSYVariable -Name 'TestVariable' -Value "Concurrent update 2"
        Start-Sleep -Seconds 3
        if ((Get-PSYVariable 'TestVariable') -ne 'Concurrent update 3') { Write-PSYErrorLog -Message "Failed test 'Test Parallel Race Execution'"}
    }, {
        Write-PSYInformationLog 'Parallel nested script 3 is executing'
        Set-PSYVariable -Name 'TestVariable' -Value "Concurrent update 3"
        Start-Sleep -Seconds 0
        Get-PSYVariable 'TestVariable'
        if ((Get-PSYVariable 'TestVariable') -ne 'Concurrent update 3') { Write-PSYErrorLog -Message "Failed test 'Test Parallel Race Execution'"}
    })

    Set-PSYVariable 'TestVariable' 0
    Start-PSYForEachActivity -Name 'Test ForEach Incorrect Concurrency Execution' -InputObject (1..10) -Parallel -ScriptBlock {
        Set-PSYVariable 'TestVariable' ((Get-PSYVariable 'TestVariable') + 1)     # will not work as expected
    }

    if ((Get-PSYVariable 'TestVariable') -eq 10) {
        Write-PSYErrorLog -Message "Failed test 'Test ForEach Incorrect Concurrency Execution'"      # the code above isn't synchronized, so TestVariable should never equal 10
    }

    Set-PSYVariable 'TestVariable' 0
    Start-PSYForEachActivity -Name 'Test ForEach Correct Concurrency Execution' -InputObject (1..10) -Parallel -ScriptBlock {
        Lock-PSYVariable 'TestVariable' {
            Set-PSYVariable 'TestVariable' ((Get-PSYVariable 'TestVariable') + 1)     # will work as expected since we're locking the variable prior to updating it
        }
    }
    if ((Get-PSYVariable 'TestVariable') -ne 10) {
        Write-PSYErrorLog -Message "Failed test 'Test ForEach Correct Concurrency Execution'"
    }

    Remove-PSYVariable 'TestVariable'
}