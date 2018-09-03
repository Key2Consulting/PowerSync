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
        $a = Write-ActivityLog -ScriptBlock $ScriptBlock -Name $Name -Title "ForEach Activity '$Name' started" -Status 'Started'

        # Execute foreach (in parallel if specified)
        $jobs = ($InputObject | Invoke-ForEach -ScriptBlock $ScriptBlock -Parallel:$Parallel -LogTitle "$Name[{0}]")
        
        # Log activity end
        Write-ActivityLog -ScriptBlock $ScriptBlock[0] -Name $Name -Title "ForEach Activity '$Name' completed" -Status 'Completed' -Activity $a
    }
    catch {
        Write-PSYErrorLog $_ "Error in Start-PSYForEachActivity '$Name'."
    }
}