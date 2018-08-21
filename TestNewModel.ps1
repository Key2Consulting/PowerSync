Remove-Item 'Log.json' -ErrorAction SilentlyContinue
Remove-Item 'Configuration.json' -ErrorAction SilentlyContinue
Import-Module "$(Resolve-Path -Path ".\PowerSync")"

Start-PSYMainActivity -ConnectScriptBlock {
    #Connect-PSYOleDbRepository -ConnectionString "Server=(LocalDb)\MSSQLLocalDB;Integrated Security=true;Database=SqlServerKit"
    Connect-PSYJsonRepository
} -ScriptBlock {

    Write-PSYInformationLog 'Main script is executing'

    Set-PSYState 'Control' "Initial value"
    Set-PSYState 'Control' "First update"

    Write-PSYInformationLog "Control State is $(Get-PSYState 'Control')"

    Start-PSYActivity -Name 'Nested A' -ScriptBlock {
        Write-PSYInformationLog 'Nested script A is executing'
        $s = Get-PSYState 'Control'
        Set-PSYState 'Control' "Second update"
        Write-PSYInformationLog "Control State is $(Get-PSYState 'Control')"
        Start-PSYParallelActivity -Name 'Nested B' -ScriptBlock ({
            Write-PSYInformationLog 'Parallel nested script 1 is executing'
            Set-PSYState 'Control' "Concurrent update 1"
            Start-Sleep -Seconds 3
            Write-PSYInformationLog "Control State is $(Get-PSYState 'Control')"
        }, {
            Write-PSYInformationLog 'Parallel nested script 2 is executing'
            Set-PSYState 'Control' "Concurrent update 2"
            Start-Sleep -Seconds 2
            Write-PSYInformationLog "Control State is $(Get-PSYState 'Control')"
        }, {
            Write-PSYInformationLog 'Parallel nested script 3 is executing'
            Set-PSYState 'Control' "Concurrent update 3"
            Start-Sleep -Seconds 1
            Write-PSYInformationLog "Control State is $(Get-PSYState 'Control')"
        })
    }

    Remove-PSYState 'Control'
}