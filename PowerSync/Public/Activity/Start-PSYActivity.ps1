function Start-PSYActivity {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [object] $ScriptBlock,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Parallel
    )

    try {
        # Log activity start. We also lock the scriptblock AST for reference purposes.  If multiple scriptblocks are
        # defined, just log the first one.
        $logScriptBlock = $ScriptBlock
        if ($ScriptBlock -is [array]) {
            $logScriptBlock = $ScriptBlock[0]
        }

        $a = Write-ActivityLog -ScriptBlock $logScriptBlock -Name $Name -Title "Activity '$Name' started" -Status 'Started'

        # Execute foreach (in parallel if specified)
        $job = ($ScriptBlock | Invoke-ForEach -ScriptBlock $ScriptBlock -Parallel:$Parallel -LogTitle "$Name[{0}]")
        
        # Log activity end
        Write-ActivityLog -ScriptBlock $ScriptBlock[0] -Name $Name -Title "Activity '$Name' completed" -Status 'Completed' -Activity $a
    }
    catch {
        Write-PSYErrorLog $_ "Error in Start-PSYActivity '$Name'."
    }
}