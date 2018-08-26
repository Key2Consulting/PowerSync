@{
    RootModule = "PowerSync.psm1"
    ModuleVersion = "1.1.0.0"
    GUID = "c2890ab0-8431-4abf-82cb-73f97b6aba9c"
    Author = "Dan Hardan"
    PowerShellVersion = "5.0"
    
    FunctionsToExport = "*"
    CmdletsToExport = "*"
    VariablesToExport = ""
    AliasesToExport = "*"

    NestedModules = @(
        "$PSScriptRoot\Private\Common\Copy-Object.ps1",
        "$PSScriptRoot\Private\Repository\Repository.ps1",
        "$PSScriptRoot\Private\Repository\FileRepository.ps1",
        "$PSScriptRoot\Private\Repository\JsonRepository.ps1",
        "$PSScriptRoot\Private\Common\Confirm-PSYInitialized.ps1",
        "$PSScriptRoot\Private\Common\Invoke-ForEach.ps1",
        "$PSScriptRoot\Private\Common\Write-ActivityLog.ps1",
        "$PSScriptRoot\Public\System\Enums.ps1",
        "$PSScriptRoot\Public\System\Import-PSYModule.ps1",
        "$PSScriptRoot\Public\Activity\Start-PSYActivity.ps1",
        "$PSScriptRoot\Public\Activity\Start-PSYForEachActivity.ps1",
        "$PSScriptRoot\Public\Logging\Write-PSYExceptionLog.ps1",
        "$PSScriptRoot\Public\Logging\Write-PSYInformationLog.ps1",
        "$PSScriptRoot\Public\Logging\Write-PSYVerboseLog.ps1",
        "$PSScriptRoot\Public\Logging\Write-PSYVariableLog.ps1",
        "$PSScriptRoot\Public\Logging\Write-PSYDebugLog.ps1",
        "$PSScriptRoot\Public\Logging\Get-PSYLog.ps1",
        "$PSScriptRoot\Public\State\Get-PSYStateVar.ps1",
        "$PSScriptRoot\Public\State\Lock-PSYStateVar.ps1",
        "$PSScriptRoot\Public\State\Remove-PSYStateVar.ps1",
        "$PSScriptRoot\Public\State\Set-PSYStateVar.ps1",
        "$PSScriptRoot\Public\Repository\Disconnect-PSYRepository.ps1",
        "$PSScriptRoot\Public\Repository\New-PSYJsonRepository.ps1",
        "$PSScriptRoot\Public\Repository\Connect-PSYJsonRepository.ps1",
        "$PSScriptRoot\Public\Repository\Remove-PSYJsonRepository.ps1",
        "$PSScriptRoot\Public\Repository\Connect-PSYOleDbRepository.ps1"
    )
}