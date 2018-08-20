function Start-PSYMainActivity {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [scriptblock] $ConnectScriptBlock,
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [scriptblock] $ScriptBlock,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Name
    )

    [hashtable] $global:Ctx = @{
        System = @{
            Repository = $null                                          # reference to the connected repository
            ActivityStack = New-Object System.Collections.ArrayList     # all activity logs in stack formation
        }
        State = @{}
    }

    # First attempt to establish a connection to the repository
    try {
        # Try to connect
        $Ctx.System.Repository = Invoke-Command $ConnectScriptBlock
        $Ctx.System.Repository.Initialize()
    }
    catch {
        throw "Unable to connect to PowerSync repository with the ConnectionScriptBlock provided. $($_.Exception.Message)"
    }

    # Test the connection
    try {
        # TODO
    }
    catch {
        throw "Repository test failed. $($_.Exception.Message)"
    }

    # The main activity is really just another activity, with connect capability (above).
    try {
        Start-PSYActivity -Name 'Main Activity' -ScriptBlock $ScriptBlock
    }
    catch {
        throw "Unable to start main activity. $($_.Exception.Message)"
    }   
}