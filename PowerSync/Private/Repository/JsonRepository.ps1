class JsonRepository : FileRepository {
    [string] $LogPath
    [string] $ConfigurationPath

    JsonRepository ([string] $LogPath, [string] $ConfigurationPath) {
        $this.LogPath = $LogPath
        $this.ConfigurationPath = $ConfigurationPath
    }

    [void] LoadRepository() {
        # Attempt to initialize from the existing log and configuration files. If it fails, it will be recreated on save.
        try {
            if ([System.IO.File]::Exists($this.LogPath)) {
                $log = Get-Content -Path $this.LogPath | ConvertFrom-Json
                $this.ActivityLog = $log.ActivityLog
                $this.ExceptionLog = $log.ExceptionLog
                $this.InformationLog = $log.InformationLog
                $this.VariableLog = $log.VariableLog
            }
            if ([System.IO.File]::Exists($this.ConfigurationPath)) {
                $config = Get-Content -Path $this.ConfigurationPath | ConvertFrom-Json
                $this.State = $config.State
                $this.Connection = $config.Connection
                $this.Registry = $config.Registry
            }
        }
        catch {
        }
    }


    [void] SaveRepository() {
        # Since you can't really update just part of a JSON file, we rewrite the entire thing.
        @{
            ActivityLog = $this.ActivityLog
            ExceptionLog = $this.ExceptionLog
            InformationLog = $this.InformationLog
            VariableLog = $this.VariableLog
        } | ConvertTo-Json | Set-Content -Path $this.LogPath

        @{
            State = $this.State
            Connection = $this.Connection
            Registry = $this.Registry
        } | ConvertTo-Json | Set-Content -Path $this.ConfigurationPath
    }  
}