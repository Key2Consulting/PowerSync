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
        $scriptAst = $ScriptBlock | ForEach-Object { $_.Ast.ToString() }
        $scriptAst = '[' + ($scriptAst -join ',') + ']'
        
        $a = Write-ActivityLog -ScriptAst $scriptAst -Name $Name -Message "Activity '$Name' started" -Status 'Started'
        $parentActivity = if ($ScriptBlock -is [array]) {$a} else {$null}       # only log a child activity if an array of scriptblocks need processing

        # Execute foreach (in parallel if specified)
        $job = ($ScriptBlock | Invoke-ForEach -ScriptBlock $ScriptBlock -Parallel:$Parallel -Name "$Name[{0}]" -ParentActivity $parentActivity)
        
        # Log activity end
        Write-ActivityLog -Name $Name -Message "Activity '$Name' completed" -Status 'Completed' -Activity $a
    }
    catch {
        Write-PSYErrorLog $_ "Error in Start-PSYActivity '$Name'."
    }
}