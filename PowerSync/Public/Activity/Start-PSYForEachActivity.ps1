function Start-PSYForEachActivity {
    param
    (
        [parameter(HelpMessage = "TODO", Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [object] $InputObject,
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [scriptblock] $ScriptBlock,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Parallel
    )

    try {
        # Log activity start
        $a = Write-ActivityLog $ScriptBlock $Name "Start-PSYForEachActivity Started" 'Started'

        # Execute foreach (in parallel if specified)
        $jobs = ($InputObject | Invoke-ForEach -ScriptBlock $ScriptBlock -Parallel:$Parallel -LogTitle "$Name[{0}]")
        
        # Log activity end
        Write-ActivityLog $ScriptBlock[0] $Name "Start-PSYForEachActivity Completed" 'Completed' $a
    }
    catch {
        Write-PSYExceptionLog $_ "Error in Start-PSYForEachActivity '$Name'."
    }
}