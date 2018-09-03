@{
    RootModule = "PowerSync.psm1"
    ModuleVersion = "1.1.0.0"
    GUID = "c2890ab0-8431-4abf-82cb-73f97b6aba9c"
    Author = "Dan Hardan, Matt Wollner, Jason Bacani"
    PowerShellVersion = "5.0"

    CmdletsToExport = "*"
    VariablesToExport = ""
    AliasesToExport = "*"
    
    # Use the following command to get the list of functions to export:  
    # Get-ChildItem '.\PowerSync\Public\' -File -Recurse | ForEach-Object { Write-Host "'$($_.BaseName)'," }
    FunctionsToExport = 
        'Get-PSYActivity',
        'Start-PSYActivity',
        'Start-PSYForEachActivity',
        'Stop-PSYActivity',
        'Invoke-PSYStoredCommand',
        'New-PSYStoredCommand',
        'ConvertFrom-PSYNativeType',
        'ConvertTo-PSYNativeType',
        'Import-PSYModule',
        'Get-PSYConnection',
        'Remove-PSYConnection',
        'Set-PSYConnection',
        'Export-PSYOleDb',
        'Export-PSYSqlServer',
        'Export-PSYTextFile',
        'Import-PSYOleDb',
        'Import-PSYSqlServer',
        'Import-PSYTextFile',
        'Get-PSYLog',
        'Write-PSYDebugLog',
        'Write-PSYErrorLog',
        'Write-PSYInformationLog',
        'Write-PSYQueryLog',
        'Write-PSYVariableLog',
        'Write-PSYVerboseLog',
        'Connect-PSYDbRepository',
        'Connect-PSYJsonRepository',
        'Disconnect-PSYRepository',
        'New-PSYJsonRepository',
        'Remove-PSYJsonRepository',
        'Get-PSYVariable',
        'Lock-PSYVariable',
        'Remove-PSYVariable',
        'Set-PSYVariable'

    NestedModules = @(
        "$PSScriptRoot\Public\Common\Enums.ps1",
        "$PSScriptRoot\Private\Common\Select-Coalesce.ps1",
        "$PSScriptRoot\Private\Common\Get-EnumName.ps1",        
        "$PSScriptRoot\Private\Common\ConvertTo-TargetSchemaTable.ps1",
        "$PSScriptRoot\Public\Common\ConvertTo-PSYNativeType.ps1",
        "$PSScriptRoot\Public\Common\ConvertFrom-PSYNativeType.ps1",
        "$PSScriptRoot\Private\Common\Copy-Object.ps1",
        "$PSScriptRoot\Private\Repository\Repository.ps1",
        "$PSScriptRoot\Private\Common\New-FactoryObject.ps1",
        "$PSScriptRoot\Private\Repository\FileRepository.ps1",
        "$PSScriptRoot\Private\Repository\JsonRepository.ps1",
        "$PSScriptRoot\Private\Repository\DbRepository.ps1",
        "$PSScriptRoot\Private\Common\Invoke-ForEach.ps1",
        "$PSScriptRoot\Private\Common\Write-ActivityLog.ps1",
        "$PSScriptRoot\Public\Common\Import-PSYModule.ps1",
        "$PSScriptRoot\Public\Activity\Start-PSYActivity.ps1",
        "$PSScriptRoot\Public\Activity\Start-PSYForEachActivity.ps1",
        "$PSScriptRoot\Public\Logging\Write-PSYErrorLog.ps1",
        "$PSScriptRoot\Public\Logging\Write-PSYInformationLog.ps1",
        "$PSScriptRoot\Public\Logging\Write-PSYVerboseLog.ps1",
        "$PSScriptRoot\Public\Logging\Write-PSYVariableLog.ps1",
        "$PSScriptRoot\Public\Logging\Write-PSYDebugLog.ps1",
        "$PSScriptRoot\Public\Logging\Get-PSYLog.ps1",
        "$PSScriptRoot\Public\Connection\Get-PSYConnection.ps1",
        "$PSScriptRoot\Public\Connection\Set-PSYConnection.ps1",
        "$PSScriptRoot\Public\Connection\Remove-PSYConnection.ps1",
        "$PSScriptRoot\Public\Command\New-PSYStoredCommand.ps1",
        "$PSScriptRoot\Public\Command\Invoke-PSYStoredCommand.ps1",
        "$PSScriptRoot\Public\Variable\Get-PSYVariable.ps1",
        "$PSScriptRoot\Public\Variable\Lock-PSYVariable.ps1",
        "$PSScriptRoot\Public\Variable\Remove-PSYVariable.ps1",
        "$PSScriptRoot\Public\Variable\Set-PSYVariable.ps1",
        "$PSScriptRoot\Public\Repository\Disconnect-PSYRepository.ps1",
        "$PSScriptRoot\Public\Repository\New-PSYJsonRepository.ps1",
        "$PSScriptRoot\Public\Repository\Connect-PSYJsonRepository.ps1",
        "$PSScriptRoot\Public\Repository\Remove-PSYJsonRepository.ps1",
        "$PSScriptRoot\Public\Repository\Connect-PSYDbRepository.ps1",
        "$PSScriptRoot\Public\Exporter\Export-PSYOleDb.ps1",
        "$PSScriptRoot\Public\Exporter\Export-PSYSqlServer.ps1",
        "$PSScriptRoot\Public\Exporter\Export-PSYTextFile.ps1",
        "$PSScriptRoot\Public\Importer\Import-PSYOleDb.ps1",
        "$PSScriptRoot\Public\Importer\Import-PSYSqlServer.ps1",
        "$PSScriptRoot\Public\Importer\Import-PSYTextFile.ps1"
    )
}