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
        # Validation
        Confirm-PSYInitialized

        # Log activity start. We also lock the scriptblock AST for reference purposes.  If multiple scriptblocks are
        # defined, just log the first one.
        $logScriptBlock = $ScriptBlock
        if ($ScriptBlock -is [array]) {
            $logScriptBlock = $ScriptBlock[0]
        }

        $a = Write-ActivityLog $logScriptBlock $Name "Start-PSYActivity Started" 'Started'

        # Execute foreach (in parallel if specified)
        $job = ($ScriptBlock | Invoke-ForEach -ScriptBlock $ScriptBlock -Parallel:$Parallel -LogTitle "$Name[{0}]")
        
        # Log activity end
        Write-ActivityLog $ScriptBlock[0] $Name "Start-PSYActivity Completed" 'Completed' $a
    }
    catch {
        Write-PSYExceptionLog $_ "Error in Start-PSYActivity '$Name'."
    }
}