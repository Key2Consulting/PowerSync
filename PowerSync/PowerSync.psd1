@{
    ModuleVersion = "1.1.0.0"
    GUID = 'c2890ab0-8431-4abf-82cb-73f97b6aba9c'
    Author = 'Dan Hardan'
    PowerShellVersion = "5.0"
    
    FunctionsToExport = '*'
    CmdletsToExport = '*'
    VariablesToExport = ''
    AliasesToExport = '*'

    NestedModules = @(
        '.\PowerSync\Private\Library\Invoke-Parallel\Invoke-Parallel.ps1',
        '.\PowerSync\Private\Library\PoshRSJob\PoshRSJob.psm1',
        '.\PowerSync\Private\Repository\Repository.ps1',
        '.\PowerSync\Private\Repository\FileRepository.ps1',
        '.\PowerSync\Private\Repository\JsonRepository.ps1',
        '.\PowerSync\Private\Common\Core.ps1',
        '.\PowerSync\Private\Common\Write-ActivityLog.ps1',
        '.\PowerSync\Public\Activity\Start-PSYActivity.ps1',
        '.\PowerSync\Public\Activity\Start-PSYForEachActivity.ps1',
        '.\PowerSync\Public\Activity\Start-PSYMainActivity.ps1'
        '.\PowerSync\Public\Logging\Write-PSYExceptionLog.ps1',
        '.\PowerSync\Public\Logging\Write-PSYInformationLog.ps1',
        '.\PowerSync\Public\Logging\Write-PSYVariableLog.ps1',
        '.\PowerSync\Public\State\Get-PSYState.ps1',
        '.\PowerSync\Public\State\Lock-PSYState.ps1',
        '.\PowerSync\Public\State\Remove-PSYState.ps1',
        '.\PowerSync\Public\State\Set-PSYState.ps1',
        '.\PowerSync\Public\Repository\Connect-PSYJsonRepository.ps1',
        '.\PowerSync\Public\Repository\Connect-PSYOleDbRepository.ps1'
    )
}