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
        'Start-PSYActivity',
        'Start-PSYForEachActivity',
        'Invoke-PSYCmd',
        'Resolve-PSYCmd',
        'ConvertFrom-PSYCompatibleType',
        'ConvertTo-PSYCompatibleType',
        'Import-PSYModule',
        'Get-PSYConnection',
        'Remove-PSYConnection',
        'Set-PSYConnection',
        'Export-PSYOleDb',
        'Export-PSYSqlServer',
        'Export-PSYTextFile',
        'Export-PSYAzureBlobTextFile',
        'Import-PSYOleDb',
        'Import-PSYSqlServer',
        'Import-PSYTextFile',
        'Find-PSYLog',
        'Write-PSYDebugLog',
        'Write-PSYErrorLog',
        'Write-PSYInformationLog',
        'Write-PSYQueryLog',
        'Write-PSYVariableLog',
        'Write-PSYVerboseLog',
        'Write-PSYQueryLog',
        'Connect-PSYOleDbRepository',
        'Connect-PSYJsonRepository',
        'Disconnect-PSYRepository',
        'New-PSYJsonRepository',
        'Remove-PSYJsonRepository',
        'Get-PSYVariable',
        'Lock-PSYVariable',
        'Remove-PSYVariable',
        'Set-PSYVariable',
        'Copy-PSYTable'

    NestedModules = @(
        "$PSScriptRoot\Public\Common\Enums.ps1",
        "$PSScriptRoot\Private\Common\Select-Coalesce.ps1",
        "$PSScriptRoot\Private\Common\Get-EnumName.ps1",
        "$PSScriptRoot\Private\Common\ConvertTo-TargetSchemaTable.ps1",
        "$PSScriptRoot\Public\Common\ConvertTo-PSYCompatibleType.ps1",
        "$PSScriptRoot\Public\Common\ConvertFrom-PSYCompatibleType.ps1",
        "$PSScriptRoot\Private\Common\Select-PSYTablePart.ps1",
        "$PSScriptRoot\Private\Common\Copy-Object.ps1",
        "$PSScriptRoot\Private\Security\Protect-PSYText.ps1",
        "$PSScriptRoot\Private\Security\Unprotect-PSYText.ps1",
        "$PSScriptRoot\Private\Repository\Repository.ps1",
        "$PSScriptRoot\Private\Common\New-FactoryObject.ps1",
        "$PSScriptRoot\Private\Repository\FileRepository.ps1",
        "$PSScriptRoot\Private\Repository\JsonRepository.ps1",
        "$PSScriptRoot\Private\Repository\OleDbRepository.ps1",
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
        "$PSScriptRoot\Public\Logging\Write-PSYQueryLog.ps1",
        "$PSScriptRoot\Public\Logging\Find-PSYLog.ps1",
        "$PSScriptRoot\Public\Connection\Get-PSYConnection.ps1",
        "$PSScriptRoot\Public\Connection\Set-PSYConnection.ps1",
        "$PSScriptRoot\Public\Connection\Remove-PSYConnection.ps1",
        "$PSScriptRoot\Public\Command\Resolve-PSYCmd.ps1",
        "$PSScriptRoot\Public\Command\Invoke-PSYCmd.ps1",
        "$PSScriptRoot\Public\Variable\Get-PSYVariable.ps1",
        "$PSScriptRoot\Public\Variable\Lock-PSYVariable.ps1",
        "$PSScriptRoot\Public\Variable\Remove-PSYVariable.ps1",
        "$PSScriptRoot\Public\Variable\Set-PSYVariable.ps1",
        "$PSScriptRoot\Public\Repository\Disconnect-PSYRepository.ps1",
        "$PSScriptRoot\Public\Repository\New-PSYJsonRepository.ps1",
        "$PSScriptRoot\Public\Repository\Connect-PSYJsonRepository.ps1",
        "$PSScriptRoot\Public\Repository\Remove-PSYJsonRepository.ps1",
        "$PSScriptRoot\Public\Repository\Connect-PSYOleDbRepository.ps1",
        "$PSScriptRoot\Public\Exporter\Export-PSYOleDb.ps1",
        "$PSScriptRoot\Public\Exporter\Export-PSYSqlServer.ps1",
        "$PSScriptRoot\Public\Exporter\Export-PSYTextFile.ps1",
        "$PSScriptRoot\Public\Exporter\Export-PSYAzureBlobTextFile.ps1",
        "$PSScriptRoot\Public\Importer\Import-PSYOleDb.ps1",
        "$PSScriptRoot\Public\Importer\Import-PSYSqlServer.ps1",
        "$PSScriptRoot\Public\Importer\Import-PSYTextFile.ps1",
        "$PSScriptRoot\Public\QuickCommand\Copy-PSYTable.ps1"
        
    )
}