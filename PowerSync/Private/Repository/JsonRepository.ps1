using module '.\Repository.ps1'

class JsonRepository : Repository {
    [string] $LogPath
    [string] $ConfigurationPath
    [System.Collections.ArrayList] $ActivityLog

    JsonRepository ([string] $LogPath, [string] $ConfigurationPath) {
        $this.LogPath = $LogPath
        $this.ConfigurationPath = $ConfigurationPath
        $this.ActivityLog = New-Object System.Collections.ArrayList
    }

    [hashtable] StartActivity([hashtable] $Parent, [string] $Name, [string] $Server, [string] $ScriptFile, [string] $ScriptAst, [string] $Status) {
        $o = @{
            ID = New-Guid
            ParentID = $Parent.ID
            Name = $Name
            Server = $Server
            ScriptFile = $ScriptFile
            Status = $Status
            ScriptAst = $ScriptAst
            StartDateTime = Get-Date
        }
        $this.ActivityLog.Add($o)
        return $o
    }
    
    [void] EndActivity([string] $ID) {
        $o = $this.ActivityLog.Where({$_.ID -eq $ID})[0]
        $o.EndDateTime = Get-Date
    }
}