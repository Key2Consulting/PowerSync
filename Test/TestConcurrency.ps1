Start-PSYActivity -Name 'Test Concurrency' -ScriptBlock {

    "Sequential Activity" | Start-PSYActivity -Name 'Test Simple Sequential Execution' -ScriptBlock {
        "...$($_)..."
    }

    (1..10) | Start-PSYActivity -Name 'Test Simple ForEach Sequential Execution' -ScriptBlock {
        "...$($_)..."
    }

    Set-PSYVariable -Name 'TestVariable' -Value "Initial value"
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
    (1..10) | Start-PSYActivity -Name 'Test ForEach Incorrect Concurrency Execution' -Parallel -Throttle 5 -ScriptBlock {
        [int] $x = (Get-PSYVariable 'TestVariable') + 1
        Start-Sleep -Milliseconds (Get-Random -Minimum 0 -Maximum 1000)
        Set-PSYVariable 'TestVariable' $x      # will not work as expected
    }
    if ((Get-PSYVariable 'TestVariable') -eq 10) {
        throw "Failed test 'Test ForEach Incorrect Concurrency Execution'"      # the code above isn't synchronized, so TestVariable should never equal 10
    }

    Set-PSYVariable 'TestVariable' 0
    (1..10) | Start-PSYActivity -Name 'Test ForEach Correct Concurrency Execution' -Parallel -Throttle 5 -ScriptBlock {
        Lock-PSYVariable -Name 'TestVariable' {
            [int] $x = (Get-PSYVariable 'TestVariable') + 1
            Start-Sleep -Milliseconds (Get-Random -Minimum 0 -Maximum 1000)
            Set-PSYVariable 'TestVariable' $x     # will work as expected since we're locking the variable prior to updating it
        }
    }
    if ((Get-PSYVariable 'TestVariable') -ne 10) {
        throw "Failed test 'Test ForEach Correct Concurrency Execution'"
    }
 
    Start-PSYActivity -Name 'Test Queued Execution' -ScriptBlock {

        # Simulate a remote activity execution by self-hosting the receiver. Normally this would be done by a remote process.
        $receiver = Start-PSYActivity -Name 'Self-Hosted Receiver' -Async -ScriptBlock {
            Receive-PSYQueuedActivity -Queue 'Outgoing' -Continous
        }

      $activities = (
            ("input 1" | Start-PSYActivity -Name 'Test Queued Activity Execution 1' -Async -Queue 'Outgoing' -ScriptBlock {
                Start-Sleep -Seconds 5
                Set-PSYVariable -Name 'TestVariable' -Value "...$($_)..."
                Write-PSYInformationLog (Get-PSYVariable -Name 'TestVariable')
                "Hello 1"
            }),
            ("input 2" | Start-PSYActivity -Name 'Test Queued Activity Execution 2' -Async -Queue 'Outgoing' -ScriptBlock {
                Start-Sleep -Seconds 3
                Set-PSYVariable -Name 'TestVariable' -Value "...$($_)..."
                Write-PSYInformationLog (Get-PSYVariable -Name 'TestVariable')
                "Hello 2"
            }),
            ("input 3" | Start-PSYActivity -Name 'Test Queued Activity Execution 3' -Async -Queue 'Outgoing' -ScriptBlock {
                Start-Sleep -Seconds 0
                Set-PSYVariable -Name 'TestVariable' -Value "...$($_)..."
                Write-PSYInformationLog (Get-PSYVariable -Name 'TestVariable')
                "Hello 3"
            })
        )

        # Wait until all activities are complete.
        $activities | Wait-PSYActivity
        
        # Output
        $activities | ForEach-Object { Write-PSYInformationLog $_.OutputObject }
 
        # Queued ForEach
        Start-PSYActivity -Name "Queue ForEach" -ScriptBlock {
            (1..10) | Start-PSYActivity -Name 'Test ForEach Queued Execution' -Queue 'Outgoing' -ScriptBlock {
                Write-PSYInformationLog -Message "...$($_)..."
            }
        }

        # Terminate our self-hosted receiver
        Stop-PSYActivity $receiver
    }

    Remove-PSYVariable 'TestVariable'
}