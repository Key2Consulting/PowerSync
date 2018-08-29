function Invoke-PSYDbCommand {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Connection,
        [Parameter(HelpMessage = "TODO", Mandatory = $false, ParameterSetName='Command')]
        [string] $Command,
        [Parameter(HelpMessage = "TODO", Mandatory = $false, ParameterSetName='StoredCommand')]
        [string] $StoredCommand,
        [Parameter(HelpMessage = "TODO", Mandatory = $false, ParameterSetName='StoredCommand')]
        [object] $Parameters
    )
}