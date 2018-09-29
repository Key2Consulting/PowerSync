Start-PSYActivity -Name 'Test Concurrency' -ScriptBlock {

<#     Set-PSYVariable -Name 'TestVariable' -Value "Initial value"
    (
        (Start-PSYActivity -Name 'Test Async Race Execution 1' -Async -ScriptBlock {
            Write-PSYInformationLog 'Async scriptblock 1 is executing'
            Set-PSYVariable -Name 'TestVariable' -Value "Concurrent update 1"
            Start-Sleep -Seconds 5
            if ((Get-PSYVariable 'TestVariable') -ne 'Concurrent update 3') { throw "Failed test 'Test Async Race Execution'"}
        }), 
        (Start-PSYActivity -Name 'Test Parallel Race Execution 2' -Async -ScriptBlock {
            Write-PSYInformationLog 'Async scriptblock 2 is executing'
            Set-PSYVariable -Name 'TestVariable' -Value "Concurrent update 2"
            Start-Sleep -Seconds 3
            if ((Get-PSYVariable 'TestVariable') -ne 'Concurrent update 3') { throw "Failed test 'Test Async Race Execution'"}
        }),
        (Start-PSYActivity -Name 'Test Async Race Execution 3' -Async -ScriptBlock {
            Write-PSYInformationLog 'Async scriptblock 3 is executing'
            Set-PSYVariable -Name 'TestVariable' -Value "Concurrent update 3"
            Start-Sleep -Seconds 0
            Get-PSYVariable 'TestVariable'
            if ((Get-PSYVariable 'TestVariable') -ne 'Concurrent update 3') { throw "Failed test 'Test Async Race Execution'"}
        })
    ) | Wait-PSYActivity

    Set-PSYVariable 'TestVariable' 0
    (1..10) | Start-PSYForEachActivity -Name 'Test ForEach Incorrect Concurrency Execution' -Parallel -Throttle 5 -ScriptBlock {
        Set-PSYVariable 'TestVariable' ((Get-PSYVariable 'TestVariable') + 1)     # will not work as expected
    }
    if ((Get-PSYVariable 'TestVariable') -eq 10) {
        throw "Failed test 'Test ForEach Incorrect Concurrency Execution'"      # the code above isn't synchronized, so TestVariable should never equal 10
    }

    Set-PSYVariable 'TestVariable' 0
    (1..10) | Start-PSYForEachActivity -Name 'Test ForEach Correct Concurrency Execution' -Parallel -Throttle 5 -ScriptBlock {
        Lock-PSYVariable 'TestVariable' {
            Set-PSYVariable 'TestVariable' ((Get-PSYVariable 'TestVariable') + 1)     # will work as expected since we're locking the variable prior to updating it
        }
    }
    if ((Get-PSYVariable 'TestVariable') -ne 10) {
        throw "Failed test 'Test ForEach Correct Concurrency Execution'"
    }
 #>
    Start-PSYActivity -Name 'Test Queued Execution' -ScriptBlock {
        
        # Simulate a remote activity execution by self-hosting the receiver. Normally this would be done by a remote process.
        $receiver = Start-PSYActivity -Name 'Self-Hosted Receiver' -Async -ScriptBlock {
            Receive-PSYQueuedActivity -Queue 'Outgoing' -Continous
        }

      <#   $activities = (
            (Start-PSYActivity -Name 'Test Queued Activity Execution 1' -InputObject "input 1" -Async -Queue 'Outgoing' -ScriptBlock {
                Start-Sleep -Seconds 5
                Set-PSYVariable -Name 'TestVariable' -Value "...$Input..."
                Write-PSYInformationLog (Get-PSYVariable -Name 'TestVariable')
                "Hello 1"
            }),
            (Start-PSYActivity -Name 'Test Queued Activity Execution 2' -InputObject "input 2" -Async -Queue 'Outgoing' -ScriptBlock {
                Start-Sleep -Seconds 3
                Set-PSYVariable -Name 'TestVariable' -Value "...$Input..."
                Write-PSYInformationLog (Get-PSYVariable -Name 'TestVariable')
                "Hello 2"
            }),
            (Start-PSYActivity -Name 'Test Queued Activity Execution 3' -InputObject "input 3" -Async -Queue 'Outgoing' -ScriptBlock {
                Start-Sleep -Seconds 0
                Set-PSYVariable -Name 'TestVariable' -Value "...$Input..."
                Write-PSYInformationLog (Get-PSYVariable -Name 'TestVariable')
                "Hello 3"
            })
        )
        # Wait until all activities are complete.
        $activities | Wait-PSYActivity
        
        # Output
        $activities | ForEach-Object { Write-PSYInformationLog $_.OutputObject }
 #>
        # Queued ForEach
        Start-PSYActivity -Name "Queue ForEach" -ScriptBlock {
            (1..10) | Start-PSYForEachActivity -Name 'Test ForEach Queued Execution' -Queue 'Outgoing' -ScriptBlock {
                Write-PSYInformationLog -Message "...$Input..."
            }
        }

        # Terminate our self-hosted receiver
        Stop-PSYActivity $receiver
    }

    Remove-PSYVariable 'TestVariable'
}