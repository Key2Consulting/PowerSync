class JsonRepository : Repository {
    [string] $LogPath
    [string] $ConfigurationPath

    JsonRepository ([string] $LogPath, [string] $ConfigurationPath) {
        $this.LogPath = $LogPath
        $this.ConfigurationPath = $ConfigurationPath
    }

    [void] Initialize() {
        # Attempt to initialize from the existing log and configuration files. If it fails, it will be recreated on save.
        try {
            if ([System.IO.File]::Exists($this.LogPath)) {           
                $log = Get-Content -Path $this.LogPath | ConvertFrom-Json
                $this.ActivityLog = $log.ActivityLog
                $this.ExceptionLog = $log.ExceptionLog
                $this.InformationLog = $log.InformationLog
                $this.VariableLog = $log.VariableLog
            }
        }
        catch {
        }
    }

    [void] Save([object] $O) {

        # Save this item based on its type
        if ($O -is [ActivityLog]) {
            $this.ActivityLog.Add($o)
        }
        elseif ($O -is [ExceptionLog]) {
            $this.ExceptionLog.Add($o)
        }
        elseif ($O -is [InformationLog]) {
            $this.InformationLog.Add($o)
        }
        elseif ($O -is [VariableLog]) {
            $this.VariableLog.Add($o)
        }

        # Since you can't really update just part of a JSON file, we rewrite the entire thing.
        $log = @{
            ActivityLog = $this.ActivityLog
            ExceptionLog = $this.ExceptionLog
            InformationLog = $this.InformationLog
            VariableLog = $this.VariableLog
        }
        ConvertTo-Json $log | Set-Content -Path $this.LogPath
    }
}